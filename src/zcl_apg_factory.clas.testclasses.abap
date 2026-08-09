CLASS ltd_handler DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_apg_handler.
ENDCLASS.

CLASS ltd_handler IMPLEMENTATION.
  METHOD zif_apg_handler~execute.
  ENDMETHOD.
ENDCLASS.


CLASS ltd_counting_toggle DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_apg_activation_toggle.

    METHODS constructor
      IMPORTING active TYPE abap_bool.

    DATA call_count TYPE i READ-ONLY.

  PRIVATE SECTION.
    DATA active TYPE abap_bool.
ENDCLASS.

CLASS ltd_counting_toggle IMPLEMENTATION.
  METHOD constructor.
    me->active = active.
  ENDMETHOD.

  METHOD zif_apg_activation_toggle~is_active.
    call_count = call_count + 1.
    result = active.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_factory DEFINITION
  FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    CONSTANTS point_id        TYPE zapg_point_id VALUE 'TEST'.
    CONSTANTS handler_class_1 TYPE zapg_handler_class VALUE 'LTD_HANDLER_1'.
    CONSTANTS handler_class_2 TYPE zapg_handler_class VALUE 'LTD_HANDLER_2'.
    CONSTANTS toggle_class    TYPE zapg_activation_class VALUE 'LTD_COUNTING_TOGGLE'.

    CLASS-DATA osql_environment TYPE REF TO if_osql_test_environment.

    DATA context   TYPE REF TO zif_apg_context.
    DATA handler_1 TYPE REF TO ltd_handler.
    DATA handler_2 TYPE REF TO ltd_handler.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS teardown.

    METHODS insert_point
      IMPORTING active           TYPE zapg_active
                activation_class TYPE zapg_activation_class OPTIONAL.
    METHODS insert_gate
      IMPORTING seqno            TYPE zapg_seqno
                handler_class    TYPE zapg_handler_class
                active           TYPE zapg_active
                activation_class TYPE zapg_activation_class OPTIONAL
                param_1          TYPE zapg_parameter OPTIONAL
                param_2          TYPE zapg_parameter OPTIONAL.

    METHODS given_db_cfg_then_seq_order   FOR TESTING RAISING zcx_apg_error.
    METHODS given_inactive_gate_then_skip FOR TESTING RAISING zcx_apg_error.
    METHODS given_point_off_then_empty    FOR TESTING RAISING zcx_apg_error.
    METHODS given_point_tgl_then_one_call FOR TESTING RAISING zcx_apg_error.
    METHODS given_params_then_delivered   FOR TESTING RAISING zcx_apg_error.
ENDCLASS.


