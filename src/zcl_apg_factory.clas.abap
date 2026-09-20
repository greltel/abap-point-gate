"! <p class="shorttext synchronized">ABAP Point Gate factory</p>
"! Resolves the active handler instances of a point by evaluating the
"! hierarchical activation model (point level first, then gate level).
CLASS zcl_apg_factory DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CONSTANTS: BEGIN OF activation_status,
                 active        TYPE zapg_active VALUE 'X',
                 inactive      TYPE zapg_active VALUE '-',
                 custom_toggle TYPE zapg_active VALUE 'C',
               END OF activation_status.

    TYPES: BEGIN OF ty_active_handler,
             handler    TYPE REF TO zif_apg_handler,
             parameters TYPE zif_apg_handler=>ty_parameters,
           END OF ty_active_handler,
           tt_active_handlers TYPE STANDARD TABLE OF ty_active_handler WITH EMPTY KEY.

    "! Returns the handlers of all active gates of the point, in sequence
    "! order. Returns an empty table when the point itself is not active.
    "! @parameter point_id      | Point to resolve
    "! @parameter context       | Shared execution context (passed to toggles)
    "! @parameter result        | Active handler instances in execution order
    "! @raising   zcx_apg_error | Toggle evaluation or instantiation failed
    CLASS-METHODS get_active_handlers_for_gate
      IMPORTING point_id      TYPE zapg_point_id
                !context      TYPE REF TO zif_apg_context
      RETURNING VALUE(result) TYPE tt_active_handlers
      RAISING   zcx_apg_error.

  PRIVATE SECTION.
    CLASS-METHODS read_configurations
      IMPORTING point_id      TYPE zapg_point_id
      RETURNING VALUE(result) TYPE zcl_apg_injector=>tt_configurations.

    CLASS-METHODS is_point_active
      IMPORTING configuration TYPE zcl_apg_injector=>ty_configuration
                !context      TYPE REF TO zif_apg_context
      RETURNING VALUE(result) TYPE abap_bool
      RAISING   zcx_apg_error.

    CLASS-METHODS is_gate_active
      IMPORTING configuration TYPE zcl_apg_injector=>ty_configuration
                !context      TYPE REF TO zif_apg_context
      RETURNING VALUE(result) TYPE abap_bool
      RAISING   zcx_apg_error.

    CLASS-METHODS is_toggle_active
      IMPORTING activation_class TYPE zapg_activation_class
                !context         TYPE REF TO zif_apg_context
      RETURNING VALUE(result)    TYPE abap_bool
      RAISING   zcx_apg_error.
ENDCLASS.


CLASS zcl_apg_factory IMPLEMENTATION.
  METHOD get_active_handlers_for_gate.
    " An injected configuration wins even when it is empty on purpose -
    " otherwise a test asking for "no gates" silently reads the database
    DATA(configurations) = COND zcl_apg_injector=>tt_configurations(
        WHEN zcl_apg_injector=>has_configurations( point_id ) = abap_true
        THEN zcl_apg_injector=>get_configurations( point_id )
        ELSE read_configurations( point_id ) ).

    IF configurations IS INITIAL.
      RETURN.
    ENDIF.

    " Point-level activation is identical on every row - evaluate once
    IF is_point_active( configuration = configurations[ 1 ]
                        context       = context ) = abap_false.
      RETURN.
    ENDIF.

    LOOP AT configurations INTO DATA(configuration).
      IF is_gate_active( configuration = configuration
                         context       = context ) = abap_true.
        INSERT VALUE #( handler    = zcl_apg_injector=>get_handler( configuration-handler_class )
                        parameters = VALUE #( param_1 = configuration-param_1
                                              param_2 = configuration-param_2 ) ) INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_configurations.
    " Two single-table reads instead of a join: ABAP SQL always bypasses the
    " table buffer for joins, and both tables are fully buffered customizing.
    SELECT SINGLE FROM zapg_point
      FIELDS point_id,
             active,
             activation_class
      WHERE point_id  = @point_id
        AND active   IN ( @activation_status-active, @activation_status-custom_toggle )
      INTO @DATA(point).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " ORDER BY PRIMARY KEY keeps the buffer: point_id is fixed by WHERE, so
    " the remaining key component seqno drives the order. A plain
    " ORDER BY seqno would bypass the buffer.
    SELECT FROM zapg_gate_handle
      FIELDS point_id,
             seqno,
             handler_class,
             active,
             activation_class,
             param_1,
             param_2
      WHERE point_id  = @point_id
        AND active   IN ( @activation_status-active, @activation_status-custom_toggle )
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(gates).

    result = VALUE #( FOR gate IN gates
                      ( point_id               = point-point_id
                        point_active           = point-active
                        point_activation_class = point-activation_class
                        seqno                  = gate-seqno
                        handler_class          = gate-handler_class
                        gate_active            = gate-active
                        gate_activation_class  = gate-activation_class
                        param_1                = gate-param_1
                        param_2                = gate-param_2 ) ).
  ENDMETHOD.

  METHOD is_point_active.
    result = SWITCH #( configuration-point_active
                       WHEN activation_status-active THEN
                         abap_true
                       WHEN activation_status-custom_toggle THEN
                         is_toggle_active( activation_class = configuration-point_activation_class
                                           context          = context )
                       ELSE
                         abap_false ).
  ENDMETHOD.

  METHOD is_gate_active.
    result = SWITCH #( configuration-gate_active
                       WHEN activation_status-active THEN
                         abap_true
                       WHEN activation_status-custom_toggle THEN
                         is_toggle_active( activation_class = configuration-gate_activation_class
                                           context          = context )
                       ELSE
                         abap_false ).
  ENDMETHOD.

  METHOD is_toggle_active.
    DATA(toggle) = zcl_apg_injector=>get_toggle( activation_class ).

    TRY.
        result = toggle->is_active( context ).
        " boundary wrap: name the failing activation class
      CATCH cx_root INTO DATA(evaluation_error).
        RAISE EXCEPTION NEW zcx_apg_error( textid     = zcx_apg_error=>toggle_evaluation_failed
                                           class_name = |{ activation_class }|
                                           previous   = evaluation_error ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
