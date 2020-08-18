use v6.c;

use NativeCall;

use GLib::Raw::Definitions;

use GLib::Roles::Pointers;

unit package RSVG::Raw::Types;

# Project forced rebuild count.
constant forced = 1;

class RsvgHandle        is repr<CPointer> is export does GLib::Roles::Pointers { }

class RsvgDimensionData is repr<CStruct>  is export does GLib::Roles::Pointers {
    has gint    $.width  is rw;
    has gint    $.height is rw;
    has gdouble $.em     is rw;
    has gdouble $.ex     is rw;
}

class RsvgPositionData is repr<CStruct> is export does GLib::Roles::Pointers {
    has gint $.x is rw;
    has gint $.y is rw;
}

class RsvgRectangle is repr<CStruct> is export does GLib::Roles::Pointers {
    has gdouble $.x      is rw;
    has gdouble $.y      is rw;
    has gdouble $.width  is rw;
    has gdouble $.height is rw;
}

our constant RsvgHandleFlags is export := guint;
our enum RsvgHandleFlagsEnum is export (
   RSVG_HANDLE_FLAGS_NONE           => 0,
   RSVG_HANDLE_FLAG_UNLIMITED       => 1,
   RSVG_HANDLE_FLAG_KEEP_IMAGE_DATA => 2
);

our constant RsvgError is export := guint;
our enum RsvgErrorEnum is export <
    RSVG_ERROR_FAILED
>;