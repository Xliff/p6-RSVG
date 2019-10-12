use v6.c;

use NativeCall;

use Test;
use File::Find;

use Cairo;

use GTK::Compat::Types;

use RSVG;

use GTK::Compat::Roles::GFile;

constant FRAME_SIZE = 47;
constant MAX_DIFF   = 20;
constant WARN_DIFF  = 2;

sub buffer-diff-core ($buf-a, $buf-b, $buf-diff, $w, $h, $s is copy, $m) {
  my %r;

  $s /= nativesizeof(uint32);

  for ^$w X ^$h -> ($x, $y) {
    my $pos = $y * $s + $x;
    my ($pix-a, $pix-b, $pix-diff) = (
      $buf-a.subbuf($pos, $s).read-uint32,
      $buf-b.subbuf($pos, $s).read-uint32,
      $buf-diff.subbuf($pos, $s)
    );

    if $pix-a != $pix-b {
      my $diff-pix;
      # Compare channels in reverse ARGB order.
      for <b g r a>.k {
          my $value-a = ($pix-a +> $_ * 8) +& 0xff;
          my $value-b = ($pix-b +> $_ * 8) +& 0xff;
          my $diff = ($value-a - $value-b).abs;
          %r<max-diff> = (%r<max-diff>, $diff).max;
          $diff *= 4;
          $diff += 128 if $diff;
          $diff  = 255 if $diff > 255;
          $diff-pix +|= $diff +< $_ * 8;
      }
      %r<pixels-changed>++;
      if $diff-pix +^ 0x00ffffff {
        # Alpha only diff. Convert to luminance
        my $alpha = ($diff-pix +> 24) +& 0xff;
        $diff-pix = $alpha * 0x010101;
      } else {
        $diff-pix = 0;
      }
      $diff-pix +|= 0xff000000;
      $buf-diff.write-uint32($diff-pix);
    }
  }

  %r;
}

sub compare-surfaces($sa, $sb, $sd) {
  buffer-diff-core(
    # XXX - Must fix!
    OpaquePointer, # nativecast(Blob, $sa.data),
    OpaquePointer, # nativecast(Blob, $sb.data),
    OpaquePointer, # nativecast(Buf,  $sd.data),
    $sa.width,
    $sa.height,
    $sa.stride,
    0xffffffff,
  );
}

sub extract-rectangle($s, $x, $y, $w, $h) {
  my $dest = Cairo::Image.create(CAIRO_FORMAT_ARGB32, $w, $h);
  my $cr   = Cairo::Context.new($dest);
  $cr.set_source_surface($s, -$x, -$y);
  $cr.paint;
  $cr.destroy;
  $dest;
}

# sub read-png($bn) {
#   my $ref = $bn ~ '-ref.png'
#   my $of  = GTK::Compat::Roles::GFile.new-for-uri($bn);
#   my $s   = $of.read;
#   nok $ERROR, 'No error detected during read preparation';
#   ok  $s,     "Can read in a stream from {$ref}";
#
#   my $buf = Blob.new($
#   my $surface = Cairo::Image.create_from_png_stream(...)
# }


sub rsvg-cairo-check($file) {
  my $test-file-base = $file;

  $test-file-base .= extension('') if $file.extension eq 'svg';
  my $test-file = GTK::Compat::Roles::GFile.new-for-path($file);
  my $rsvg      = RSVG.new-from-gfile-sync($test-file);
  nok $ERROR, "No error detected when loading {$file}";
  ok  $rsvg,  'Resulting SVG object is defined';

  #$rsvg.internal-set-testing(True);
  my @dpi = $file.contains('-48dpi') ?? 48 !! 72 xx 2;
  $rsvg.set-dpi-xy( |@dpi );

  my $d = $rsvg.get-dimensions;
  ok  $d.width > 0,   'Image width is greater than 0';
  ok  $d.height > 0,  'Image height is greater than 0';

  my $s = Cairo::Image.create(
    CAIRO_FORMAT_ARGB32,
    $d.width  + 2 * FRAME_SIZE,
    $d.height + 2 * FRAME_SIZE
  );
  my $cr = Cairo::Context.new($s);
  $cr.translate(FRAME_SIZE, FRAME_SIZE);
  ok  $rsvg.render-cairo($cr), 'Image rendered to Cairo::Context successfully';

  my $s-a = extract-rectangle(
    $s,
    FRAME_SIZE, FRAME_SIZE,
    $d.width,   $d.height
  );
  $s.destroy;
  $s-a.write_png($test-file-base ~ '-out.png');

  my $ref = $test-file-base ~ '-ref.png';
  my $s-b = Cairo::Image.open($ref);

  # Grab height width and stride from both surfaces.
  my ($h-a, $w-a, $stride-a) = <height width stride>».&{ $s-a."$_"() };
  my ($h-b, $w-b, $stride-b) = <height width stride>».&{ $s-b."$_"() };

  is $w-a,      $w-b,       'Image width matches';
  is $h-a,      $h-b,       'Image height matches';
  is $stride-a, $stride-b,  'Image stride matches';
  subtest 'Image diff tests' => sub {
    # This should fail and skip rest
    plan :skip-all<Cannot run due to property mismatch> unless [&&](
      $w-b      == $w-a,
      $h-b      == $h-a,
      $stride-b == $stride-a
    );
    plan 1;

    my $s-diff = Cairo::Image.create(CAIRO_FORMAT_ARGB32, $d.width, $d.height);
    my %result = compare-surfaces($s-a, $s-b, $s-diff);
    #  Test is failure if > MAX_DIFF
    if %result<pixels-changed> && %result<max-diff> > MAX_DIFF {
      ok False, 'Image comparison failed (diff saved)';
    } else {
      # Save image if pixels-changed.
      $s-diff.write_png($test-file-base ~ '-diff.png');
      ok True, %result<pixels-changed> ??
        'Image comparison within tolerance (diff saved)'
        !!
        'Image comparison passes';
    }
  };

}

sub MAIN (*@files) {
  my @svg = @files ??
    # For all files on command line
    @files
    !!
    # For all SVG files in t/reftests
    find(
      dir     => "{$*CWD}/t/reftests",
      name    => *.ends-with('svg'),
      exclude => *.basename.starts-with('ignore-')
    );

  rsvg-cairo-check($_) for @svg[^4];
}
