"! Shared rule set for the Active / ActivationClass field pair.
CLASS lcl_activation_check DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.

    TYPES: BEGIN OF ty_finding,
             "! One rule violation, named by the message it maps to
             textid     LIKE if_t100_message=>t100key,
             class_name TYPE string,
           END OF ty_finding.
    TYPES tt_findings TYPE STANDARD TABLE OF ty_finding WITH EMPTY KEY.

    "! @parameter class_inspector | Resolves whether the activation class is usable
    METHODS constructor
      IMPORTING class_inspector TYPE REF TO zif_apg_class_inspector.

    "! Returns the findings for the given field pair (empty = valid).
    "!
    "! @parameter active |
    "! @parameter activation_class |
    "! @parameter result |
    METHODS check
      IMPORTING active           TYPE zapg_active
                activation_class TYPE zapg_activation_class
      RETURNING VALUE(result)    TYPE tt_findings.

  PRIVATE SECTION.
    DATA class_inspector TYPE REF TO zif_apg_class_inspector.
ENDCLASS.


CLASS lcl_activation_check IMPLEMENTATION.
  METHOD constructor.
    me->class_inspector = class_inspector.
  ENDMETHOD.

  METHOD check.
    IF active <> zcl_apg_factory=>activation_status-custom_toggle.
      IF activation_class IS NOT INITIAL.
        result = VALUE #( ( textid     = zcm_apg_point=>activation_class_not_allowed
                            class_name = |{ activation_class }| ) ).
      ENDIF.
      RETURN.
    ENDIF.

    IF activation_class IS INITIAL.
      result = VALUE #( ( textid = zcm_apg_point=>activation_class_required ) ).
      RETURN.
    ENDIF.

    IF class_inspector->is_class( activation_class ) = abap_false.
      result = VALUE #( ( textid     = zcm_apg_point=>class_not_found
                          class_name = |{ activation_class }| ) ).
      RETURN.
    ENDIF.

    IF class_inspector->implements( classname = activation_class
                                    interface = zif_apg_class_inspector=>interface-toggle ) = abap_false.
      result = VALUE #( ( textid     = zcm_apg_point=>interface_not_implemented
                          class_name = |{ activation_class }| ) ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_point_factory DEFINITION FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    "! Returns the authorization adapter, or the injected double.
    "!
    "! @parameter result |
    CLASS-METHODS authorization
      RETURNING VALUE(result) TYPE REF TO zif_apg_authorization.

    "! Returns the class inspector, or the injected double.
    "!
    "! @parameter result |
    CLASS-METHODS class_inspector
      RETURNING VALUE(result) TYPE REF TO zif_apg_class_inspector.

    "! Test hook - pass an unbound reference to restore the production default.
    "!
    "! @parameter authorization |
    CLASS-METHODS inject_authorization
      IMPORTING !authorization TYPE REF TO zif_apg_authorization.

    "! Test hook - pass an unbound reference to restore the production default.
    "!
    "! @parameter class_inspector |
    CLASS-METHODS inject_class_inspector
      IMPORTING class_inspector TYPE REF TO zif_apg_class_inspector.

  PRIVATE SECTION.
    CLASS-DATA authorization_override   TYPE REF TO zif_apg_authorization.
    CLASS-DATA class_inspector_override TYPE REF TO zif_apg_class_inspector.
ENDCLASS.


CLASS lcl_point_factory IMPLEMENTATION.
  METHOD authorization.
    result = COND #( WHEN authorization_override IS BOUND
                     THEN authorization_override
                     ELSE NEW zcl_apg_authorization( ) ).
  ENDMETHOD.

  METHOD class_inspector.
    result = COND #( WHEN class_inspector_override IS BOUND
                     THEN class_inspector_override
                     ELSE NEW zcl_apg_class_inspector( ) ).
  ENDMETHOD.

  METHOD inject_authorization.
    authorization_override = authorization.
  ENDMETHOD.

  METHOD inject_class_inspector.
    class_inspector_override = class_inspector.
  ENDMETHOD.
