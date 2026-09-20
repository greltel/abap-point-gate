"! <p class="shorttext synchronized" lang="EN">ABAP Point Gate domain values</p>
"! Production implementation of {@link zif_apg_domain_values}. The only place
"! in the framework that combines runtime type information with the user
"! language to read dictionary fixed values.
CLASS zcl_apg_domain_values DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_apg_domain_values.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS fallback_language TYPE spras VALUE 'E'.

    "! Returns the user language, or the fallback when it cannot be determined.
    METHODS user_language
      RETURNING VALUE(result) TYPE spras.
ENDCLASS.


CLASS zcl_apg_domain_values IMPLEMENTATION.

  METHOD zif_apg_domain_values~read.
    cl_abap_typedescr=>describe_by_name(
          EXPORTING
            p_name         = data_element
          RECEIVING
            p_descr_ref    = DATA(descriptor)
          EXCEPTIONS
            type_not_found = 1
            OTHERS         = 2 ).
    " Fail soft: an unknown or non-elementary name yields no values
    IF sy-subrc <> 0 OR descriptor->kind <> cl_abap_typedescr=>kind_elem.
      RETURN.
    ENDIF.

    DATA(element)  = CAST cl_abap_elemdescr( descriptor ).
    DATA(language) = user_language( ).

    DATA(fixed_values) = element->get_ddic_fixed_values( language ).
    IF fixed_values IS INITIAL AND language <> fallback_language.
      " Domain texts are maintained in English only - fall back
      fixed_values = element->get_ddic_fixed_values( fallback_language ).
    ENDIF.

    result = VALUE #( FOR fixed_value IN fixed_values
                      ( code        = fixed_value-low
                        description = fixed_value-ddtext ) ).
  ENDMETHOD.

  METHOD user_language.
    TRY.
        result = cl_abap_context_info=>get_user_language_abap_format( ).
      CATCH cx_abap_context_info_error.
        result = fallback_language.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
