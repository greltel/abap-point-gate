*"* use this source file for your ABAP unit test classes
CLASS ltd_class_inspector DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_apg_class_inspector.

    METHODS constructor
      IMPORTING class_exists         TYPE abap_bool DEFAULT abap_true
                implements_interface TYPE abap_bool DEFAULT abap_true.

  PRIVATE SECTION.
    DATA class_exists         TYPE abap_bool.
    DATA implements_interface TYPE abap_bool.
ENDCLASS.

CLASS ltd_class_inspector IMPLEMENTATION.
  METHOD constructor.
    me->class_exists         = class_exists.
    me->implements_interface = implements_interface.
  ENDMETHOD.

  METHOD zif_apg_class_inspector~is_class.
    result = class_exists.
  ENDMETHOD.

  METHOD zif_apg_class_inspector~implements.
    result = implements_interface.
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


CLASS ltc_activation_check DEFINITION
  FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    CONSTANTS some_class TYPE zapg_activation_class VALUE 'ZCL_APG_ACT_TOGGLE_SAMPLE'.

    METHODS check
      IMPORTING active               TYPE zapg_active
                activation_class     TYPE zapg_activation_class
                class_exists         TYPE abap_bool DEFAULT abap_true
                implements_interface TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(result)        TYPE lcl_activation_check=>tt_findings.

    "! Returns the T100 key of the first finding, or an initial key when valid.
    METHODS first_textid
      IMPORTING active               TYPE zapg_active
                activation_class     TYPE zapg_activation_class
                class_exists         TYPE abap_bool DEFAULT abap_true
                implements_interface TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(result)        LIKE if_t100_message=>t100key.

    METHODS given_x_no_class_then_ok      FOR TESTING.
    METHODS given_x_with_class_then_not_a FOR TESTING.
    METHODS given_c_no_class_then_req     FOR TESTING.
    METHODS given_c_unknown_then_missing  FOR TESTING.
    METHODS given_c_wrong_class_then_intf FOR TESTING.
    METHODS given_c_valid_then_ok         FOR TESTING.
ENDCLASS.


CLASS ltc_activation_check IMPLEMENTATION.

  METHOD check.
    DATA(cut) = NEW lcl_activation_check( NEW ltd_class_inspector(
                                              class_exists         = class_exists
                                              implements_interface = implements_interface ) ).
    result = cut->check( active           = active
                         activation_class = activation_class ).
  ENDMETHOD.

  METHOD first_textid.
    DATA(findings) = check( active               = active
                            activation_class     = activation_class
                            class_exists         = class_exists
                            implements_interface = implements_interface ).
    result = VALUE #( findings[ 1 ]-textid OPTIONAL ).
  ENDMETHOD.

  METHOD given_x_no_class_then_ok.
    cl_abap_unit_assert=>assert_initial(
        act = check( active           = zcl_apg_factory=>activation_status-active
                     activation_class = space )
        msg = `Status X without an activation class must be valid` ).
  ENDMETHOD.

  METHOD given_x_with_class_then_not_a.
    cl_abap_unit_assert=>assert_equals(
        act = first_textid( active           = zcl_apg_factory=>activation_status-active
                            activation_class = some_class )
        exp = zcm_apg_point=>activation_class_not_allowed
        msg = `An activation class without status C must be rejected` ).
  ENDMETHOD.

  METHOD given_c_no_class_then_req.
    cl_abap_unit_assert=>assert_equals(
        act = first_textid( active           = zcl_apg_factory=>activation_status-custom_toggle
                            activation_class = space )
        exp = zcm_apg_point=>activation_class_required
        msg = `Status C without an activation class must be rejected` ).
  ENDMETHOD.

  METHOD given_c_unknown_then_missing.
    cl_abap_unit_assert=>assert_equals(
        act = first_textid( active           = zcl_apg_factory=>activation_status-custom_toggle
                            activation_class = some_class
                            class_exists     = abap_false )
        exp = zcm_apg_point=>class_not_found
        msg = `An activation class that does not exist must be rejected` ).
  ENDMETHOD.

  METHOD given_c_wrong_class_then_intf.
    cl_abap_unit_assert=>assert_equals(
        act = first_textid( active               = zcl_apg_factory=>activation_status-custom_toggle
                            activation_class     = some_class
                            implements_interface = abap_false )
        exp = zcm_apg_point=>interface_not_implemented
        msg = `An activation class that is not a toggle must be rejected` ).
  ENDMETHOD.

  METHOD given_c_valid_then_ok.
    cl_abap_unit_assert=>assert_initial(
        act = check( active           = zcl_apg_factory=>activation_status-custom_toggle
                     activation_class = some_class )
        msg = `Status C with a valid toggle class must be valid` ).
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
    METHODS given_no_inject_then_rtti    FOR TESTING.
    METHODS given_inject_then_inspector  FOR TESTING.
ENDCLASS.


CLASS ltc_point_factory IMPLEMENTATION.

  METHOD teardown.
    lcl_point_factory=>inject_authorization( VALUE #( ) ).
    lcl_point_factory=>inject_class_inspector( VALUE #( ) ).
  ENDMETHOD.

  METHOD given_no_inject_then_adapter.
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

  METHOD given_no_inject_then_rtti.
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( lcl_point_factory=>class_inspector( ) IS INSTANCE OF zcl_apg_class_inspector )
        msg = `Without injection the factory must return the repository inspector` ).
  ENDMETHOD.

  METHOD given_inject_then_inspector.
    " ARRANGE
    DATA(double) = NEW ltd_class_inspector( ).
    lcl_point_factory=>inject_class_inspector( double ).

    " ACT & ASSERT
    cl_abap_unit_assert=>assert_equals( act = lcl_point_factory=>class_inspector( )
                                        exp = double
                                        msg = `An injected inspector must be handed out unchanged` ).
  ENDMETHOD.

ENDCLASS.