ENDCLASS.

CLASS ltc_gate_validations DEFINITION DEFERRED FOR TESTING.

CLASS lhc_gate DEFINITION
  INHERITING FROM cl_abap_behavior_handler
  FRIENDS ltc_gate_validations.

  PRIVATE SECTION.
    CONSTANTS state_area_handler    TYPE string VALUE 'VALIDATE_HANDLER_CLASS'.
    CONSTANTS state_area_activation TYPE string VALUE 'VALIDATE_ACTIVATION_CLASS'.

    METHODS validatehandlerclass FOR VALIDATE ON SAVE
      IMPORTING keys FOR gate~validatehandlerclass.

    METHODS validateactivationclass FOR VALIDATE ON SAVE
      IMPORTING keys FOR gate~validateactivationclass.
ENDCLASS.


CLASS lhc_gate IMPLEMENTATION.
    METHOD validatehandlerclass.
    READ ENTITIES OF zr_apg_point IN LOCAL MODE
         ENTITY gate
         FIELDS ( handlerclass )
         WITH CORRESPONDING #( keys )
         RESULT DATA(gates).

    DATA(class_inspector) = lcl_point_factory=>class_inspector( ).

    LOOP AT gates INTO DATA(gate).
      " Draft: drop the previous state message before re-reporting, otherwise a
      " field the user has just corrected keeps its old error on the UI
      INSERT VALUE #( %tky        = gate-%tky
                      %state_area = state_area_handler ) INTO TABLE reported-gate.

      DATA(finding) = VALUE lcl_activation_check=>ty_finding( ).

      IF gate-handlerclass IS INITIAL.
        finding-textid = zcm_apg_point=>handler_class_required.
      ELSEIF class_inspector->is_class( gate-handlerclass ) = abap_false.
        finding = VALUE #( textid     = zcm_apg_point=>class_not_found
                           class_name = |{ gate-handlerclass }| ).
      ELSEIF class_inspector->implements( classname = gate-handlerclass
                                          interface = zif_apg_class_inspector=>interface-handler ) = abap_false.
        finding = VALUE #( textid     = zcm_apg_point=>interface_not_implemented
                           class_name = |{ gate-handlerclass }| ).
      ELSE.
        CONTINUE.
      ENDIF.

      INSERT VALUE #( %tky = gate-%tky ) INTO TABLE failed-gate.
      INSERT VALUE #( %tky                  = gate-%tky
                      %state_area           = state_area_handler
                      %msg                  = NEW zcm_apg_point(
                          severity       = if_abap_behv_message=>severity-error
                          textid         = finding-textid
                          class_name     = finding-class_name
                          interface_name = |{ zif_apg_class_inspector=>interface-handler }| )
                      %element-handlerclass = if_abap_behv=>mk-on ) INTO TABLE reported-gate.
    ENDLOOP.
  ENDMETHOD.

    METHOD validateactivationclass.
    READ ENTITIES OF zr_apg_point IN LOCAL MODE
         ENTITY gate
         FIELDS ( active activationclass )
         WITH CORRESPONDING #( keys )
         RESULT DATA(gates).

    DATA(activation_check) = NEW lcl_activation_check( lcl_point_factory=>class_inspector( ) ).
    DATA(toggle_interface) = |{ zif_apg_class_inspector=>interface-toggle }|.

    LOOP AT gates INTO DATA(gate).
      " Draft: drop the previous state message before re-reporting
      INSERT VALUE #( %tky        = gate-%tky
                      %state_area = state_area_activation ) INTO TABLE reported-gate.

      DATA(findings) = activation_check->check( active           = gate-active
                                                activation_class = gate-activationclass ).

      LOOP AT findings INTO DATA(finding).
        INSERT VALUE #( %tky = gate-%tky ) INTO TABLE failed-gate.
        INSERT VALUE #( %tky                     = gate-%tky
                        %state_area              = state_area_activation
                        %msg                     = NEW zcm_apg_point(
                                                           severity       = if_abap_behv_message=>severity-error
                                                           textid         = finding-textid
                                                           class_name     = finding-class_name
                                                           interface_name = toggle_interface )
                        %element-activationclass = if_abap_behv=>mk-on ) INTO TABLE reported-gate.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


