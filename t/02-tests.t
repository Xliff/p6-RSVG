use v6.c;

use Test;
use File::Find;

use Cairo;
use RSVG;

constant FRAME_SIZE = 47;

sub rsvg-cairo-check($file) {
  my $test-file-base = $file;

  $test-file-base.extension('') if $file.extension eq 'svg';
  my $test-file = GTK::Compat::Roles::GFile.new-for-path($file);
  my $rsvg      = RSVG.new-from-gfile-sync($file);
  nok $ERROR, "No error detected when loading {$file}";
  ok  $rsvg,  'Resulting SVG object is defined';

  $rsvg.internal-set-testing(True);
  $rsvg.set-dpi-xy( $file.contains('-48dpi') ?? 48 !! 72 );

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
  save-image( $s-a, my $out = ($base ~ '-out.png').IO );

  my $s-b = read-png($out);
}

sub MAIN (*@files) {
  my @svg = @files ??
    # For all files on command line
    @files
    !!
    # For all SVG files in t/reftests
    find( dir => "{$*CWD}/t/reftests", name => *.ends-with('svg') );

  rsvg-cairo-check($_) for @svg;
}
