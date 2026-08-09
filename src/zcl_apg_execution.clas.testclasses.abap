CLASS ltd_handler DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_apg_handler.
    DATA was_called          TYPE abap_bool.
    DATA received_parameters TYPE zif_apg_handler=>ty_parameters.
ENDCLASS.

CLASS ltd_handler IMPLEMENTATION.
  METHOD zif_apg_handler~execute.
    was_called          = abap_true.
    received_parameters = parameters.
    INSERT VALUE #( type    = 'S'
                    message = 'Handler executed' ) INTO TABLE messages.
  ENDMETHOD.
ENDCLASS.


CLASS ltd_failing_handler DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_apg_handler.
ENDCLASS.

CLASS ltd_failing_handler IMPLEMENTATION.
  METHOD zif_apg_handler~execute.
    RAISE EXCEPTION NEW zcx_apg_error( textid     = zcx_apg_error=>instantiation_failed
                                       class_name = `LTD_FAILING_HANDLER` ).
  ENDMETHOD.
ENDCLASS.


CLASS ltd_toggle DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_apg_activation_toggle.

    METHODS constructor
      IMPORTING active TYPE abap_bool.

  PRIVATE SECTION.
    DATA active TYPE abap_bool.
ENDCLASS.

CLASS ltd_toggle IMPLEMENTATION.
  METHOD constructor.
    me->active = active.
  ENDMETHOD.

  METHOD zif_apg_activation_toggle~is_active.
    result = active.
  ENDMETHOD.
ENDCLASS.

CLASS ltc_execution DEFINITION
  FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    CONSTANTS point_id      TYPE zapg_point_id VALUE 'TEST'.
    CONSTANTS handler_class TYPE zapg_handler_class VALUE 'LTD_HANDLER'.
    CONSTANTS toggle_class  TYPE zapg_activation_class VALUE 'LTD_TOGGLE'.

    DATA context TYPE REF TO zif_apg_context.
    DATA handler TYPE REF TO ltd_handler.

    METHODS setup.
    METHODS teardown.
    METHODS inject_gate
      IMPORTING point_active TYPE zapg_active
                gate_active  TYPE zapg_active.

    METHODS given_active_gate_then_runs FOR TESTING RAISING zcx_apg_error.
    METHODS given_toggle_on_then_runs   FOR TESTING RAISING zcx_apg_error.
    METHODS given_toggle_off_then_skips FOR TESTING RAISING zcx_apg_error.
    METHODS given_point_off_then_skips  FOR TESTING RAISING zcx_apg_error.
    METHODS given_error_then_continues  FOR TESTING RAISING zcx_apg_error.
    METHODS given_params_then_passed  FOR TESTING RAISING zcx_apg_error.
ENDCLASS.