CLASS lhc_point DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    CONSTANTS state_area_activation TYPE string VALUE 'VALIDATE_ACTIVATION_CLASS'.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR point RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR point RESULT result.

    METHODS validateactivationclass FOR VALIDATE ON SAVE
      IMPORTING keys FOR point~validateactivationclass.
ENDCLASS.


CLASS lhc_point IMPLEMENTATION.
  METHOD get_global_authorizations.
    DATA(authorization) = lcl_point_factory=>authorization( ).

    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = COND #(
          WHEN authorization->is_allowed( zif_apg_authorization=>activity-create ) = abap_true
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

    IF requested_authorizations-%update = if_abap_behv=>mk-on.
      result-%update = COND #(
          WHEN authorization->is_allowed( zif_apg_authorization=>activity-change ) = abap_true
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

    IF requested_authorizations-%delete = if_abap_behv=>mk-on.
      result-%delete = COND #(
          WHEN authorization->is_allowed( zif_apg_authorization=>activity-delete ) = abap_true
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_authorizations.
    READ ENTITIES OF zr_apg_point IN LOCAL MODE
         ENTITY point
         FIELDS ( pointid )
         WITH CORRESPONDING #( keys )
         RESULT DATA(points).

    DATA(authorization) = lcl_point_factory=>authorization( ).

    LOOP AT points INTO DATA(point).
      DATA(may_change) = authorization->is_allowed_for_point( activity = zif_apg_authorization=>activity-change
                                                              point_id = point-pointid ).
      DATA(may_delete) = authorization->is_allowed_for_point( activity = zif_apg_authorization=>activity-delete
                                                              point_id = point-pointid ).

      INSERT VALUE #( %tky    = point-%tky
                      %update = COND #( WHEN may_change = abap_true
                                        THEN if_abap_behv=>auth-allowed
                                        ELSE if_abap_behv=>auth-unauthorized )
                      %delete = COND #( WHEN may_delete = abap_true
                                        THEN if_abap_behv=>auth-allowed
                                        ELSE if_abap_behv=>auth-unauthorized ) )
             INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateactivationclass.
    READ ENTITIES OF zr_apg_point IN LOCAL MODE
         ENTITY point
         FIELDS ( active activationclass )
         WITH CORRESPONDING #( keys )
         RESULT DATA(points).

    DATA(activation_check) = NEW lcl_activation_check( lcl_point_factory=>class_inspector( ) ).
    DATA(toggle_interface) = |{ zif_apg_class_inspector=>interface-toggle }|.

    LOOP AT points INTO DATA(point).
      " Draft: drop the previous state message before re-reporting, otherwise a
      " field the user has just corrected keeps its old error on the UI
      INSERT VALUE #( %tky        = point-%tky
                      %state_area = state_area_activation ) INTO TABLE reported-point.

      DATA(findings) = activation_check->check( active           = point-active
                                                activation_class = point-activationclass ).

      LOOP AT findings INTO DATA(finding).
        INSERT VALUE #( %tky = point-%tky ) INTO TABLE failed-point.
        INSERT VALUE #( %tky                     = point-%tky
                        %state_area              = state_area_activation
                        %msg                     = NEW zcm_apg_point(
                                                           severity       = if_abap_behv_message=>severity-error
                                                           textid         = finding-textid
                                                           class_name     = finding-class_name
                                                           interface_name = toggle_interface )
                        %element-activationclass = if_abap_behv=>mk-on ) INTO TABLE reported-point.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
