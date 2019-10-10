use v6.c;

use GTK::Compat::Types;

use RSVG;

use GTK::Application;
use GTK::Image;

my $a = GTK::Application.new(
  title  => 'org.genex.billiards',
  width  => 820,
  height => 600,
);

my $svg = RSVG.new-from-file("{$*CWD}/t/billiards.svg");
$svg.set-dpi(80);

$a.activate.tap({
  $a.wait-for-init;

  my $image = GTK::Image.new-from-pixbuf($svg.pixbuf);
  $a.window.destroy-signal.tap({ $a.exit });
  $a.window.add($image);
  $a.window.show-all;
});

$a.run;
