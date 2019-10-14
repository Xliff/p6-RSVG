use v6.c;

use NativeCall;

use Test;
use File::Find;

use Cairo;

use GTK::Compat::Types;

use RSVG;

use GTK::Compat::Roles::GFile;

constant FRAME_SIZE    = 47;
constant MAX_DIFF      = 20;
constant WARN_DIFF     = 2;
constant TESTS_PER_SVG = 9;

sub buffer-diff-core ($buf-a, $buf-b, $w, $h, $s is copy, $m) {
  my %r;

  $s /= nativesizeof(uint32);

  # Bit of a pause here if either dimension is > 250. I thought these
  # lazy lists wouldn't do that!
  %r<buf-diff> = Buf.allocate($buf-a.elems);

  my uint32 ($x, $y) = 0 xx 4;
  loop ($x = 0; $x < $w; $x++) {
    loop ($y = 0; $y < $h; $y++) {
      my uint64 $pos = ($y * $s * 4 + $x).Int;
      my uint32 ($pix_a, $pix_b, $pix_diff) = (
        $buf-a.read-uint32($pos),
        $buf-b.read-uint32($pos),
        0
      );

      if $pix_a != $pix_b {
        my uint32 $diff-pix = 0;
        # Compare channels in reverse ARGB order.\
        my %pd;
        for <b g r a>.keys {
            my $value_a = ( $pix_a +> ($_ * 8) ) +& 0xff;
            my $value_b = ( $pix_b +> ($_ * 8) ) +& 0xff;
            my $diff = ($value_a - $value_b).abs;
            %r<max-diff> = (%r<max-diff>, $diff).max;
            $diff *= 4;
            $diff += 128 if $diff;
            $diff  = 255 if $diff > 255;
            $diff-pix +|= ( $diff +< ($_ * 8) );
            %pd{"diff-$_"}++ unless $_ eq 'a';
            %pd<diff-r diff-g diff-b> = 0 xx 3
              if $_ eq 'a' && $value_b == 0;
        }

        %r<pixels-changed>++;
        %r<diff-a>++ if %pd<diff-r> || %pd<diff-g> || %pd<diff-b>;
        unless $diff-pix +^ 0x00ffffff {
          # Alpha only diff. Convert to luminance
          my uint32 $alpha = ($diff-pix +> 24) +& 0xff;
          $diff-pix = $alpha * 0x010101;
        }
        $diff-pix +|= 0xff000000;
        %r<buf-diff>.write-uint32($pos, $diff-pix);
      }
    }
  }
  diag %r.gist;

  %r;
}

sub compare-surfaces($sa, $sb) {
  buffer-diff-core(
    $sa.Blob,
    $sb.Blob,
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

  # $rsvg.internal-set-testing(True);
  my $dpi = $file.contains('-48dpi') ?? 48 !! 72;
  $rsvg.set-dpi($dpi);

  # diag "DPI: $dpi";
  # diag "DPI-X: {$rsvg.dpi-x}";
  # diag "DPI-Y: {$rsvg.dpi-y}";

  my $d = $rsvg.get-dimensions;
  ok  $d.width  > 0,  'Image width is greater than 0';
  ok  $d.height > 0,  'Image height is greater than 0';

  # diag "W: {$d.width}";
  # diag "H: {$d.height}";

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
  $s-a.write_png($test-file-base ~ '-out.png');
  $s.destroy;

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

    # $s-diff comes from Cairo as a Blob, check to see if it remains attached
    # to the actual Cairo buffer.
    my %result = compare-surfaces($s-a, $s-b);
    #  Test is failure if pixels have changed and %result<max-diff> > MAX_DIFF
    if %result<pixels-changed> && %result«max-diff» > MAX_DIFF {
      ok False, "Image comparison failed [{
                 %result<pixels-changed>} pix / {%result<diff-a>}α {
                 %result<max-diff>} max] (diff saved)";
    } else {
      # Save image if pixels-changed.
      ok True, %result<pixels-changed> ??
        "Image comparison within tolerance [{
          %result<pixels-changed>} pix {
          %result<max-diff>} max] (diff saved)"
        !!
        'Image comparison passes';
    }
    if %result<pixels-changed> {
      my $bd = Cairo::Image.create(
        CAIRO_FORMAT_ARGB32,
        $d.width, $d.height,
        %result<buf-diff>
      );
      $bd.write_png($test-file-base ~ '-diff.png');
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
      exclude => { .basename.starts-with('ignore-') || .self eq 'resources' }
    );

  plan TESTS_PER_SVG * 10;

  rsvg-cairo-check($_) for @svg[^100];
}
