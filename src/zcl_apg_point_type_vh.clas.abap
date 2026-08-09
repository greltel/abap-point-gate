"! <p class="shorttext synchronized" lang="EN">Point type value help</p>
"! Query provider that serves the fixed values of domain ZAPG_POINT_TYPE.
CLASS zcl_apg_point_type_vh DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CONSTANTS fallback_language TYPE spras VALUE 'E'.

    TYPES tt_values TYPE STANDARD TABLE OF zi_apg_point_type_vh WITH EMPTY KEY.

    METHODS read_domain_values
      RETURNING VALUE(result) TYPE tt_values.

    METHODS determine_language RETURNING VALUE(result) TYPE spras.

ENDCLASS.


CLASS zcl_apg_point_type_vh IMPLEMENTATION.

  METHOD if_rap_query_provider~select.
    io_request->get_sort_elements( ).
    io_request->get_paging( ).
    DATA(values) = read_domain_values( ).

    TRY.
        LOOP AT io_request->get_filter( )->get_as_ranges( ) INTO DATA(filter).
          IF to_upper( filter-name ) = 'POINTTYPE'.
            DELETE values WHERE pointtype NOT IN filter-range.
          ENDIF.
        ENDLOOP.
      CATCH cx_rap_query_filter_no_range.
        " Non-range filters are not applicable to this fixed value set
    ENDTRY.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( values ) ).
    ENDIF.

    IF io_request->is_data_requested( ).
      DATA(paging) = io_request->get_paging( ).
      DATA(offset) = CONV i( paging->get_offset( ) ).
      DATA(page_size) = COND i( WHEN paging->get_page_size( ) = if_rap_query_paging=>page_size_unlimited
                                THEN lines( values )
                                ELSE paging->get_page_size( ) ).

      IF offset > 0.
        DELETE values TO offset.
      ENDIF.

      IF lines( values ) > page_size.
        DELETE values FROM page_size + 1.
      ENDIF.

      io_response->set_data( values ).
    ENDIF.
  ENDMETHOD.

  METHOD determine_language.
    TRY.
        result = cl_abap_context_info=>get_user_language_abap_format( ).
      CATCH cx_abap_context_info_error.
        result = fallback_language.
    ENDTRY.
  ENDMETHOD.

  METHOD read_domain_values.
    DATA point_type TYPE zapg_point_type.

    DATA(language) = determine_language( ).
    DATA(element) = CAST cl_abap_elemdescr( cl_abap_typedescr=>describe_by_data( point_type ) ).
    DATA(fixed_values) = element->get_ddic_fixed_values( language ).

    IF fixed_values IS INITIAL AND language <> fallback_language.
      " Domain texts are maintained in English only - fall back
      fixed_values = element->get_ddic_fixed_values( fallback_language ).
    ENDIF.

    result = VALUE #( FOR fixed_value IN fixed_values
                      ( pointtype   = fixed_value-low
                        description = fixed_value-ddtext ) ).
  ENDMETHOD.

ENDCLASS.
