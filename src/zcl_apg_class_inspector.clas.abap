"! <p class="shorttext synchronized" lang="EN">ABAP Point Gate class inspector</p>
"! Production implementation of {@link zif_apg_class_inspector} and the only
"! place in the framework that inspects the repository at runtime.
CLASS zcl_apg_class_inspector DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_apg_class_inspector.

  PROTECTED SECTION.
  PRIVATE SECTION.
    "! Returns the class descriptor, or an unbound reference when the name
    "! is unknown or does not refer to a class.
    METHODS describe_class
      IMPORTING classname     TYPE clike
      RETURNING VALUE(result) TYPE REF TO cl_abap_classdescr.
ENDCLASS.


CLASS zcl_apg_class_inspector IMPLEMENTATION.

  METHOD zif_apg_class_inspector~is_class.
    result = xsdbool( describe_class( classname ) IS BOUND ).
  ENDMETHOD.

  METHOD zif_apg_class_inspector~implements.
    DATA(class_descriptor) = describe_class( classname ).
    IF class_descriptor IS NOT BOUND.
      RETURN.
    ENDIF.

    result = xsdbool( line_exists( class_descriptor->interfaces[ name = interface ] ) ).
  ENDMETHOD.

  METHOD describe_class.
    cl_abap_typedescr=>describe_by_name(
          EXPORTING
            p_name         = classname
          RECEIVING
            p_descr_ref    = DATA(descriptor)
          EXCEPTIONS
            type_not_found = 1
            OTHERS         = 2 ).
    " Fail closed: any lookup problem counts as -class does not exist-
    IF sy-subrc <> 0 OR descriptor->kind <> cl_abap_typedescr=>kind_class.
      RETURN.
    ENDIF.

    result = CAST cl_abap_classdescr( descriptor ).
  ENDMETHOD.

ENDCLASS.
