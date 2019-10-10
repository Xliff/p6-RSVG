use v6.c;

use Method::Also;

use Cairo;

use GTK::Compat::Types;
use RSVG::Raw::Types;

use RSVG::Raw::RSVG;

use GTK::Compat::Roles::Object;

class RSVG does {
  also does GTK::Compat::Roles::Object;

  has RsvgHandle $!rsvg;

  submethod BUILD (:$svg) {
    $!rsvg = $svg;

    self.roleInit-Object;
  }

  method RSVG::Types::Raw::RsvgHandle
    is also<RsvgHandle>
  { $!rsvg }

  method new {
    my $svg = rsvg_handle_new();

    $svg ?? self.bless( :$svg ) !! Nil;
  }

  method new_from_data (
    Blob $data,
    Int() $data_len                = $data.elems,
    CArray[Pointer[GError]] $error = gerror
  )
    is also<new-from-data>
  {
    my $svg = rsvg_handle_new_from_data($data, $data_len, $error);

    $svg ?? self.bless( :$svg ) !! Nil;
  }

  method new_from_file (
    Str() $filename,
    CArray[Pointer[GError]] $error = gerror
  )
    is also<new-from-file>
  {
    clear_error;
    my $svg = rsvg_handle_new_from_file($file, $error);
    set_error($error);

    $svg ?? self.bless( :$svg ) !! Nil;
  }

  method new_from_gfile_sync (
    GFile() $file,
    Int() $flags,
    GCancellable $cancellable      = GCancellable,
    CArray[Pointer[GError]] $error = gerror
  )
    is also<new-from-gfile-sync>
  {
    my RsvgHandleFlags $f = $flags;
    clear_error;
    my $svg = rsvg_handle_new_from_gfile_sync($file, $f, $cancellable, $error);

    $svg ?? self.bless( :$svg ) !! Nil;
  }

  method new_from_stream_sync (
    GInputStream() $input_stream;
    GFile() $base_file,
    Int() $flags,
    GCancellable() $cancellable    = GCancellable,
    CArray[Pointer[GError]] $error = gerror
  )
    is also<new-from-stream-sync>
  {
    my RsvgHandleFlags $f = $flags;

    clear_error;
    my $svg = rsvg_handle_new_from_stream_sync(
      $!rsvg,
      $base_file,
      $f,
      $cancellable,
      $error
    );
    set_error($error);

    $svg ?? self.bless( :$svg ) !! Nil;
  }

  method new_with_flags (Int() $flags) is also<new-with-flags> {
    my RsvgHandleFlags $f =$flags;
    my $svg = rsvg_handle_new_with_flags($f);

    $svg ?? self.bless( :$svg ) !! Nil;
  }

  method close (CArray[Pointer[GError]] $error = gerror) {
    clear_error;
    my $rv = so rsvg_handle_close($!rsvg, $error);
    set_error($error);
    $rv;
  }

  method get_base_uri is also<get-base-uri> {
    rsvg_handle_get_base_uri($!rsvg);
  }

  method get_dimensions (RsvgDimensionData $dimension_data)
    is also<get-dimensions>
  {
    rsvg_handle_get_dimensions($!rsvg, $dimension_data);
  }

  method get_dimensions_sub (RsvgDimensionData $dimension_data, Str() $id)
    is also<get-dimensions-sub>
  {
    rsvg_handle_get_dimensions_sub($!rsvg, $dimension_data, $id);
  }

  method get_pixbuf (:$raw = False) is also<get-pixbuf> {
    my $pixbuf = rsvg_handle_get_pixbuf_sub($!rsvg, $id);

    $pixbuf ??
      ( $raw ?? $pixbuf !! GTK::Compat::Pixbuf.new($pixbuf) )
      !!
      Nil;
  }

  method get_pixbuf_sub (Str() $id, :$raw = False) is also<get-pixbuf-sub> {
    my $pixbuf = rsvg_handle_get_pixbuf_sub($!rsvg, $id);

    $pixbuf ??
      ( $raw ?? $pixbuf !! GTK::Compat::Pixbuf.new($pixbuf) )
      !!
      Nil;
  }

  method get_position_sub (RsvgPositionData $position_data, Str() $id)
    is also<get-position-sub>
  {
    rsvg_handle_get_position_sub($!rsvg, $position_data, $id);
  }

  method get_type is also<get-type> {
    state ($n, $t);

    unstable_get_type( self.^name, &rsvg_handle_get_type, $n, $t );
  }

  method has_sub (Str() $id) is also<has-sub> {
    so rsvg_handle_has_sub($!rsvg, $id);
  }

  method internal_set_testing (Int() $testing) is also<internal-set-testing> {
    my gboolean $t = $testing;

    rsvg_handle_internal_set_testing($!rsvg, $t);
  }

  method read_stream_sync (
    GInputStream $stream,
    GCancellable $cancellable,
    CArray[Pointer[GError]] $error = gerror
  )
    is also<read-stream-sync>
  {
    clear_error;
    my $rv = so rsvg_handle_read_stream_sync(
      $!rsvg,
      $stream,
      $cancellable,
      $error
    );
    set_error($error);
    $rv;
  }

  method rsvg_cleanup ( RSVG:U: ) is also<rsvg-cleanup> {
    rsvg_cleanup();
  }

  method rsvg_error_quark ( RSVG:U: ) is also<rsvg-error-quark> {
    rsvg_error_quark();
  }

  method set_base_gfile (GFile() $base_file) is also<set-base-gfile> {
    rsvg_handle_set_base_gfile($!rsvg, $base_file);
  }

  method set_dpi (gdouble $dpi) is also<set-dpi> {
    rsvg_handle_set_dpi($!rsvg, $dpi);
  }

  method set_dpi_x_y (gdouble $dpi_x, gdouble $dpi_y) is also<set-dpi-x-y> {
    rsvg_handle_set_dpi_x_y($!rsvg, $dpi_x, $dpi_y);
  }

  method render_cairo ($cr) is also<render-cairo> {
    $cr .= context if $cr ~~ Cairo::Context;
    die '$cr parameter must be a cairo_t compatible type!'
      unless $cr ~~ cairo_t;

    rsvg_handle_render_cairo($!rsvg, $cr);
  }

  method render_cairo_sub ($cr, Str $id) is also<render-cairo-sub> {
    $cr .= context if $cr ~~ Cairo::Context;
    die '$cr parameter must be a cairo_t compatible type!'
      unless $cr ~~ cairo_t;

    rsvg_handle_render_cairo_sub($!rsvg, $cr, $id);
  }

}
