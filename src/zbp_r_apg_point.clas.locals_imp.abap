"! Read-only inspector for global class metadata used by the validations.
CLASS lcl_class_inspector DEFINITION FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CONSTANTS handler_interface TYPE abap_classname VALUE 'ZIF_APG_HANDLER'.
    CONSTANTS toggle_interface  TYPE abap_classname VALUE 'ZIF_APG_ACTIVATION_TOGGLE'.

    "! Returns abap_true if the name refers to an existing global class.
    CLASS-METHODS is_class
      IMPORTING classname     TYPE clike
      RETURNING VALUE(result) TYPE abap_bool.

    "! Returns abap_true if the class implements the given interface.
    CLASS-METHODS implements
      IMPORTING classname     TYPE clike
                interface     TYPE abap_classname
      RETURNING VALUE(result) TYPE abap_bool.
ENDCLASS.


CLASS lcl_class_inspector IMPLEMENTATION.

  METHOD is_class.
    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = classname
                                         RECEIVING  p_descr_ref    = DATA(descriptor)
                                         EXCEPTIONS type_not_found = 1
                                                    OTHERS         = 2 ).
    " Fail closed: any lookup problem counts as "class does not exist"
    result = xsdbool( sy-subrc = 0 AND descriptor->kind = cl_abap_typedescr=>kind_class ).
  ENDMETHOD.

  METHOD implements.
    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = classname
                                         RECEIVING  p_descr_ref    = DATA(descriptor)
                                         EXCEPTIONS type_not_found = 1
                                                    OTHERS         = 2 ).
    IF sy-subrc <> 0 OR descriptor->kind <> cl_abap_typedescr=>kind_class.
      RETURN. " fail closed
    ENDIF.

    DATA(class_descriptor) = CAST cl_abap_classdescr( descriptor ).
    result = xsdbool( line_exists( class_descriptor->interfaces[ name = interface ] ) ).
  ENDMETHOD.

ENDCLASS.


"! Shared rule set for the Active / ActivationClass field pair.
CLASS lcl_activation_check DEFINITION FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    TYPES tt_findings TYPE STANDARD TABLE OF symsg WITH EMPTY KEY.

    "! Returns the findings for the given field pair (empty = valid).
    CLASS-METHODS check
      IMPORTING active           TYPE zapg_active
                activation_class TYPE zapg_activation_class
      RETURNING VALUE(result)    TYPE tt_findings.

  PRIVATE SECTION.
    CONSTANTS message_class TYPE symsgid VALUE 'ZAPG'.
ENDCLASS.


