"! <p class="shorttext synchronized" lang="EN">ABAP Point Gate error</p>
"! Central exception of the ABAP Point Gate framework. Every error raised
"! by the framework carries a message from message class ZAPG, selected
"! via one of the textid constants, together with the relevant attributes.
CLASS zcx_apg_error DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
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

    "! Instantiation of class &1 failed
    CONSTANTS:
      BEGIN OF instantiation_failed,
        msgid TYPE symsgid VALUE 'ZAPG',
        msgno TYPE symsgno VALUE '003',
        attr1 TYPE scx_attrname VALUE 'CLASS_NAME',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF instantiation_failed.

    "! No value found in context for name &1
    CONSTANTS:
      BEGIN OF context_value_missing,
        msgid TYPE symsgid VALUE 'ZAPG',
        msgno TYPE symsgno VALUE '004',
        attr1 TYPE scx_attrname VALUE 'CONTEXT_NAME',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF context_value_missing.

    "! Context value &1 cannot be converted to the requested type
    CONSTANTS:
      BEGIN OF context_conversion_failed,
        msgid TYPE symsgid VALUE 'ZAPG',
        msgno TYPE symsgno VALUE '005',
        attr1 TYPE scx_attrname VALUE 'CONTEXT_NAME',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF context_conversion_failed.

    "! Evaluation of activation class &1 failed
    CONSTANTS:
      BEGIN OF toggle_evaluation_failed,
        msgid TYPE symsgid VALUE 'ZAPG',
        msgno TYPE symsgno VALUE '008',
        attr1 TYPE scx_attrname VALUE 'CLASS_NAME',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF toggle_evaluation_failed.

    "! Name of the class involved in the error
    DATA class_name     TYPE string READ-ONLY.
    "! Name of the interface the class is expected to implement
    DATA interface_name TYPE string READ-ONLY.
    "! Name of the context entry involved in the error
    DATA context_name   TYPE string READ-ONLY.

    "! Creates the exception with an optional T100 key and attributes.
    "! @parameter textid         | T100 key (one of the textid constants)
    "! @parameter previous       | Original exception being wrapped
    "! @parameter class_name     | Class name for message placeholder
    "! @parameter interface_name | Interface name for message placeholder
    "! @parameter context_name   | Context entry name for message placeholder
    METHODS constructor
      IMPORTING
        textid         LIKE if_t100_message=>t100key OPTIONAL
        previous       LIKE previous OPTIONAL
        class_name     TYPE string OPTIONAL
        interface_name TYPE string OPTIONAL
        context_name   TYPE string OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcx_apg_error IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).

    me->class_name     = class_name.
    me->interface_name = interface_name.
    me->context_name   = context_name.

    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
