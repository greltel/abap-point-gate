CLASS ltd_handler DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_apg_handler.
ENDCLASS.


CLASS ltd_handler IMPLEMENTATION.
  METHOD zif_apg_handler~execute.
  ENDMETHOD.
ENDCLASS.


CLASS ltd_failing_toggle DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_apg_activation_toggle.
ENDCLASS.


CLASS ltd_failing_toggle IMPLEMENTATION.
  METHOD zif_apg_activation_toggle~is_active.
    RAISE EXCEPTION NEW zcx_apg_error( textid     = zcx_apg_error=>class_not_found
                                       class_name = `LTD_FAILING_TOGGLE` ).
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
    call_count += 1.
    result = active.
  ENDMETHOD.
ENDCLASS.


CLASS lth_factory DEFINITION ABSTRACT
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PROTECTED SECTION.
    CONSTANTS point_id        TYPE zapg_point_id         VALUE 'TEST'.
    CONSTANTS handler_class_1 TYPE zapg_handler_class    VALUE 'LTD_HANDLER_1'.
    CONSTANTS handler_class_2 TYPE zapg_handler_class    VALUE 'LTD_HANDLER_2'.
    CONSTANTS point_toggle    TYPE zapg_activation_class VALUE 'LTD_POINT_TOGGLE'.
    CONSTANTS gate_toggle     TYPE zapg_activation_class VALUE 'LTD_GATE_TOGGLE'.
    CONSTANTS failing_toggle  TYPE zapg_activation_class VALUE 'LTD_FAILING_TOGGLE'.

    DATA context   TYPE REF TO zif_apg_context.
    DATA handler_1 TYPE REF TO ltd_handler.
    DATA handler_2 TYPE REF TO ltd_handler.

    METHODS arrange_fixture.

    METHODS inject_toggle
      IMPORTING activation_class TYPE zapg_activation_class
                active           TYPE abap_bool
      RETURNING VALUE(result)    TYPE REF TO ltd_counting_toggle.

    METHODS resolve
      RETURNING VALUE(result) TYPE zcl_apg_factory=>tt_active_handlers
      RAISING   zcx_apg_error.
ENDCLASS.


CLASS lth_factory IMPLEMENTATION.
  METHOD arrange_fixture.
    zcl_apg_injector=>clear( ).

    context   = NEW zcl_apg_context( ).
    handler_1 = NEW ltd_handler( ).
    handler_2 = NEW ltd_handler( ).
    zcl_apg_injector=>inject_instance( classname = handler_class_1
                                       instance  = handler_1 ).
    zcl_apg_injector=>inject_instance( classname = handler_class_2
                                       instance  = handler_2 ).
  ENDMETHOD.

  METHOD inject_toggle.
    result = NEW #( active ).
    zcl_apg_injector=>inject_instance( classname = activation_class
                                       instance  = result ).
  ENDMETHOD.

  METHOD resolve.
    result = zcl_apg_factory=>get_active_handlers_for_gate( point_id = point_id
                                                            context  = context ).
  ENDMETHOD.
ENDCLASS.