CLASS lcl_activation_check IMPLEMENTATION.

  METHOD check.
    IF active <> zcl_apg_factory=>activation_status-custom_toggle.
      IF activation_class IS NOT INITIAL.
        result = VALUE #( ( msgid = message_class
                            msgno = '007'
                            msgv1 = activation_class ) ).
      ENDIF.
      RETURN.
    ENDIF.

    IF activation_class IS INITIAL.
      result = VALUE #( ( msgid = message_class
                          msgno = '006' ) ).
      RETURN.
    ENDIF.

    IF lcl_class_inspector=>is_class( activation_class ) = abap_false.
      result = VALUE #( ( msgid = message_class
                          msgno = '001'
                          msgv1 = activation_class ) ).
      RETURN.
    ENDIF.

    IF lcl_class_inspector=>implements( classname = activation_class
                                        interface = lcl_class_inspector=>toggle_interface ) = abap_false.
      result = VALUE #( ( msgid = message_class
                          msgno = '002'
                          msgv1 = activation_class
                          msgv2 = lcl_class_inspector=>toggle_interface ) ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lhc_gate DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    CONSTANTS message_class TYPE symsgid VALUE 'ZAPG'.

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

    LOOP AT gates INTO DATA(gate).
      IF gate-handlerclass IS INITIAL.
        INSERT VALUE #( %tky = gate-%tky ) INTO TABLE failed-gate.
        INSERT VALUE #( %tky                  = gate-%tky
                        %msg                  = new_message( id       = message_class
                                                             number   = '009'
                                                             severity = if_abap_behv_message=>severity-error )
                        %element-handlerclass = if_abap_behv=>mk-on ) INTO TABLE reported-gate.
        CONTINUE.
      ENDIF.

      IF lcl_class_inspector=>is_class( gate-handlerclass ) = abap_false.
        INSERT VALUE #( %tky = gate-%tky ) INTO TABLE failed-gate.
        INSERT VALUE #( %tky                  = gate-%tky
                        %msg                  = new_message( id       = message_class
                                                             number   = '001'
                                                             severity = if_abap_behv_message=>severity-error
                                                             v1       = gate-handlerclass )
                        %element-handlerclass = if_abap_behv=>mk-on ) INTO TABLE reported-gate.
        CONTINUE.
      ENDIF.

      IF lcl_class_inspector=>implements( classname = gate-handlerclass
                                          interface = lcl_class_inspector=>handler_interface ) = abap_false.
        INSERT VALUE #( %tky = gate-%tky ) INTO TABLE failed-gate.
        INSERT VALUE #( %tky                  = gate-%tky
                        %msg                  = new_message( id       = message_class
                                                             number   = '002'
                                                             severity = if_abap_behv_message=>severity-error
                                                             v1       = gate-handlerclass
                                                             v2       = lcl_class_inspector=>handler_interface )
                        %element-handlerclass = if_abap_behv=>mk-on ) INTO TABLE reported-gate.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateactivationclass.
    READ ENTITIES OF zr_apg_point IN LOCAL MODE
         ENTITY gate
         FIELDS ( active activationclass )
         WITH CORRESPONDING #( keys )
         RESULT DATA(gates).

    LOOP AT gates INTO DATA(gate).
      DATA(findings) = lcl_activation_check=>check( active           = gate-active
                                                    activation_class = gate-activationclass ).

      LOOP AT findings INTO DATA(finding).
        INSERT VALUE #( %tky = gate-%tky ) INTO TABLE failed-gate.
        INSERT VALUE #( %tky                     = gate-%tky
                        %msg                     = new_message( id       = finding-msgid
                                                                number   = finding-msgno
                                                                severity = if_abap_behv_message=>severity-error
                                                                v1       = finding-msgv1
                                                                v2       = finding-msgv2 )
                        %element-activationclass = if_abap_behv=>mk-on ) INTO TABLE reported-gate.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


CLASS lhc_point DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR point RESULT result.

    METHODS validateactivationclass FOR VALIDATE ON SAVE
      IMPORTING keys FOR point~validateactivationclass.
ENDCLASS.


CLASS lhc_point IMPLEMENTATION.

  METHOD get_global_authorizations.
    " Intentionally open: the framework configuration app has no own
    " authorization object yet. A dedicated object + DCL is a roadmap item.
  ENDMETHOD.

  METHOD validateactivationclass.
    READ ENTITIES OF zr_apg_point IN LOCAL MODE
         ENTITY point
         FIELDS ( active activationclass )
         WITH CORRESPONDING #( keys )
         RESULT DATA(points).

    LOOP AT points INTO DATA(point).
      DATA(findings) = lcl_activation_check=>check( active           = point-active
                                                    activation_class = point-activationclass ).

      LOOP AT findings INTO DATA(finding).
        INSERT VALUE #( %tky = point-%tky ) INTO TABLE failed-point.
        INSERT VALUE #( %tky                     = point-%tky
                        %msg                     = new_message( id       = finding-msgid
                                                                number   = finding-msgno
                                                                severity = if_abap_behv_message=>severity-error
                                                                v1       = finding-msgv1
                                                                v2       = finding-msgv2 )
                        %element-activationclass = if_abap_behv=>mk-on ) INTO TABLE reported-point.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
