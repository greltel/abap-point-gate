"! <p class="shorttext synchronized" lang="EN">ABAP Point Gate context</p>
"! Hashed-table based implementation of {@link zif_apg_context}.
CLASS zcl_apg_context DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_apg_context.

    ALIASES set_data    FOR zif_apg_context~set_data.
    ALIASES get_data    FOR zif_apg_context~get_data.
    ALIASES has_data    FOR zif_apg_context~has_data.
    ALIASES get_string  FOR zif_apg_context~get_string.
    ALIASES get_integer FOR zif_apg_context~get_integer.
    ALIASES get_date    FOR zif_apg_context~get_date.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_entry,
             name  TYPE string,
             value TYPE REF TO data,
           END OF ty_entry,
           ty_entries TYPE HASHED TABLE OF ty_entry WITH UNIQUE KEY name.

    DATA entries TYPE ty_entries.

    "! Dereferences the stored value and assigns it to the field symbol.
    METHODS assign_value
      IMPORTING name          TYPE string
      RETURNING VALUE(result) TYPE REF TO data
      RAISING   zcx_apg_error.
ENDCLASS.


CLASS zcl_apg_context IMPLEMENTATION.

  METHOD zif_apg_context~set_data.
    DELETE entries WHERE name = name.
    INSERT VALUE #( name  = name
                    value = value ) INTO TABLE entries.
  ENDMETHOD.

  METHOD zif_apg_context~get_data.
    TRY.
        result = entries[ name = name ]-value.
      CATCH cx_sy_itab_line_not_found INTO DATA(not_found).
        RAISE EXCEPTION NEW zcx_apg_error( textid       = zcx_apg_error=>context_value_missing
                                           context_name = name
                                           previous     = not_found ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_apg_context~has_data.
    result = xsdbool( line_exists( entries[ name = name ] ) ).
  ENDMETHOD.

  METHOD zif_apg_context~get_string.
    DATA(value_ref) = assign_value( name ).
    ASSIGN value_ref->* TO FIELD-SYMBOL(<value>).
    TRY.
        result = |{ <value> }|.
      CATCH cx_root INTO DATA(conversion_error). " boundary wrap: any conversion failure becomes a framework error
        RAISE EXCEPTION NEW zcx_apg_error( textid       = zcx_apg_error=>context_conversion_failed
                                           context_name = name
                                           previous     = conversion_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_apg_context~get_integer.
    DATA(value_ref) = assign_value( name ).
    ASSIGN value_ref->* TO FIELD-SYMBOL(<value>).
    TRY.
        result = <value>.
      CATCH cx_root INTO DATA(conversion_error). " boundary wrap: any conversion failure becomes a framework error
        RAISE EXCEPTION NEW zcx_apg_error( textid       = zcx_apg_error=>context_conversion_failed
                                           context_name = name
                                           previous     = conversion_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_apg_context~get_date.
    DATA(value_ref) = assign_value( name ).
    ASSIGN value_ref->* TO FIELD-SYMBOL(<value>).
    TRY.
        result = <value>.
      CATCH cx_root INTO DATA(conversion_error). " boundary wrap: any conversion failure becomes a framework error
        RAISE EXCEPTION NEW zcx_apg_error( textid       = zcx_apg_error=>context_conversion_failed
                                           context_name = name
                                           previous     = conversion_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD assign_value.
    result = get_data( name ).
    IF result IS NOT BOUND.
      RAISE EXCEPTION NEW zcx_apg_error( textid       = zcx_apg_error=>context_value_missing
                                         context_name = name ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
