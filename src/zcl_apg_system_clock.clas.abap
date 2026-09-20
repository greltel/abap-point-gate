"! <p class="shorttext synchronized" lang="EN">ABAP Point Gate system clock</p>
"! Production implementation of {@link zif_apg_clock} and the single place
"! in the framework that calls the released context-info API for the date.
CLASS zcl_apg_system_clock DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_apg_clock.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_apg_system_clock IMPLEMENTATION.

  METHOD zif_apg_clock~today.
    result = cl_abap_context_info=>get_system_date( ).
  ENDMETHOD.

ENDCLASS.
