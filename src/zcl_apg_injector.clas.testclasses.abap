*"* use this source file for your ABAP unit test classes
CLASS ltd_plain_handler DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_apg_handler.
ENDCLASS.

CLASS ltd_plain_handler IMPLEMENTATION.
  METHOD zif_apg_handler~execute.
  ENDMETHOD.
ENDCLASS.


CLASS ltd_plain_toggle DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_apg_activation_toggle.
ENDCLASS.

CLASS ltd_plain_toggle IMPLEMENTATION.
  METHOD zif_apg_activation_toggle~is_active.
    result = abap_true.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_injector DEFINITION
  FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    CONSTANTS mock_classname TYPE abap_classname VALUE 'LTD_PLAIN_HANDLER'.

    METHODS setup.
    METHODS teardown.

    METHODS given_mock_then_returned      FOR TESTING RAISING zcx_apg_error.
    METHODS given_wrong_type_then_raises  FOR TESTING.
    METHODS given_unknown_cls_then_raises FOR TESTING.
    METHODS given_clear_then_all_removed  FOR TESTING.
ENDCLASS.


CLASS ltc_injector IMPLEMENTATION.

  METHOD setup.
    zcl_apg_injector=>clear( ).
  ENDMETHOD.

  METHOD teardown.
    zcl_apg_injector=>clear( ).
  ENDMETHOD.

  METHOD given_mock_then_returned.
    " ARRANGE
    DATA(mock) = NEW ltd_plain_handler( ).
    zcl_apg_injector=>inject_instance( classname = mock_classname
                                       instance  = mock ).

    " ACT
    DATA(handler) = zcl_apg_injector=>get_handler( mock_classname ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = handler
                                        exp = mock
                                        msg = 'Injected mock must be returned unchanged' ).
  ENDMETHOD.

  METHOD given_wrong_type_then_raises.
    " ARRANGE - a toggle registered under a name requested as handler
    zcl_apg_injector=>inject_instance( classname = mock_classname
                                       instance  = NEW ltd_plain_toggle( ) ).

    TRY.
        " ACT
        zcl_apg_injector=>get_handler( mock_classname ).
        cl_abap_unit_assert=>fail( 'Wrong mock type must raise zcx_apg_error' ).
      CATCH zcx_apg_error INTO DATA(error).
        " ASSERT
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_apg_error=>interface_not_implemented
                                            msg = 'Wrong mock type must raise interface_not_implemented' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_unknown_cls_then_raises.
    TRY.
        " ACT
        zcl_apg_injector=>get_handler( 'ZCL_APG_DOES_NOT_EXIST' ).
        cl_abap_unit_assert=>fail( 'Unknown class must raise zcx_apg_error' ).
      CATCH zcx_apg_error INTO DATA(error).
        " ASSERT
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_apg_error=>instantiation_failed
                                            msg = 'Unknown class must raise instantiation_failed' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_clear_then_all_removed.
    " ARRANGE
    DATA(mock) = NEW ltd_plain_handler( ).
    zcl_apg_injector=>inject_instance( classname = mock_classname
                                       instance  = mock ).
    zcl_apg_injector=>inject_configurations(
        point_id       = 'TEST'
        configurations = VALUE #( ( point_id = 'TEST' ) ) ).

    " ACT
    zcl_apg_injector=>clear( ).

    " ASSERT
    cl_abap_unit_assert=>assert_initial(
        act = zcl_apg_injector=>get_configurations( 'TEST' )
        msg = 'Clear must remove injected configurations' ).

    TRY.
        DATA(handler) = zcl_apg_injector=>get_handler( mock_classname ).
        " Local double class is visible in this class pool, so dynamic
        " creation succeeds - a fresh instance proves the mock is gone
        cl_abap_unit_assert=>assert_false(
            act = xsdbool( handler = mock )
            msg = 'Clear must remove injected mocks' ).
      CATCH zcx_apg_error.
        " Also acceptable: without the mock, creation may fail
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
