"! <p class="shorttext synchronized" lang="EN">Point Gate BO messages</p>
"! RAP message class of the configuration business object. Every validation
"! message is selected through one of the textid constants, so handlers and
"! their tests refer to a name instead of a message number.
CLASS zcm_apg_point DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_abap_behv_message.
    INTERFACES if_t100_dyn_msg.
    INTERFACES if_t100_message.

    "! Class &1 does not exist
    CONSTANTS:
      BEGIN OF class_not_found,
        msgid TYPE symsgid VALUE 'ZAPG',
        msgno TYPE symsgno VALUE '001',
        attr1 TYPE scx_attrname VALUE 'CLASS_NAME',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF class_not_found.

    "! Class &1 does not implement interface &2
    CONSTANTS:
      BEGIN OF interface_not_implemented,
        msgid TYPE symsgid VALUE 'ZAPG',
        msgno TYPE symsgno VALUE '002',
        attr1 TYPE scx_attrname VALUE 'CLASS_NAME',
        attr2 TYPE scx_attrname VALUE 'INTERFACE_NAME',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF interface_not_implemented.

    "! Activation class is required when activation status is Custom
    CONSTANTS:
      BEGIN OF activation_class_required,
        msgid TYPE symsgid VALUE 'ZAPG',
        msgno TYPE symsgno VALUE '006',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF activation_class_required.

    "! Activation class &1 is only allowed with activation status Custom
    CONSTANTS:
      BEGIN OF activation_class_not_allowed,
        msgid TYPE symsgid VALUE 'ZAPG',
        msgno TYPE symsgno VALUE '007',
        attr1 TYPE scx_attrname VALUE 'CLASS_NAME',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF activation_class_not_allowed.

    "! Handler class is required
    CONSTANTS:
      BEGIN OF handler_class_required,
        msgid TYPE symsgid VALUE 'ZAPG',
        msgno TYPE symsgno VALUE '009',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF handler_class_required.

    "! Name of the class the message refers to
    DATA class_name     TYPE string READ-ONLY.
    "! Name of the interface the class is expected to implement
    DATA interface_name TYPE string READ-ONLY.

    "! Creates the message with a T100 key and the placeholder values.
    "! @parameter severity       | Severity reported to the consumer
    "! @parameter textid         | T100 key (one of the textid constants)
    "! @parameter previous       | Original exception being wrapped
    "! @parameter class_name     | Class name for message placeholder &1
    "! @parameter interface_name | Interface name for message placeholder &2
    METHODS constructor
      IMPORTING
        severity       TYPE if_abap_behv_message=>t_severity DEFAULT if_abap_behv_message=>severity-error
        textid         LIKE if_t100_message=>t100key OPTIONAL
        previous       LIKE previous OPTIONAL
        class_name     TYPE string OPTIONAL
        interface_name TYPE string OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcm_apg_point IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).

    me->class_name     = class_name.
    me->interface_name = interface_name.

    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.

    if_abap_behv_message~m_severity = severity.
  ENDMETHOD.

ENDCLASS.
