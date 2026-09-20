"! <p class="shorttext synchronized">ABAP Point Gate injector</p>
"! Dependency injection registry of the framework. Resolves handler and
"! toggle instances (test double or dynamic creation) and stores injected
"! configurations. Static state is intentional: this is cross-cutting
"! DI infrastructure, not a business class.
CLASS zcl_apg_injector DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_configuration,
             point_id               TYPE zapg_point_id,
             point_active           TYPE zapg_active,
             point_activation_class TYPE zapg_activation_class,
             seqno                  TYPE zapg_seqno,
             handler_class          TYPE zapg_handler_class,
             gate_active            TYPE zapg_active,
             gate_activation_class  TYPE zapg_activation_class,
             param_1                TYPE zapg_parameter,
             param_2                TYPE zapg_parameter,
           END OF ty_configuration,
           tt_configurations TYPE STANDARD TABLE OF ty_configuration WITH EMPTY KEY.

    "! Returns abap_true when a configuration was injected for the point,
    "! including one that is intentionally empty.
    "! @parameter point_id | Point to look up
    "! @parameter result   | abap_true when an injected configuration exists
    CLASS-METHODS has_configurations
      IMPORTING point_id      TYPE zapg_point_id
      RETURNING VALUE(result) TYPE abap_bool.

    "! Returns a handler instance: an injected double or a new instance.
    "! @parameter classname     | Name of the handler class
    "! @parameter result        | Handler instance
    "! @raising   zcx_apg_error | Class not creatable or wrong interface
    CLASS-METHODS get_handler
      IMPORTING classname     TYPE abap_classname
      RETURNING VALUE(result) TYPE REF TO zif_apg_handler
      RAISING   zcx_apg_error.

    "! Returns a toggle instance: an injected double or a new instance.
    "! @parameter classname     | Name of the activation class
    "! @parameter result        | Toggle instance
    "! @raising   zcx_apg_error | Class not creatable or wrong interface
    CLASS-METHODS get_toggle
      IMPORTING classname     TYPE abap_classname
      RETURNING VALUE(result) TYPE REF TO zif_apg_activation_toggle
      RAISING   zcx_apg_error.

    "! Registers a test double under a class name.
    "! @parameter classname | Class name the double stands in for
    "! @parameter instance  | Test double instance
    CLASS-METHODS inject_instance
      IMPORTING classname TYPE abap_classname
                !instance TYPE REF TO object.

    "! Registers a mock configuration for a point.
    "! @parameter point_id       | Point the configuration belongs to
    "! @parameter configurations | Configuration rows for the point
    CLASS-METHODS inject_configurations
      IMPORTING point_id       TYPE zapg_point_id
                configurations TYPE tt_configurations.

    "! Returns the injected configuration of a point (empty if none).
    "! @parameter point_id | Point to look up
    "! @parameter result   | Injected configuration rows
    CLASS-METHODS get_configurations
      IMPORTING point_id      TYPE zapg_point_id
      RETURNING VALUE(result) TYPE tt_configurations.

    "! Registers a class inspector, replacing the repository inspector.
    "! @parameter class_inspector | Inspector to use; pass an unbound reference to restore the default
    CLASS-METHODS inject_class_inspector
      IMPORTING class_inspector TYPE REF TO zif_apg_class_inspector.

    "! Removes all injected doubles, configurations and inspectors.
    CLASS-METHODS clear.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_mock,
             classname TYPE abap_classname,
             instance  TYPE REF TO object,
           END OF ty_mock,
           ty_mocks TYPE HASHED TABLE OF ty_mock WITH UNIQUE KEY classname.

    TYPES: BEGIN OF ty_mock_configuration,
             point_id       TYPE zapg_point_id,
             configurations TYPE tt_configurations,
           END OF ty_mock_configuration,
           ty_mock_configurations TYPE HASHED TABLE OF ty_mock_configuration WITH UNIQUE KEY point_id.

    CLASS-DATA mocks                    TYPE ty_mocks.
    CLASS-DATA mock_configurations      TYPE ty_mock_configurations.
    CLASS-DATA class_inspector_override TYPE REF TO zif_apg_class_inspector.

    CLASS-METHODS class_inspector
      RETURNING VALUE(result) TYPE REF TO zif_apg_class_inspector.

    "! Raises the error that explains why the class cannot serve the interface.
    "!
    "! @parameter classname |
    "! @parameter interface |
    "! @raising zcx_apg_error |
    CLASS-METHODS check_usable
      IMPORTING classname  TYPE abap_classname
                !interface TYPE abap_classname
      RAISING   zcx_apg_error.

    CLASS-METHODS get_mock
      IMPORTING classname     TYPE abap_classname
      RETURNING VALUE(result) TYPE REF TO object.