CLASS ltc_execution IMPLEMENTATION.

  METHOD setup.
    zcl_apg_injector=>clear( ).
    context = NEW zcl_apg_context( ).
    handler = NEW ltd_handler( ).
    zcl_apg_injector=>inject_instance( classname = handler_class
                                       instance  = handler ).
  ENDMETHOD.

  METHOD teardown.
    zcl_apg_injector=>clear( ).
  ENDMETHOD.

  METHOD inject_gate.
    DATA(point_toggle) = COND zapg_activation_class(
      WHEN point_active = zcl_apg_factory=>activation_status-custom_toggle THEN toggle_class ).
    DATA(gate_toggle) = COND zapg_activation_class(
      WHEN gate_active = zcl_apg_factory=>activation_status-custom_toggle THEN toggle_class ).

    zcl_apg_injector=>inject_configurations(
        point_id       = point_id
        configurations = VALUE #( ( point_id               = point_id
                                    point_active           = point_active
                                    point_activation_class = point_toggle
                                    seqno                  = '001'
                                    handler_class          = handler_class
                                    gate_active            = gate_active
                                    gate_activation_class  = gate_toggle ) ) ).
  ENDMETHOD.

  METHOD given_active_gate_then_runs.
    " ARRANGE
    inject_gate( point_active = zcl_apg_factory=>activation_status-active
                 gate_active  = zcl_apg_factory=>activation_status-active ).
    DATA messages TYPE zif_apg_handler=>tt_messages.

    " ACT
    zcl_apg_execution=>execute_gate( EXPORTING point_id = point_id
                                               context  = context
                                     CHANGING  messages = messages ).

    " ASSERT
    cl_abap_unit_assert=>assert_true( act = handler->was_called
                                      msg = 'Handler of an active gate must be executed' ).
    cl_abap_unit_assert=>assert_not_initial( act = messages
                                             msg = 'Handler messages must reach the container' ).
  ENDMETHOD.

  METHOD given_toggle_on_then_runs.
    " ARRANGE
    inject_gate( point_active = zcl_apg_factory=>activation_status-active
                 gate_active  = zcl_apg_factory=>activation_status-custom_toggle ).
    zcl_apg_injector=>inject_instance( classname = toggle_class
                                       instance  = NEW ltd_toggle( active = abap_true ) ).
    DATA messages TYPE zif_apg_handler=>tt_messages.

    " ACT
    zcl_apg_execution=>execute_gate( EXPORTING point_id = point_id
                                               context  = context
                                     CHANGING  messages = messages ).

    " ASSERT
    cl_abap_unit_assert=>assert_true( act = handler->was_called
                                      msg = 'Gate with active toggle must execute its handler' ).
  ENDMETHOD.

  METHOD given_toggle_off_then_skips.
    " ARRANGE
    inject_gate( point_active = zcl_apg_factory=>activation_status-active
                 gate_active  = zcl_apg_factory=>activation_status-custom_toggle ).
    zcl_apg_injector=>inject_instance( classname = toggle_class
                                       instance  = NEW ltd_toggle( active = abap_false ) ).
    DATA messages TYPE zif_apg_handler=>tt_messages.

    " ACT
    zcl_apg_execution=>execute_gate( EXPORTING point_id = point_id
                                               context  = context
                                     CHANGING  messages = messages ).

    " ASSERT
    cl_abap_unit_assert=>assert_false( act = handler->was_called
                                       msg = 'Gate with inactive toggle must not execute its handler' ).
  ENDMETHOD.

  METHOD given_point_off_then_skips.
    " ARRANGE
    inject_gate( point_active = zcl_apg_factory=>activation_status-custom_toggle
                 gate_active  = zcl_apg_factory=>activation_status-active ).
    zcl_apg_injector=>inject_instance( classname = toggle_class
                                       instance  = NEW ltd_toggle( active = abap_false ) ).
    DATA messages TYPE zif_apg_handler=>tt_messages.

    " ACT
    zcl_apg_execution=>execute_gate( EXPORTING point_id = point_id
                                               context  = context
                                     CHANGING  messages = messages ).

    " ASSERT
    cl_abap_unit_assert=>assert_false( act = handler->was_called
                                       msg = 'Inactive point must suppress all of its gates' ).
  ENDMETHOD.

  METHOD given_error_then_continues.
    " ARRANGE - failing handler on seqno 001, normal handler on seqno 002
    zcl_apg_injector=>inject_configurations(
        point_id       = point_id
        configurations = VALUE #( ( point_id      = point_id
                                    point_active  = zcl_apg_factory=>activation_status-active
                                    seqno         = '001'
                                    handler_class = 'LTD_FAILING_HANDLER'
                                    gate_active   = zcl_apg_factory=>activation_status-active )
                                  ( point_id      = point_id
                                    point_active  = zcl_apg_factory=>activation_status-active
                                    seqno         = '002'
                                    handler_class = handler_class
                                    gate_active   = zcl_apg_factory=>activation_status-active ) ) ).
    zcl_apg_injector=>inject_instance( classname = 'LTD_FAILING_HANDLER'
                                       instance  = NEW ltd_failing_handler( ) ).
    DATA messages TYPE zif_apg_handler=>tt_messages.

    " ACT
    zcl_apg_execution=>execute_gate( EXPORTING point_id = point_id
                                               context  = context
                                     CHANGING  messages = messages ).

    " ASSERT
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( messages[ type = 'E' ] ) )
        msg = 'A failing handler must produce an error message' ).
    cl_abap_unit_assert=>assert_true(
        act = handler->was_called
        msg = 'A failing handler must not stop the following handlers' ).
  ENDMETHOD.

  METHOD given_params_then_passed.
    " ARRANGE
    zcl_apg_injector=>inject_configurations(
        point_id       = point_id
        configurations = VALUE #( ( point_id      = point_id
                                    point_active  = zcl_apg_factory=>activation_status-active
                                    seqno         = '001'
                                    handler_class = handler_class
                                    gate_active   = zcl_apg_factory=>activation_status-active
                                    param_1       = 'ALPHA'
                                    param_2       = 'BETA' ) ) ).
    DATA messages TYPE zif_apg_handler=>tt_messages.

    " ACT
    zcl_apg_execution=>execute_gate( EXPORTING point_id = point_id
                                               context  = context
                                     CHANGING  messages = messages ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = handler->received_parameters-param_1
                                        exp = 'ALPHA'
                                        msg = 'Gate parameters must be passed to the handler' ).
  ENDMETHOD.

ENDCLASS.