"! Activation logic against injected configurations - no database involved.
"! Runs in ADT and in the off-stack CI alike.
CLASS ltc_factory DEFINITION
  INHERITING FROM lth_factory FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS setup.
    METHODS teardown.

    METHODS inject
      IMPORTING configurations TYPE zcl_apg_injector=>tt_configurations.

    METHODS gate
      IMPORTING handler_class          TYPE zapg_handler_class
                gate_active            TYPE zapg_active           DEFAULT zcl_apg_factory=>activation_status-active
                gate_activation_class  TYPE zapg_activation_class OPTIONAL
                point_active           TYPE zapg_active           DEFAULT zcl_apg_factory=>activation_status-active
                point_activation_class TYPE zapg_activation_class OPTIONAL
                param_1                TYPE zapg_parameter        OPTIONAL
                param_2                TYPE zapg_parameter        OPTIONAL
      RETURNING VALUE(result)          TYPE zcl_apg_injector=>ty_configuration.

    METHODS given_active_gates_then_all    FOR TESTING RAISING zcx_apg_error.
    METHODS given_inactive_gate_then_skip  FOR TESTING RAISING zcx_apg_error.
    METHODS given_unknown_status_then_skip FOR TESTING RAISING zcx_apg_error.
    METHODS given_point_off_then_empty     FOR TESTING RAISING zcx_apg_error.
    METHODS given_point_tgl_then_one_call  FOR TESTING RAISING zcx_apg_error.
    METHODS given_point_tgl_off_then_empty FOR TESTING RAISING zcx_apg_error.
    METHODS given_gate_tgl_on_then_runs    FOR TESTING RAISING zcx_apg_error.
    METHODS given_gate_tgl_off_then_skip   FOR TESTING RAISING zcx_apg_error.
    METHODS given_params_then_delivered    FOR TESTING RAISING zcx_apg_error.
    METHODS given_toggle_err_then_008      FOR TESTING RAISING zcx_apg_error.
    METHODS given_empty_inject_then_none   FOR TESTING RAISING zcx_apg_error.
ENDCLASS.