CLASS ltc_factory IMPLEMENTATION.

  METHOD class_setup.
    osql_environment = cl_osql_test_environment=>create( VALUE #( ( 'ZAPG_POINT' )
                                                                  ( 'ZAPG_GATE_HANDLE' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    osql_environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    osql_environment->clear_doubles( ).
    zcl_apg_injector=>clear( ).

    context   = NEW zcl_apg_context( ).
    handler_1 = NEW ltd_handler( ).
    handler_2 = NEW ltd_handler( ).
    zcl_apg_injector=>inject_instance( classname = handler_class_1
                                       instance  = handler_1 ).
    zcl_apg_injector=>inject_instance( classname = handler_class_2
                                       instance  = handler_2 ).
  ENDMETHOD.

  METHOD teardown.
    zcl_apg_injector=>clear( ).
  ENDMETHOD.

  METHOD insert_point.
    DATA points TYPE STANDARD TABLE OF zapg_point WITH EMPTY KEY.

    points = VALUE #( ( point_id         = point_id
                        active           = active
                        activation_class = activation_class ) ).
    osql_environment->insert_test_data( points ).
  ENDMETHOD.

  METHOD insert_gate.
    DATA gates TYPE STANDARD TABLE OF zapg_gate_handle WITH EMPTY KEY.

    gates = VALUE #( ( point_id         = point_id
                       seqno            = seqno
                       handler_class    = handler_class
                       active           = active
                       activation_class = activation_class
                       param_1          = param_1
                       param_2          = param_2 ) ).
    osql_environment->insert_test_data( gates ).
  ENDMETHOD.

  METHOD given_db_cfg_then_seq_order.
    " ARRANGE - two active gates, inserted in reverse sequence order
    insert_point( active = zcl_apg_factory=>activation_status-active ).
    insert_gate( seqno         = '002'
                 handler_class = handler_class_2
                 active        = zcl_apg_factory=>activation_status-active ).
    insert_gate( seqno         = '001'
                 handler_class = handler_class_1
                 active        = zcl_apg_factory=>activation_status-active ).

    " ACT
    DATA(handlers) = zcl_apg_factory=>get_active_handlers_for_gate( point_id = point_id
                                                                    context  = context ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = lines( handlers )
                                        exp = 2
                                        msg = 'Both active gates must be resolved' ).
    cl_abap_unit_assert=>assert_equals( act = handlers[ 1 ]-handler
                                        exp = handler_1
                                        msg = 'Handlers must be returned in seqno order' ).
  ENDMETHOD.

  METHOD given_inactive_gate_then_skip.
    " ARRANGE
    insert_point( active = zcl_apg_factory=>activation_status-active ).
    insert_gate( seqno         = '001'
                 handler_class = handler_class_1
                 active        = zcl_apg_factory=>activation_status-inactive ).
    insert_gate( seqno         = '002'
                 handler_class = handler_class_2
                 active        = zcl_apg_factory=>activation_status-active ).

    " ACT
    DATA(handlers) = zcl_apg_factory=>get_active_handlers_for_gate( point_id = point_id
                                                                    context  = context ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = lines( handlers )
                                        exp = 1
                                        msg = 'Inactive gate must not be resolved' ).
    cl_abap_unit_assert=>assert_equals( act = handlers[ 1 ]-handler
                                        exp = handler_2
                                        msg = 'Only the active gate must be resolved' ).
  ENDMETHOD.

  METHOD given_point_off_then_empty.
    " ARRANGE
    insert_point( active = zcl_apg_factory=>activation_status-inactive ).
    insert_gate( seqno         = '001'
                 handler_class = handler_class_1
                 active        = zcl_apg_factory=>activation_status-active ).

    " ACT
    DATA(handlers) = zcl_apg_factory=>get_active_handlers_for_gate( point_id = point_id
                                                                    context  = context ).

    " ASSERT
    cl_abap_unit_assert=>assert_initial( act = handlers
                                         msg = 'Inactive point must yield no handlers' ).
  ENDMETHOD.

  METHOD given_point_tgl_then_one_call.
    " ARRANGE - point with custom toggle, three active gates
    insert_point( active           = zcl_apg_factory=>activation_status-custom_toggle
                  activation_class = toggle_class ).
    insert_gate( seqno         = '001'
                 handler_class = handler_class_1
                 active        = zcl_apg_factory=>activation_status-active ).
    insert_gate( seqno         = '002'
                 handler_class = handler_class_2
                 active        = zcl_apg_factory=>activation_status-active ).
    insert_gate( seqno         = '003'
                 handler_class = handler_class_1
                 active        = zcl_apg_factory=>activation_status-active ).

    DATA(toggle) = NEW ltd_counting_toggle( active = abap_true ).
    zcl_apg_injector=>inject_instance( classname = toggle_class
                                       instance  = toggle ).

    " ACT
    DATA(handlers) = zcl_apg_factory=>get_active_handlers_for_gate( point_id = point_id
                                                                    context  = context ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = lines( handlers )
                                        exp = 3
                                        msg = 'All gates of an active point must be resolved' ).
    cl_abap_unit_assert=>assert_equals( act = toggle->call_count
                                        exp = 1
                                        msg = 'Point toggle must be evaluated exactly once' ).
  ENDMETHOD.

  METHOD given_params_then_delivered.
    " ARRANGE
    insert_point( active = zcl_apg_factory=>activation_status-active ).
    insert_gate( seqno         = '001'
                 handler_class = handler_class_1
                 active        = zcl_apg_factory=>activation_status-active
                 param_1       = 'ALPHA'
                 param_2       = 'BETA' ).

    " ACT
    DATA(handlers) = zcl_apg_factory=>get_active_handlers_for_gate( point_id = point_id
                                                                    context  = context ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = handlers[ 1 ]-parameters-param_1
                                        exp = 'ALPHA'
                                        msg = 'Param 1 must reach the resolved handler entry' ).
    cl_abap_unit_assert=>assert_equals( act = handlers[ 1 ]-parameters-param_2
                                        exp = 'BETA'
                                        msg = 'Param 2 must reach the resolved handler entry' ).
  ENDMETHOD.

ENDCLASS.
