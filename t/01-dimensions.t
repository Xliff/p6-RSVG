use v6.c;

use Test;

use RSVG::Raw::Types;

use RSVG;

my @dimensions = (
  # Consider converting these to hashes.
  #[
    # Test name
    # File Name
    # Fixture ID
    # Fixture X, Fixture Y, Width, Height
    # Has Fixture, Has Position
  #]
  [
      '/dimensions/no viewbox, width and height',
      'dimensions/bug608102.svg',
      Str,
      0, 0, 16, 16,
      False, True
  ],
  [
      '/dimensions/100% width and height',
      'dimensions/bug612951.svg',
      Str,
      0, 0, 47, 47.14,
      False, True
  ],
  [
      '/dimensions/viewbox only',
      'dimensions/bug614018.svg',
      Str,
      0, 0, 972, 546,
      False, True
  ],
  [
      '/dimensions/sub/rect no unit',
      'dimensions/sub-rect-no-unit.svg',
      '#rect-no-unit',
      0, 0, 44, 45,
      False, True
  ],
  [
      '/dimensions/sub/text_position',
      'dimensions/347-wrapper.svg',
      '#LabelA',
      80, 48.90, 0, 0,
      True, False
  ]
);

sub test-dimensions {
  for @dimensions -> $dt {
    subtest $dt[0] => sub {
      my $h = RSVG.new-from-file("$*CWD/t/$dt[1]");
      nok $ERROR, "No error detected from loading '{ $dt[1] }'";

      my ($p, $d);
      if $dt[2] {
        ok $h.has-sub($dt[2]), "File has subid '{ $dt[2] }'";

        ($p, $d) = ( $h.get-position-sub( $dt[2] ), $h.get-dimensions-sub( $dt[2] ) );
        ok $p, "Can obtain position for { $dt[2] }";
        ok $d, "Can obtain dimesions for { $dt[2] }";

        diag "w={$d.width} h={$d.height}";
      } else {
        $d = $h.get-dimensions;
      }

      if $dt[7] {
        is $dt[3].floor, $p.x, 'Fixture has the correct X value';
        is $dt[4].floor, $p.y, 'Fixture has the correct Y value';
      }
      if $dt[8] {
        is $dt[5].floor, $d.width,  'Image has the correct width';
        is $dt[6].floor, $d.height, 'Image has the correct height';
      }
    }
  }
}

plan @dimensions.elems;

test-dimensions;
