use v6.c;

use NativeCall;

use Test;
use File::Find;

use Cairo;

use GTK::Compat::Types;

use RSVG;

use GIO::Roles::GFile;

constant FRAME_SIZE    = 47;
constant MAX_DIFF      = 20;
constant WARN_DIFF     = 2;
constant TESTS_PER_SVG = 9;

my $TEST-DEBUG = False;

sub buffer-diff-core ($buf-a, $buf-b, $buf-d, $w, $h, $s is copy, $m) {
  my %r;

  #$s /= nativesizeof(uint32);

  diag "W: {$w}, H: {$h}, S: {$s}" if $TEST-DEBUG;

  my @order = <a r g b>;
  my uint32 ($x, $y) = 0 xx 4;
  loop ($x = 0; $x < $w; $x++) {
    loop ($y = 0; $y < $h; $y++) {
      my uint64 $pos = ($y * $s + $x).Int;
      my uint32 ($pix_a, $pix_b, $pix_diff) = (
        $buf-a.read-uint32($pos),
        $buf-b.read-uint32($pos),
        0
      );

      if $pix_a != $pix_b {
        diag "Pixel mismatch at ({$x}, {$y})" if $TEST-DEBUG;
        my uint32 $diff-pix = 0;
        # Compare channels in reverse ARGB order.
        for @order.reverse.kv -> $k, $v {
            my $value_a = ( $pix_a +> ($k * 8) ) +& 0xff;
            my $value_b = ( $pix_b +> ($k * 8) ) +& 0xff;
            my $diff = ($value_a - $value_b).abs;
            %r<max-diff> = (%r<max-diff>, $diff).max;
            $diff *= 4;
            $diff += 128 if $diff;
            $diff  = 255 if $diff > 255;
            $diff-pix +|= ( $diff +< ($k * 8) );

            diag "\tMismatched {$v} channel: {$value_b} vs {$value_a}"
              if $diff && $TEST-DEBUG;
        }

        %r<pixels-changed>++;
        unless $diff-pix +^ 0x00ffffff {
          # Alpha only diff. Convert to luminance
          my uint32 $alpha = ($diff-pix +> 24) +& 0xff;
          $diff-pix = $alpha * 0x010101;
        }

        # Write difference pixel back to image buffer.
        $diff-pix +|= 0xff000000;
        for @order.kv -> $k, $v {
          my $val = ( $diff-pix +> ( (@order.elems - $k - 1) * 8 ) ) +& 0xff;
          $buf-d[$pos + $k] = $val;
        }
      }
    }
  }
  diag %r.gist if $TEST-DEBUG;

  %r;
}

sub compare-surfaces($sa, $sb, $sd) {
  buffer-diff-core(
    $sa.data,
    $sb.data,
    $sd.data-rw,
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
#   my $of  = GIO::Roles::GFile.new-for-uri($bn);
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
  my $test-file = GIO::Roles::GFile.new-for-path($file);
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

    my $s-d = Cairo::Image.create(CAIRO_FORMAT_ARGB32, $d.width, $d.height);
    my %result = compare-surfaces($s-a, $s-b, $s-d);
    #  Test is failure if pixels have changed and %result<max-diff> > MAX_DIFF
    if %result<pixels-changed> && %result«max-diff» > MAX_DIFF {
      ok False, "Image comparison failed [{
                 %result<pixels-changed>} pix / {
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
    $s-d.write_png($test-file-base ~ '-diff.png') if %result<pixels-changed>;
  };

}

sub MAIN (:$debug = False, *@files) {
  $TEST-DEBUG = $debug;

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
