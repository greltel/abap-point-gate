*"* use this source file for your ABAP unit test classes
CLASS ltc_activation_check DEFINITION
  FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS given_x_no_class_then_ok     FOR TESTING.
    METHODS given_x_with_class_then_007  FOR TESTING.
    METHODS given_c_no_class_then_006    FOR TESTING.
    METHODS given_c_unknown_then_001     FOR TESTING.
    METHODS given_c_wrong_class_then_002 FOR TESTING.
    METHODS given_c_valid_then_ok        FOR TESTING.
ENDCLASS.


CLASS ltc_activation_check IMPLEMENTATION.

  METHOD given_x_no_class_then_ok.
    cl_abap_unit_assert=>assert_initial(
        act = lcl_activation_check=>check( active           = zcl_apg_factory=>activation_status-active
                                           activation_class = '' )
        msg = 'Status X without activation class must be valid' ).
  ENDMETHOD.

  METHOD given_x_with_class_then_007.
    DATA(findings) = lcl_activation_check=>check( active           = zcl_apg_factory=>activation_status-active
                                                  activation_class = 'ZCL_APG_ACT_TOGGLE_SAMPLE' ).

    cl_abap_unit_assert=>assert_equals( act = findings[ 1 ]-msgno
                                        exp = '007'
                                        msg = 'Activation class without status C must yield message 007' ).
  ENDMETHOD.

  METHOD given_c_no_class_then_006.
    DATA(findings) = lcl_activation_check=>check( active           = zcl_apg_factory=>activation_status-custom_toggle
                                                  activation_class = '' ).

    cl_abap_unit_assert=>assert_equals( act = findings[ 1 ]-msgno
                                        exp = '006'
                                        msg = 'Status C without activation class must yield message 006' ).
  ENDMETHOD.

  METHOD given_c_unknown_then_001.
    DATA(findings) = lcl_activation_check=>check( active           = zcl_apg_factory=>activation_status-custom_toggle
                                                  activation_class = 'ZCL_APG_DOES_NOT_EXIST' ).

    cl_abap_unit_assert=>assert_equals( act = findings[ 1 ]-msgno
                                        exp = '001'
                                        msg = 'Unknown activation class must yield message 001' ).
  ENDMETHOD.

  METHOD given_c_wrong_class_then_002.
    " ZCL_APG_CONTEXT exists but does not implement the toggle interface
    DATA(findings) = lcl_activation_check=>check( active           = zcl_apg_factory=>activation_status-custom_toggle
                                                  activation_class = 'ZCL_APG_CONTEXT' ).

    cl_abap_unit_assert=>assert_equals( act = findings[ 1 ]-msgno
                                        exp = '002'
                                        msg = 'Non-toggle class must yield message 002' ).
  ENDMETHOD.

  METHOD given_c_valid_then_ok.
    cl_abap_unit_assert=>assert_initial(
        act = lcl_activation_check=>check( active           = zcl_apg_factory=>activation_status-custom_toggle
                                           activation_class = 'ZCL_APG_ACT_TOGGLE_SAMPLE' )
        msg = 'Status C with a valid toggle class must be valid' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_class_inspector DEFINITION
  FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS given_class_then_true       FOR TESTING.
    METHODS given_interface_then_false  FOR TESTING.
    METHODS given_implementor_then_true FOR TESTING.
ENDCLASS.


CLASS ltc_class_inspector IMPLEMENTATION.

  METHOD given_class_then_true.
    cl_abap_unit_assert=>assert_true(
        act = lcl_class_inspector=>is_class( 'ZCL_APG_CONTEXT' )
        msg = 'An existing global class must be recognized' ).
  ENDMETHOD.

  METHOD given_interface_then_false.
    cl_abap_unit_assert=>assert_false(
        act = lcl_class_inspector=>is_class( 'ZIF_APG_HANDLER' )
        msg = 'An interface must not count as a class' ).
  ENDMETHOD.

  METHOD given_implementor_then_true.
    cl_abap_unit_assert=>assert_true(
        act = lcl_class_inspector=>implements( classname = 'ZCL_APG_ACT_TOGGLE_SAMPLE'
                                               interface = lcl_class_inspector=>toggle_interface )
        msg = 'Toggle sample must be recognized as toggle implementor' ).
  ENDMETHOD.

ENDCLASS.

CLASS ltd_authorization DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_apg_authorization.

    METHODS constructor
      IMPORTING allowed TYPE abap_bool.

  PRIVATE SECTION.
    DATA allowed TYPE abap_bool.
ENDCLASS.

CLASS ltd_authorization IMPLEMENTATION.
  METHOD constructor.
    me->allowed = allowed.
  ENDMETHOD.

  METHOD zif_apg_authorization~is_allowed.
    result = allowed.
  ENDMETHOD.

  METHOD zif_apg_authorization~is_allowed_for_point.
    result = allowed.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_point_factory DEFINITION
  FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS teardown.
    METHODS given_no_inject_then_adapter FOR TESTING.
    METHODS given_inject_then_double     FOR TESTING.
    METHODS given_unbound_then_restored  FOR TESTING.
ENDCLASS.


CLASS ltc_point_factory IMPLEMENTATION.

  METHOD teardown.
    lcl_point_factory=>inject_authorization( VALUE #( ) ).
  ENDMETHOD.

  METHOD given_no_inject_then_adapter.
    " ACT & ASSERT - the production default is the AUTHORITY-CHECK adapter
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( lcl_point_factory=>authorization( ) IS INSTANCE OF zcl_apg_authorization )
        msg = `Without injection the factory must return the production adapter` ).
  ENDMETHOD.

  METHOD given_inject_then_double.
    " ARRANGE
    DATA(double) = NEW ltd_authorization( abap_false ).
    lcl_point_factory=>inject_authorization( double ).

    " ACT & ASSERT
    cl_abap_unit_assert=>assert_equals( act = lcl_point_factory=>authorization( )
                                        exp = double
                                        msg = `An injected double must be handed out unchanged` ).
  ENDMETHOD.

  METHOD given_unbound_then_restored.
    " ARRANGE
    lcl_point_factory=>inject_authorization( NEW ltd_authorization( abap_false ) ).

    " ACT
    lcl_point_factory=>inject_authorization( VALUE #( ) ).

    " ASSERT
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( lcl_point_factory=>authorization( ) IS INSTANCE OF zcl_apg_authorization )
        msg = `An unbound injection must restore the production adapter` ).
  ENDMETHOD.

ENDCLASS.
