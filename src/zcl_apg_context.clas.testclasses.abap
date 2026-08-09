CLASS ltc_context DEFINITION
  FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zif_apg_context.

    METHODS setup.
    METHODS given_string_then_returned  FOR TESTING RAISING zcx_apg_error.
    METHODS given_date_then_returned    FOR TESTING RAISING zcx_apg_error.
    METHODS given_int_then_returned     FOR TESTING RAISING zcx_apg_error.
    METHODS given_set_twice_then_latest FOR TESTING RAISING zcx_apg_error.
    METHODS given_value_then_has_data   FOR TESTING.
    METHODS given_missing_then_raises   FOR TESTING.
ENDCLASS.


CLASS ltc_context IMPLEMENTATION.

  METHOD setup.
    cut = NEW zcl_apg_context( ).
  ENDMETHOD.

  METHOD given_string_then_returned.
    " ARRANGE
    cut->set_data( name  = `TEXT`
                   value = NEW string( `Hello` ) ).

    " ACT
    DATA(text) = cut->get_string( `TEXT` ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = text
                                        exp = `Hello`
                                        msg = 'Stored string was not returned unchanged' ).
  ENDMETHOD.

  METHOD given_date_then_returned.
    " ARRANGE
    DATA(today) = cl_abap_context_info=>get_system_date( ).
    cut->set_data( name  = `DATE`
                   value = REF #( today ) ).

    " ACT
    DATA(stored_date) = cut->get_date( `DATE` ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = stored_date
                                        exp = today
                                        msg = 'Stored date was not returned unchanged' ).
  ENDMETHOD.

  METHOD given_int_then_returned.
    " ARRANGE
    cut->set_data( name  = `NUMBER`
                   value = NEW i( 42 ) ).

    " ACT
    DATA(number) = cut->get_integer( `NUMBER` ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = number
                                        exp = 42
                                        msg = 'Stored integer was not returned unchanged' ).
  ENDMETHOD.

  METHOD given_set_twice_then_latest.
    " ARRANGE
    cut->set_data( name  = `TEXT`
                   value = NEW string( `First` ) ).
    cut->set_data( name  = `TEXT`
                   value = NEW string( `Second` ) ).

    " ACT
    DATA(text) = cut->get_string( `TEXT` ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = text
                                        exp = `Second`
                                        msg = 'Overwriting a name must keep the latest value' ).
  ENDMETHOD.

  METHOD given_value_then_has_data.
    " ARRANGE
    cut->set_data( name  = `TEXT`
                   value = NEW string( `Hello` ) ).

    " ACT & ASSERT
    cl_abap_unit_assert=>assert_true( act = cut->has_data( `TEXT` )
                                      msg = 'has_data must be true for a stored name' ).
    cl_abap_unit_assert=>assert_false( act = cut->has_data( `MISSING` )
                                       msg = 'has_data must be false for an unknown name' ).
  ENDMETHOD.

  METHOD given_missing_then_raises.
    TRY.
        " ACT
        cut->get_string( `MISSING` ).
        cl_abap_unit_assert=>fail( 'Reading a missing name must raise zcx_apg_error' ).
      CATCH zcx_apg_error INTO DATA(error).
        " ASSERT
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_apg_error=>context_value_missing
                                            msg = 'Missing value must raise textid context_value_missing' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
