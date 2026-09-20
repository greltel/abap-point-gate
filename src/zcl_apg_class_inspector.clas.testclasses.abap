*"* use this source file for your ABAP unit test classes
CLASS ltc_class_inspector DEFINITION
  FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zif_apg_class_inspector.

    METHODS setup.
    METHODS given_class_then_true        FOR TESTING.
    METHODS given_interface_then_false   FOR TESTING.
    METHODS given_unknown_then_false     FOR TESTING.
    METHODS given_implementor_then_true  FOR TESTING.
    METHODS given_non_impl_then_false    FOR TESTING.
    METHODS given_unknown_impl_then_fals FOR TESTING.
ENDCLASS.


CLASS ltc_class_inspector IMPLEMENTATION.

  METHOD setup.
    cut = NEW zcl_apg_class_inspector( ).
  ENDMETHOD.

  METHOD given_class_then_true.
    cl_abap_unit_assert=>assert_true( act = cut->is_class( 'ZCL_APG_CONTEXT' )
                                      msg = `An existing global class must be recognized` ).
  ENDMETHOD.

  METHOD given_interface_then_false.
    cl_abap_unit_assert=>assert_false( act = cut->is_class( 'ZIF_APG_HANDLER' )
                                       msg = `An interface must not count as a class` ).
  ENDMETHOD.

  METHOD given_unknown_then_false.
    cl_abap_unit_assert=>assert_false( act = cut->is_class( 'ZCL_APG_DOES_NOT_EXIST' )
                                       msg = `An unknown name must not count as a class` ).
  ENDMETHOD.

  METHOD given_implementor_then_true.
    cl_abap_unit_assert=>assert_true(
        act = cut->implements( classname = 'ZCL_APG_ACT_TOGGLE_SAMPLE'
                               interface = zif_apg_class_inspector=>interface-toggle )
        msg = `The toggle sample must be recognized as a toggle implementor` ).
  ENDMETHOD.

  METHOD given_non_impl_then_false.
    cl_abap_unit_assert=>assert_false(
        act = cut->implements( classname = 'ZCL_APG_CONTEXT'
                               interface = zif_apg_class_inspector=>interface-toggle )
        msg = `A class that does not implement the toggle interface must be rejected` ).
  ENDMETHOD.

  METHOD given_unknown_impl_then_fals.
    cl_abap_unit_assert=>assert_false(
        act = cut->implements( classname = 'ZCL_APG_DOES_NOT_EXIST'
                               interface = zif_apg_class_inspector=>interface-handler )
        msg = `An unknown class must never be reported as an implementor` ).
  ENDMETHOD.

ENDCLASS.
