"! <p class="shorttext synchronized" lang="EN">Point type value help</p>
"! Query provider that serves the fixed values of data element ZAPG_POINT_TYPE.
"! The dictionary access itself lives behind {@link zif_apg_domain_values}.
CLASS zcl_apg_point_type_vh DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    "! Creates the query provider with the source of the fixed values.
    "! @parameter domain_values | Injected in tests; the production default reads the dictionary
    METHODS constructor
      IMPORTING domain_values TYPE REF TO zif_apg_domain_values OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS data_element   TYPE string VALUE `ZAPG_POINT_TYPE`.
    CONSTANTS filter_element TYPE string VALUE `POINTTYPE`.

    TYPES tt_values TYPE STANDARD TABLE OF zi_apg_point_type_vh WITH EMPTY KEY.

    DATA domain_values TYPE REF TO zif_apg_domain_values.

    "! Maps the dictionary fixed values onto the value-help entity rows.
    METHODS read_values
      RETURNING VALUE(result) TYPE tt_values.
ENDCLASS.


CLASS zcl_apg_point_type_vh IMPLEMENTATION.

  METHOD constructor.
    me->domain_values = COND #( WHEN domain_values IS BOUND
                                THEN domain_values
                                ELSE NEW zcl_apg_domain_values( ) ).
  ENDMETHOD.

  METHOD read_values.
    result = VALUE #( FOR value IN domain_values->read( data_element )
                      ( pointtype   = value-code
                        description = value-description ) ).
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    " Sorting is deliberately not applied: the set is a handful of dictionary
    " fixed values delivered in dictionary order, which is the order the value
    " help is meant to show.
    DATA(values) = read_values( ).

    TRY.
        LOOP AT io_request->get_filter( )->get_as_ranges( ) INTO DATA(filter).
          IF to_upper( filter-name ) = filter_element.
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
      DATA(paging)    = io_request->get_paging( ).
      DATA(offset)    = CONV i( paging->get_offset( ) ).
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

ENDCLASS.
