use v6.c;

use Cairo;

use GTK::Compat::Types;
use RSVG::Raw::Types;

use RSVG::Raw::RSVG;

class RSVG {
  has RsvgHandle $!rsvg;

  method new () {
    rsvg_handle_new();
  }

  method RSVG::Types::Raw::RsvgHandle
  { $!rsvg }

  method new_from_data (
    Blob $data,
    gsize $data_len,
    CArray[Pointer[GError]] $error = gerror
  ) {
    rsvg_handle_new_from_data($data, $data_len, $error);
  }

  method new_from_file (
    Str() $filename,
    CArray[Pointer[GError]] $error = gerror
  ) {
    rsvg_handle_new_from_file($file, $error);
  }

  method new_from_gfile_sync (
    GFile() $file,
    RsvgHandleFlags $flags,
    GCancellable $cancellable      = GCancellable,
    CArray[Pointer[GError]] $error = gerror
  ) {
    rsvg_handle_new_from_gfile_sync($file, $flags, $cancellable, $error);
  }

  method new_from_stream_sync (
    GInputStream() $input_stream;
    GFile() $base_file,
    RsvgHandleFlags $flags,
    GCancellable() $cancellable    = GCancellable,
    CArray[Pointer[GError]] $error = gerror
  ) {
    rsvg_handle_new_from_stream_sync(
      $!rsvg,
      $base_file,
      $flags,
      $cancellable,
      $error
    );
  }

  method new_with_flags (Int() $flags) {
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

  method get_base_uri {
    rsvg_handle_get_base_uri($!rsvg);
  }

  method get_dimensions (RsvgDimensionData $dimension_data) {
    rsvg_handle_get_dimensions($!rsvg, $dimension_data);
  }

  method get_dimensions_sub (RsvgDimensionData $dimension_data, Str() $id) {
    rsvg_handle_get_dimensions_sub($!rsvg, $dimension_data, $id);
  }

  method get_pixbuf_sub (Str $id) {
    rsvg_handle_get_pixbuf_sub($!rsvg, $id);
  }

  method get_position_sub (RsvgPositionData $position_data, Str() $id) {
    rsvg_handle_get_position_sub($!rsvg, $position_data, $id);
  }

  method get_type {
    state ($n, $t);

    unstable_get_type( self.^name, &rsvg_handle_get_type, $n, $t );
  }

  method has_sub (Str() $id) {
    so rsvg_handle_has_sub($!rsvg, $id);
  }

  method internal_set_testing (Int() $testing) {
    my gboolean $t = $testing;

    rsvg_handle_internal_set_testing($!rsvg, $t);
  }

  method read_stream_sync (
    GInputStream $stream,
    GCancellable $cancellable,
    CArray[Pointer[GError]] $error = gerror
  ) {
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

  method rsvg_cleanup () {
    rsvg_cleanup($!rsvg);
  }

  method rsvg_error_quark () {
    rsvg_error_quark($!rsvg);
  }

  method set_base_gfile (GFile() $base_file) {
    rsvg_handle_set_base_gfile($!rsvg, $base_file);
  }

  method set_dpi (gdouble $dpi) {
    rsvg_handle_set_dpi($!rsvg, $dpi);
  }

  method set_dpi_x_y (gdouble $dpi_x, gdouble $dpi_y) {
    rsvg_handle_set_dpi_x_y($!rsvg, $dpi_x, $dpi_y);
  }

  method render_cairo ($cr) {
    $cr .= context if $cr ~~ Cairo::Context;
    die '$cr parameter must be a cairo_t compatible type!'
      unless $cr ~~ cairo_t;

    rsvg_handle_render_cairo($!rsvg, $cr);
  }

  method render_cairo_sub ($cr, Str $id) {
    $cr .= context if $cr ~~ Cairo::Context;
    die '$cr parameter must be a cairo_t compatible type!'
      unless $cr ~~ cairo_t;

    rsvg_handle_render_cairo_sub($!rsvg, $cr, $id);
  }

}
