use v6.c;

unit package RSVG::Raw::Exports;

our @rsvg-exports is export;

BEGIN {
  @rsvg-exports = <
    RSVG::Raw::Definitions
  >;
}
