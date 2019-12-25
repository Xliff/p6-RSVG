use v6.c;

use Method::Also;
use NativeCall;

use Cairo;

use GTK::Compat::Types;
use GLib::Value;
use RSVG::Raw::Types;

use RSVG::Raw::RSVG;

use GTK::Compat::Pixbuf;

use GTK::Roles::Properties;

class RSVG {
  also does GTK::Roles::Properties;

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
    my $svg = rsvg_handle_new_from_file($filename, $error);
    set_error($error);

    $svg ?? self.bless( :$svg ) !! Nil;
  }

  method new_from_gfile_sync (
    GFile() $file,
    Int() $flags                   = 0,
    GCancellable() $cancellable    = GCancellable,
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
      $input_stream,
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

  # Type: gchar
  method base-uri is rw is also<base_uri> {
    #my GLib::Value $gv .= new( G_TYPE_STRING );
    Proxy.new(
      FETCH => -> $ {
        # $gv = GLib::Value.new(
        #   self.prop_get('base-uri', $gv)
        # );
        # $gv.string;

        # Eschew property based FETCH for purpose built method.
        self.get_base_uri;
      },
      STORE => -> $, Str() $val is copy {
        $gv.string = $val;
        self.prop_set('base-uri', $gv);
      }
    );
  }


  # Type: gdouble
  method dpi-x is rw  {
    my GLib::Value $gv .= new( G_TYPE_DOUBLE );
    Proxy.new(
      FETCH => -> $ {
        $gv = GLib::Value.new(
          self.prop_get('dpi-x', $gv)
        );
        $gv.double;
      },
      STORE => -> $, Num() $val is copy {
        $gv.double = $val;

        self.prop_set('dpi-x', $gv);
      }
    );
  }

  # Type: gdouble
  method dpi-y is rw  {
    my GLib::Value $gv .= new( G_TYPE_DOUBLE );
    Proxy.new(
      FETCH => -> $ {
        $gv = GLib::Value.new(
          self.prop_get('dpi-y', $gv)
        );
        $gv.double;
      },
      STORE => -> $, Num() $val is copy {
        $gv.double = $val;

        self.prop_set('dpi-y', $gv);
      }
    );
  }

  # Type: RsvgHandleFlags
  method flags is rw  {

    # Unless there is a reason for this to be user facing, it won't be.
    sub flags_get_type {
      state ($n, $t);

      unstable_get_type( self.^name, &rsvg_handle_flags_get_type, $n, $t);
    }

    my GLib::Value $gv .= new(flags_get_type);
    Proxy.new(
      FETCH => -> $ {
        $gv = GLib::Value.new(
          self.prop_get('flags', $gv.flags)
        );
        $gv.flags;
      },
      STORE => -> $, $val is copy {
        warn 'Can only set RsvgHandleFlags at construction time!';
      }
    );
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

  proto method get_dimensions (|)
    is also<get-dimensions>
  { * }

  # cw: Note for all routines that take an :$all parameter - 10/12/2019!!
  #
  # For most multi's that accept no arguments, but take a rw parameter, we
  # may need to do something similar to the following.
  multi method get_dimensions {
    my $rv = samewith(RsvgDimensionData.new, :all);
    $rv[0] ?? $rv[1] !! Nil;
  }
  multi method get_dimensions (RsvgDimensionData $dimension_data, :$all = False) {
    my $rv = so rsvg_handle_get_dimensions($!rsvg, $dimension_data);
    $rv = True; # For this call, rsvg_handle_get_dimensions always returns
                # False. Note that this function is deprecated and only
                # remains for testing purposes.
    $all.not ?? $rv !! ($rv, $dimension_data);
  }

  proto method get_dimensions_sub (|)
    is also<get-dimensions-sub>
  { * }

  multi method get_dimensions_sub (Str() $id) {
    my $rv = samewith(RsvgDimensionData.new, $id, :all);

    $rv[0] ?? $rv[1] !! Nil;
  }
  multi method get_dimensions_sub (
    RsvgDimensionData $dimension_data,
    Str() $id,
    :$all = False;
  ) {
    my $rv = so rsvg_handle_get_dimensions_sub($!rsvg, $dimension_data, $id);
    $rv = True; # For this call, rsvg_handle_get_dimensions always returns
                # False. Note that this function is deprecated and only
                # remains for testing purposes.
    $all.not ?? $rv !! ($rv, $dimension_data);
  }

  method get_pixbuf (:$raw = False)
    is also<
      get-pixbuf
      pixbuf
    >
  {
    my $pixbuf = rsvg_handle_get_pixbuf($!rsvg);

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

  proto method get_position_sub(|)
        is also<get-position-sub>
  { * }

  multi method get_position_sub (Str() $id) {
    my $rv = samewith(RsvgPositionData.new, $id, :all);

    $rv[0] ?? $rv[1] !! Nil;
  }
  multi method get_position_sub (
    RsvgPositionData $position_data,
    Str() $id,
    :$all = False
  ) {
    my $rv = so rsvg_handle_get_position_sub($!rsvg, $position_data, $id);
    $rv = True; # For this call, rsvg_handle_get_dimensions always returns
                # False. Note that this function is deprecated and only
                # remains for testing purposes.
    $all.not ?? $rv !! ($rv, $position_data);
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
    GInputStream() $stream,
    GCancellable() $cancellable    = GCancellable,
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

  method set_dpi (Num() $dpi) is also<set-dpi> {
    my gdouble $d = $dpi;

    rsvg_handle_set_dpi($!rsvg, $d);
  }

  method set_dpi_x_y (Num() $dpi_x, Num() $dpi_y)
    is also<
      set-dpi-x-y
      set_dpi_xy
      set-dpi-xy
    >
  {
    my gdouble ($dx, $dy);

    rsvg_handle_set_dpi_x_y($!rsvg, $dx, $dy);
  }

  method render_cairo ($cr is copy) is also<render-cairo> {
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
