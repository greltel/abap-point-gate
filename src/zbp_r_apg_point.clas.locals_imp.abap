"! Shared rule set for the Active / ActivationClass field pair.
CLASS lcl_activation_check DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    "! One rule violation, named by the message it maps to
    TYPES: BEGIN OF ty_finding,
             textid     LIKE if_t100_message=>t100key,
             class_name TYPE string,
           END OF ty_finding.
    TYPES tt_findings TYPE STANDARD TABLE OF ty_finding WITH EMPTY KEY.

    "! @parameter class_inspector | Resolves whether the activation class is usable
    METHODS constructor
      IMPORTING class_inspector TYPE REF TO zif_apg_class_inspector.

    "! Returns the findings for the given field pair (empty = valid).
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
    CLASS-METHODS authorization
      RETURNING VALUE(result) TYPE REF TO zif_apg_authorization.

    "! Returns the class inspector, or the injected double.
    CLASS-METHODS class_inspector
      RETURNING VALUE(result) TYPE REF TO zif_apg_class_inspector.

    "! Test hook - pass an unbound reference to restore the production default.
    CLASS-METHODS inject_authorization
      IMPORTING authorization TYPE REF TO zif_apg_authorization.

    "! Test hook - pass an unbound reference to restore the production default.
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


CLASS lhc_gate DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
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

    DATA(activation_check)  = NEW lcl_activation_check( lcl_point_factory=>class_inspector( ) ).
    DATA(toggle_interface)  = |{ zif_apg_class_inspector=>interface-toggle }|.

    LOOP AT gates INTO DATA(gate).
      DATA(findings) = activation_check->check( active           = gate-active
                                                activation_class = gate-activationclass ).

      LOOP AT findings INTO DATA(finding).
        INSERT VALUE #( %tky = gate-%tky ) INTO TABLE failed-gate.
        INSERT VALUE #( %tky                     = gate-%tky
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
