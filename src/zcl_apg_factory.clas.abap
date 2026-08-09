"! <p class="shorttext synchronized" lang="EN">ABAP Point Gate factory</p>
"! Resolves the active handler instances of a point by evaluating the
"! hierarchical activation model (point level first, then gate level).
CLASS zcl_apg_factory DEFINITION
  PUBLIC
  FINAL
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
    "! @parameter point_id | Point to resolve
    "! @parameter context  | Shared execution context (passed to toggles)
    "! @parameter result   | Active handler instances in execution order
    "! @raising zcx_apg_error | Toggle evaluation or instantiation failed
    CLASS-METHODS get_active_handlers_for_gate
      IMPORTING point_id      TYPE zapg_point_id
                context       TYPE REF TO zif_apg_context
      RETURNING VALUE(result) TYPE tt_active_handlers
      RAISING   zcx_apg_error.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-METHODS read_configurations
      IMPORTING point_id      TYPE zapg_point_id
      RETURNING VALUE(result) TYPE zcl_apg_injector=>tt_configurations.

    CLASS-METHODS is_point_active
      IMPORTING configuration TYPE zcl_apg_injector=>ty_configuration
                context       TYPE REF TO zif_apg_context
      RETURNING VALUE(result) TYPE abap_bool
      RAISING   zcx_apg_error.

    CLASS-METHODS is_gate_active
      IMPORTING configuration TYPE zcl_apg_injector=>ty_configuration
                context       TYPE REF TO zif_apg_context
      RETURNING VALUE(result) TYPE abap_bool
      RAISING   zcx_apg_error.

    CLASS-METHODS is_toggle_active
      IMPORTING activation_class TYPE zapg_activation_class
                context          TYPE REF TO zif_apg_context
      RETURNING VALUE(result)    TYPE abap_bool
      RAISING   zcx_apg_error.
ENDCLASS.


CLASS zcl_apg_factory IMPLEMENTATION.

  METHOD get_active_handlers_for_gate.
    DATA(configurations) = zcl_apg_injector=>get_configurations( point_id ).

    IF configurations IS INITIAL.
      configurations = read_configurations( point_id ).
    ENDIF.

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
    SELECT FROM zapg_gate_handle AS gate
           INNER JOIN zapg_point AS point ON point~point_id = gate~point_id
      FIELDS point~point_id,
             point~active           AS point_active,
             point~activation_class AS point_activation_class,
             gate~seqno,
             gate~handler_class,
             gate~active            AS gate_active,
             gate~activation_class  AS gate_activation_class,
             gate~param_1,
             gate~param_2
      WHERE gate~point_id  = @point_id
        AND point~active  IN ( @activation_status-active, @activation_status-custom_toggle )
        AND gate~active   IN ( @activation_status-active, @activation_status-custom_toggle )
      ORDER BY gate~seqno ASCENDING
      INTO TABLE @result.
  ENDMETHOD.

  METHOD is_point_active.
    result = SWITCH #( configuration-point_active
               WHEN activation_status-active
                 THEN abap_true
               WHEN activation_status-custom_toggle
                 THEN is_toggle_active( activation_class = configuration-point_activation_class
                                        context          = context )
               ELSE abap_false ).
  ENDMETHOD.

  METHOD is_gate_active.
    result = SWITCH #( configuration-gate_active
               WHEN activation_status-active
                 THEN abap_true
               WHEN activation_status-custom_toggle
                 THEN is_toggle_active( activation_class = configuration-gate_activation_class
                                        context          = context )
               ELSE abap_false ).
  ENDMETHOD.

  METHOD is_toggle_active.
    DATA(toggle) = zcl_apg_injector=>get_toggle( activation_class ).

    TRY.
        result = toggle->is_active( context ).
      CATCH cx_root INTO DATA(evaluation_error). " boundary wrap: name the failing activation class
        RAISE EXCEPTION NEW zcx_apg_error( textid     = zcx_apg_error=>toggle_evaluation_failed
                                           class_name = |{ activation_class }|
                                           previous   = evaluation_error ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
