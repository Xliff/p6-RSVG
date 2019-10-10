use v6.c;

use NativeCall;

use GTK::Compat::Types;
use RSVG::Raw::Types;

unit package RSVG::Raw::RSVG;

our constant rsvg is export = 'rsvg-2',v2;

sub rsvg_error_get_type ()
  GType
  is native(rsvg)
  is export
{ * }

sub rsvg_handle_flags_get_type ()
  GType
  is native(rsvg)
  is export
{ * }


sub rsvg_handle_close (
  RsvgHandle $handle,
  CArray[Pointer[GError]] $error
)
  returns uint32
  is native(rsvg)
  is export
{ * }

# sub rsvg_handle_free (RsvgHandle $handle)
#   is native(rsvg)
#   is export
# { * }

sub rsvg_handle_get_base_uri (RsvgHandle $handle)
  returns char
  is native(rsvg)
  is export
{ * }

# sub rsvg_handle_get_desc (RsvgHandle $handle)
#   returns char
#   is native(rsvg)
#   is export
# { * }

sub rsvg_handle_get_dimensions (
  RsvgHandle $handle,
  RsvgDimensionData $dimension_data
)
  is native(rsvg)
  is export
{ * }

sub rsvg_handle_get_dimensions_sub (
  RsvgHandle $handle,
  RsvgDimensionData $dimension_data,
  Str $id
)
  returns uint32
  is native(rsvg)
  is export
{ * }

# sub rsvg_handle_get_metadata (RsvgHandle $handle)
#   returns char
#   is native(rsvg)
#   is export
# { * }

sub rsvg_handle_get_pixbuf (RsvgHandle $handle)
  returns GdkPixbuf
  is native(rsvg)
  is export
{ * }

sub rsvg_handle_get_pixbuf_sub (RsvgHandle $handle, Str $id)
  returns GdkPixbuf
  is native(rsvg)
  is export
{ * }

sub rsvg_handle_get_position_sub (
  RsvgHandle $handle,
  RsvgPositionData $position_data,
  Str $id
)
  returns uint32
  is native(rsvg)
  is export
{ * }

# sub rsvg_handle_get_title (RsvgHandle $handle)
#   returns char
#   is native(rsvg)
#   is export
# { * }

sub rsvg_handle_get_type ()
  returns GType
  is native(rsvg)
  is export
{ * }

sub rsvg_handle_has_sub (RsvgHandle $handle, Str $id)
  returns uint32
  is native(rsvg)
  is export
{ * }

sub rsvg_handle_internal_set_testing (RsvgHandle $handle, gboolean $testing)
  is native(rsvg)
  is export
{ * }

sub rsvg_handle_new ()
  returns RsvgHandle
  is native(rsvg)
  is export
{ * }

sub rsvg_handle_new_from_data (
  Blob $data,
  gsize $data_len,
  CArray[Pointer[GError]] $error
)
  returns RsvgHandle
  is native(rsvg)
  is export
{ * }

sub rsvg_handle_new_from_file (
  Str $file_name,
  CArray[Pointer[GError]] $error
)
  returns RsvgHandle
  is native(rsvg)
  is export
{ * }

sub rsvg_handle_new_from_gfile_sync (
  GFile $file,
  RsvgHandleFlags $flags,
  GCancellable $cancellable,
  CArray[Pointer[GError]] $error
)
  returns RsvgHandle
  is native(rsvg)
  is export
{ * }

sub rsvg_handle_new_from_stream_sync (
  GInputStream $input_stream,
  GFile $base_file,
  RsvgHandleFlags $flags,
  GCancellable $cancellable,
  CArray[Pointer[GError]] $error
)
  returns RsvgHandle
  is native(rsvg)
  is export
{ * }

sub rsvg_handle_new_with_flags (RsvgHandleFlags $flags)
  returns RsvgHandle
  is native(rsvg)
  is export
{ * }

sub rsvg_handle_read_stream_sync (
  RsvgHandle $handle,
  GInputStream $stream,
  GCancellable $cancellable,
  CArray[Pointer[GError]] $error
)
  returns uint32
  is native(rsvg)
  is export
{ * }

sub rsvg_cleanup ()
  is native(rsvg)
  is export
{ * }

sub rsvg_error_quark ()
  returns GQuark
  is native(rsvg)
  is export
{ * }

# sub rsvg_init ()
#   is native(rsvg)
#   is export
# { * }

# sub rsvg_pixbuf_from_file (Str $file_name, CArray[Pointer[GError]] $error)
#   returns GdkPixbuf
#   is native(rsvg)
#   is export
# { * }
#
# sub rsvg_pixbuf_from_file_at_max_size (
#   Str $file_name,
#   gint $max_width,
#   gint $max_height,
#   CArray[Pointer[GError]] $error
# )
#   returns GdkPixbuf
#   is native(rsvg)
#   is export
# { * }
#
# sub rsvg_pixbuf_from_file_at_size (
#   Str $file_name,
#   gint $width,
#   gint $height,
#   CArray[Pointer[GError]] $error
# )
#   returns GdkPixbuf
#   is native(rsvg)
#   is export
# { * }
#
# sub rsvg_pixbuf_from_file_at_zoom (
#   Str $file_name,
#   gdouble $x_zoom,
#   gdouble $y_zoom,
#   CArray[Pointer[GError]] $error
# )
#   returns GdkPixbuf
#   is native(rsvg)
#   is export
# { * }
#
# sub rsvg_pixbuf_from_file_at_zoom_with_max (
#   Str $file_name,
#   gdouble $x_zoom,
#   gdouble $y_zoom,
#   gint $max_width,
#   gint $max_height,
#   CArray[Pointer[GError]] $error
# )
#   returns GdkPixbuf
#   is native(rsvg)
#   is export
# { * }

# sub rsvg_set_default_dpi (gdouble $dpi)
#   is native(rsvg)
#   is export
# { * }
#
# sub rsvg_set_default_dpi_x_y (gdouble $dpi_x, gdouble $dpi_y)
#   is native(rsvg)
#   is export
# { * }

# sub rsvg_term ()
#   is native(rsvg)
#   is export
# { * }

sub rsvg_handle_set_base_gfile (RsvgHandle $handle, GFile $base_file)
  is native(rsvg)
  is export
{ * }

sub rsvg_handle_set_dpi (RsvgHandle $handle, gdouble $dpi)
  is native(rsvg)
  is export
{ * }

sub rsvg_handle_set_dpi_x_y (
  RsvgHandle $handle,
  gdouble $dpi_x,
  gdouble $dpi_y
)
  is native(rsvg)
  is export
{ * }

# sub rsvg_handle_set_size_callback (
#   RsvgHandle $handle,
#   RsvgSizeFunc $size_func,
#   gpointer $user_data,
#   GDestroyNotify $user_data_destroy
# )
#   is native(rsvg)
#   is export
# { * }

sub rsvg_handle_render_cairo (RsvgHandle $handle, cairo_t $cr)
  returns uint32
  is native(rsvg)
  is export
{ * }

sub rsvg_handle_render_cairo_sub (RsvgHandle $handle, cairo_t $cr, Str $id)
  returns uint32
  is native(rsvg)
  is export
{ * }