CLASS ltc_factory IMPLEMENTATION.
  METHOD setup.
    arrange_fixture( ).
  ENDMETHOD.

  METHOD teardown.
    zcl_apg_injector=>clear( ).
  ENDMETHOD.

  METHOD inject.
    zcl_apg_injector=>inject_configurations( point_id       = point_id
                                             configurations = configurations ).
  ENDMETHOD.

  METHOD gate.
    result = VALUE #( point_id               = point_id
                      point_active           = point_active
                      point_activation_class = point_activation_class
                      handler_class          = handler_class
                      gate_active            = gate_active
                      gate_activation_class  = gate_activation_class
                      param_1                = param_1
                      param_2                = param_2 ).
  ENDMETHOD.

  METHOD given_active_gates_then_all.
    " ARRANGE
    inject( VALUE #( ( gate( handler_class_1 ) )
                     ( gate( handler_class_2 ) ) ) ).

    " ACT
    DATA(handlers) = resolve( ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( handlers )
                                        msg = 'Both active gates must be resolved' ).
    cl_abap_unit_assert=>assert_equals( exp = handler_1
                                        act = handlers[ 1 ]-handler
                                        msg = 'Configuration order must be execution order' ).
  ENDMETHOD.

  METHOD given_inactive_gate_then_skip.
    " ARRANGE
    inject( VALUE #( ( gate( handler_class = handler_class_1
                             gate_active   = zcl_apg_factory=>activation_status-inactive ) )
                     ( gate( handler_class_2 ) ) ) ).

    " ACT
    DATA(handlers) = resolve( ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( handlers )
                                        msg = 'Inactive gate must not be resolved' ).
    cl_abap_unit_assert=>assert_equals( exp = handler_2
                                        act = handlers[ 1 ]-handler
                                        msg = 'Only the active gate must be resolved' ).
  ENDMETHOD.

  METHOD given_unknown_status_then_skip.
    " ARRANGE - blank status is 'unknown' and must be treated as inactive
    inject( VALUE #( ( gate( handler_class = handler_class_1
                             gate_active   = space ) ) ) ).

    " ACT
    DATA(handlers) = resolve( ).

    " ASSERT
    cl_abap_unit_assert=>assert_initial( act = handlers
                                         msg = 'Unknown gate status must be treated as inactive' ).
  ENDMETHOD.

  METHOD given_point_off_then_empty.
    " ARRANGE
    inject( VALUE #( ( gate( handler_class = handler_class_1
                             point_active  = zcl_apg_factory=>activation_status-inactive ) ) ) ).

    " ACT
    DATA(handlers) = resolve( ).

    " ASSERT
    cl_abap_unit_assert=>assert_initial( act = handlers
                                         msg = 'Inactive point must yield no handlers' ).
  ENDMETHOD.

  METHOD given_point_tgl_then_one_call.
    " ARRANGE - point with custom toggle, three active gates
    DATA(toggle) = inject_toggle( activation_class = point_toggle
                                  active           = abap_true ).
    inject( VALUE #( ( gate( handler_class          = handler_class_1
                             point_active           = zcl_apg_factory=>activation_status-custom_toggle
                             point_activation_class = point_toggle ) )
                     ( gate( handler_class          = handler_class_2
                             point_active           = zcl_apg_factory=>activation_status-custom_toggle
                             point_activation_class = point_toggle ) )
                     ( gate( handler_class          = handler_class_1
                             point_active           = zcl_apg_factory=>activation_status-custom_toggle
                             point_activation_class = point_toggle ) ) ) ).

    " ACT
    DATA(handlers) = resolve( ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( handlers )
                                        msg = 'All gates of an active point must be resolved' ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = toggle->call_count
                                        msg = 'Point toggle must be evaluated exactly once' ).
  ENDMETHOD.

  METHOD given_point_tgl_off_then_empty.
    " ARRANGE
    inject_toggle( activation_class = point_toggle
                   active           = abap_false ).
    inject( VALUE #( ( gate( handler_class          = handler_class_1
                             point_active           = zcl_apg_factory=>activation_status-custom_toggle
                             point_activation_class = point_toggle ) ) ) ).

    " ACT
    DATA(handlers) = resolve( ).

    " ASSERT
    cl_abap_unit_assert=>assert_initial( act = handlers
                                         msg = 'Point toggle returning false must suppress all gates' ).
  ENDMETHOD.

  METHOD given_gate_tgl_on_then_runs.
    " ARRANGE
    inject_toggle( activation_class = gate_toggle
                   active           = abap_true ).
    inject( VALUE #( ( gate( handler_class         = handler_class_1
                             gate_active           = zcl_apg_factory=>activation_status-custom_toggle
                             gate_activation_class = gate_toggle ) ) ) ).

    " ACT
    DATA(handlers) = resolve( ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( exp = handler_1
                                        act = handlers[ 1 ]-handler
                                        msg = 'Gate toggle returning true must resolve the gate' ).
  ENDMETHOD.

  METHOD given_gate_tgl_off_then_skip.
    " ARRANGE - toggled-off gate followed by a plain active gate
    inject_toggle( activation_class = gate_toggle
                   active           = abap_false ).
    inject( VALUE #( ( gate( handler_class         = handler_class_1
                             gate_active           = zcl_apg_factory=>activation_status-custom_toggle
                             gate_activation_class = gate_toggle ) )
                     ( gate( handler_class_2 ) ) ) ).

    " ACT
    DATA(handlers) = resolve( ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( handlers )
                                        msg = 'Gate toggle returning false must skip only that gate' ).
    cl_abap_unit_assert=>assert_equals( exp = handler_2
                                        act = handlers[ 1 ]-handler
                                        msg = 'The remaining active gate must still be resolved' ).
  ENDMETHOD.

  METHOD given_params_then_delivered.
    " ARRANGE
    inject( VALUE #( ( gate( handler_class = handler_class_1
                             param_1       = 'ALPHA'
                             param_2       = 'BETA' ) ) ) ).

    " ACT
    DATA(handlers) = resolve( ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( exp = 'ALPHA'
                                        act = handlers[ 1 ]-parameters-param_1
                                        msg = 'Param 1 must reach the resolved handler entry' ).
    cl_abap_unit_assert=>assert_equals( exp = 'BETA'
                                        act = handlers[ 1 ]-parameters-param_2
                                        msg = 'Param 2 must reach the resolved handler entry' ).
  ENDMETHOD.

  METHOD given_toggle_err_then_008.
    " ARRANGE
    zcl_apg_injector=>inject_instance( classname = failing_toggle
                                       instance  = NEW ltd_failing_toggle( ) ).
    inject( VALUE #( ( gate( handler_class          = handler_class_1
                             point_active           = zcl_apg_factory=>activation_status-custom_toggle
                             point_activation_class = failing_toggle ) ) ) ).

    TRY.
        " ACT
        resolve( ).
        cl_abap_unit_assert=>fail( 'Failing toggle must raise zcx_apg_error' ).
      CATCH zcx_apg_error INTO DATA(error).
        " ASSERT
        cl_abap_unit_assert=>assert_equals( exp = zcx_apg_error=>toggle_evaluation_failed
                                            act = error->if_t100_message~t100key
                                            msg = 'Failing toggle must surface textid toggle_evaluation_failed' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_empty_inject_then_none.
    " ARRANGE
    inject( VALUE #( ) ).

    " ACT
    DATA(handlers) = resolve( ).

    " ASSERT
    cl_abap_unit_assert=>assert_initial( act = handlers
                                         msg = 'Injected empty configuration must yield no handlers' ).
  ENDMETHOD.
ENDCLASS.


"! Database read path of the factory: SQL filters, primary-key order, column
"! mapping and the injection-wins rule. Needs CL_OSQL_TEST_ENVIRONMENT, so it
"! runs in ADT only - every method is listed in options.skip off-stack.
CLASS ltc_factory_db DEFINITION
  INHERITING FROM lth_factory FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    CLASS-DATA osql_environment TYPE REF TO if_osql_test_environment.

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
                param_1          TYPE zapg_parameter        OPTIONAL
                param_2          TYPE zapg_parameter        OPTIONAL.

    METHODS given_db_cfg_then_seq_order   FOR TESTING RAISING zcx_apg_error.
    METHODS given_db_gate_off_then_skip   FOR TESTING RAISING zcx_apg_error.
    METHODS given_db_point_off_then_empty FOR TESTING RAISING zcx_apg_error.
    METHODS given_db_params_then_mapped   FOR TESTING RAISING zcx_apg_error.
    METHODS given_db_point_tgl_then_used  FOR TESTING RAISING zcx_apg_error.
    METHODS given_db_gate_tgl_then_used   FOR TESTING RAISING zcx_apg_error.
    METHODS given_injection_then_no_db    FOR TESTING RAISING zcx_apg_error.
ENDCLASS.


CLASS ltc_factory_db IMPLEMENTATION.
  METHOD class_teardown.
    IF osql_environment IS BOUND.
      osql_environment->destroy( ).
    ENDIF.
  ENDMETHOD.

  METHOD setup.
    " Created on first use rather than in class_setup: the off-stack runner
    " calls class_setup even when every method of the class is skipped
    IF osql_environment IS NOT BOUND.
      osql_environment = cl_osql_test_environment=>create( VALUE #( ( 'ZAPG_POINT' ) ( 'ZAPG_GATE_HANDLE' ) ) ).
    ENDIF.
    osql_environment->clear_doubles( ).
    arrange_fixture( ).
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
    insert_point( zcl_apg_factory=>activation_status-active ).
    insert_gate( seqno         = '002'
                 handler_class = handler_class_2
                 active        = zcl_apg_factory=>activation_status-active ).
    insert_gate( seqno         = '001'
                 handler_class = handler_class_1
                 active        = zcl_apg_factory=>activation_status-active ).

    " ACT
    DATA(handlers) = resolve( ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( handlers )
                                        msg = 'Both active gates must be read' ).
    cl_abap_unit_assert=>assert_equals( exp = handler_1
                                        act = handlers[ 1 ]-handler
                                        msg = 'Gates must be read in seqno order' ).
  ENDMETHOD.

  METHOD given_db_gate_off_then_skip.
    " ARRANGE
    insert_point( zcl_apg_factory=>activation_status-active ).
    insert_gate( seqno         = '001'
                 handler_class = handler_class_1
                 active        = zcl_apg_factory=>activation_status-inactive ).
    insert_gate( seqno         = '002'
                 handler_class = handler_class_2
                 active        = zcl_apg_factory=>activation_status-active ).

    " ACT
    DATA(handlers) = resolve( ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( handlers )
                                        msg = 'Inactive gate must be filtered by the read' ).
    cl_abap_unit_assert=>assert_equals( exp = handler_2
                                        act = handlers[ 1 ]-handler
                                        msg = 'Only the active gate must be read' ).
  ENDMETHOD.

  METHOD given_db_point_off_then_empty.
    " ARRANGE
    insert_point( zcl_apg_factory=>activation_status-inactive ).
    insert_gate( seqno         = '001'
                 handler_class = handler_class_1
                 active        = zcl_apg_factory=>activation_status-active ).

    " ACT
    DATA(handlers) = resolve( ).

    " ASSERT
    cl_abap_unit_assert=>assert_initial( act = handlers
                                         msg = 'Inactive point must be filtered by the read' ).
  ENDMETHOD.

  METHOD given_db_params_then_mapped.
    " ARRANGE
    insert_point( zcl_apg_factory=>activation_status-active ).
    insert_gate( seqno         = '001'
                 handler_class = handler_class_1
                 active        = zcl_apg_factory=>activation_status-active
                 param_1       = 'ALPHA'
                 param_2       = 'BETA' ).

    " ACT
    DATA(handlers) = resolve( ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( exp = 'ALPHA'
                                        act = handlers[ 1 ]-parameters-param_1
                                        msg = 'PARAM_1 must be read from ZAPG_GATE_HANDLE' ).
    cl_abap_unit_assert=>assert_equals( exp = 'BETA'
                                        act = handlers[ 1 ]-parameters-param_2
                                        msg = 'PARAM_2 must be read from ZAPG_GATE_HANDLE' ).
  ENDMETHOD.

  METHOD given_db_point_tgl_then_used.
    " ARRANGE
    DATA(toggle) = inject_toggle( activation_class = point_toggle
                                  active           = abap_true ).
    insert_point( active           = zcl_apg_factory=>activation_status-custom_toggle
                  activation_class = point_toggle ).
    insert_gate( seqno         = '001'
                 handler_class = handler_class_1
                 active        = zcl_apg_factory=>activation_status-active ).

    " ACT
    DATA(handlers) = resolve( ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( handlers )
                                        msg = 'Custom-toggled point must be read' ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = toggle->call_count
                                        msg = 'Point activation class must be read from ZAPG_POINT' ).
  ENDMETHOD.

  METHOD given_db_gate_tgl_then_used.
    " ARRANGE
    DATA(toggle) = inject_toggle( activation_class = gate_toggle
                                  active           = abap_false ).
    insert_point( zcl_apg_factory=>activation_status-active ).
    insert_gate( seqno            = '001'
                 handler_class    = handler_class_1
                 active           = zcl_apg_factory=>activation_status-custom_toggle
                 activation_class = gate_toggle ).

    " ACT
    DATA(handlers) = resolve( ).

    " ASSERT
    cl_abap_unit_assert=>assert_initial( act = handlers
                                         msg = 'Gate toggle returning false must skip the gate' ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = toggle->call_count
                                        msg = 'Gate activation class must be read from ZAPG_GATE_HANDLE' ).
  ENDMETHOD.

  METHOD given_injection_then_no_db.
    " ARRANGE - database holds an active gate, the test injects "no gates"
    insert_point( zcl_apg_factory=>activation_status-active ).
    insert_gate( seqno         = '001'
                 handler_class = handler_class_1
                 active        = zcl_apg_factory=>activation_status-active ).
    zcl_apg_injector=>inject_configurations( point_id       = point_id
                                             configurations = VALUE #( ) ).

    " ACT
    DATA(handlers) = resolve( ).

    " ASSERT
    cl_abap_unit_assert=>assert_initial( act = handlers
                                         msg = 'An injected empty configuration must win over the database' ).
  ENDMETHOD.
ENDCLASS.