ENDCLASS.


CLASS zcl_apg_injector IMPLEMENTATION.
  METHOD has_configurations.
    result = xsdbool( line_exists( mock_configurations[ point_id = point_id ] ) ).
  ENDMETHOD.

  METHOD get_handler.
    DATA(mock) = get_mock( classname ).
    IF mock IS BOUND.
      TRY.
          result = CAST #( mock ).
        CATCH cx_sy_move_cast_error INTO DATA(cast_error).
          RAISE EXCEPTION NEW zcx_apg_error( textid         = zcx_apg_error=>interface_not_implemented
                                             class_name     = |{ classname }|
                                             interface_name = |{ zif_apg_class_inspector=>interface-handler }|
                                             previous       = cast_error ).
      ENDTRY.
      RETURN.
    ENDIF.

    check_usable( classname = classname
                  interface = zif_apg_class_inspector=>interface-handler ).

    TRY.
        " Dynamic instantiation: NEW cannot take a runtime type name
        CREATE OBJECT result TYPE (classname).
      CATCH cx_sy_create_object_error INTO DATA(create_error).
        RAISE EXCEPTION NEW zcx_apg_error( textid     = zcx_apg_error=>instantiation_failed
                                           class_name = |{ classname }|
                                           previous   = create_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD get_toggle.
    DATA(mock) = get_mock( classname ).
    IF mock IS BOUND.
      TRY.
          result = CAST #( mock ).
        CATCH cx_sy_move_cast_error INTO DATA(cast_error).
          RAISE EXCEPTION NEW zcx_apg_error( textid         = zcx_apg_error=>interface_not_implemented
                                             class_name     = |{ classname }|
                                             interface_name = |{ zif_apg_class_inspector=>interface-toggle }|
                                             previous       = cast_error ).
      ENDTRY.
      RETURN.
    ENDIF.

    check_usable( classname = classname
                  interface = zif_apg_class_inspector=>interface-toggle ).

    TRY.
        " Dynamic instantiation: NEW cannot take a runtime type name
        CREATE OBJECT result TYPE (classname).
      CATCH cx_sy_create_object_error INTO DATA(create_error).
        RAISE EXCEPTION NEW zcx_apg_error( textid     = zcx_apg_error=>instantiation_failed
                                           class_name = |{ classname }|
                                           previous   = create_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD inject_instance.
    DELETE TABLE mocks WITH TABLE KEY classname = classname.
    INSERT VALUE #( classname = classname
                    instance  = instance ) INTO TABLE mocks.
  ENDMETHOD.

  METHOD inject_configurations.
    DELETE TABLE mock_configurations WITH TABLE KEY point_id = point_id.
    INSERT VALUE #( point_id       = point_id
                    configurations = configurations ) INTO TABLE mock_configurations.
  ENDMETHOD.

  METHOD get_configurations.
    result = VALUE #( mock_configurations[ point_id = point_id ]-configurations OPTIONAL ).
  ENDMETHOD.

  METHOD inject_class_inspector.
    class_inspector_override = class_inspector.
  ENDMETHOD.

  METHOD clear.
    CLEAR: mocks,
           mock_configurations,
           class_inspector_override.
  ENDMETHOD.

  METHOD class_inspector.
    result = COND #( WHEN class_inspector_override IS BOUND
                     THEN class_inspector_override
                     ELSE NEW zcl_apg_class_inspector( ) ).
  ENDMETHOD.

  METHOD check_usable.
    DATA(inspector) = class_inspector( ).

    IF inspector->is_class( classname ) = abap_false.
      RAISE EXCEPTION NEW zcx_apg_error( textid     = zcx_apg_error=>class_not_found
                                         class_name = |{ classname }| ).
    ENDIF.

    IF inspector->implements( classname = classname
                              interface = interface ) = abap_false.
      RAISE EXCEPTION NEW zcx_apg_error( textid         = zcx_apg_error=>interface_not_implemented
                                         class_name     = |{ classname }|
                                         interface_name = |{ interface }| ).
    ENDIF.
  ENDMETHOD.

  METHOD get_mock.
    result = VALUE #( mocks[ classname = classname ]-instance OPTIONAL ).
  ENDMETHOD.
ENDCLASS.
