"! <p class="shorttext synchronized" lang="EN">ABAP Point Gate toggle sample</p>
"! Sample activation toggle: active only when the journal entry posting
"! date differs from the current system date.
CLASS zcl_apg_act_toggle_sample DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_apg_activation_toggle.

    "! Creates the toggle with the clock it compares the posting date against.
    "! @parameter clock | Injected in tests; the production default is the system clock
    METHODS constructor
      IMPORTING clock TYPE REF TO zif_apg_clock OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS context_name_journal_entry TYPE string VALUE `JOURNAL_ENTRY`.
    DATA clock TYPE REF TO zif_apg_clock.
ENDCLASS.


CLASS zcl_apg_act_toggle_sample IMPLEMENTATION.

  METHOD constructor.
    me->clock = COND #( WHEN clock IS BOUND
                        THEN clock
                        ELSE NEW zcl_apg_system_clock( ) ).
  ENDMETHOD.

  METHOD zif_apg_activation_toggle~is_active.
    TRY.
        DATA(journal_entry_ref) = CAST i_journalentry( context->get_data( context_name_journal_entry ) ).
      CATCH cx_sy_move_cast_error INTO DATA(conversion_error).
        RAISE EXCEPTION NEW zcx_apg_error( textid       = zcx_apg_error=>context_conversion_failed
                                           context_name = context_name_journal_entry
                                           previous     = conversion_error ).
    ENDTRY.

    IF journal_entry_ref IS NOT BOUND.
      RAISE EXCEPTION NEW zcx_apg_error( textid       = zcx_apg_error=>context_value_missing
                                         context_name = context_name_journal_entry ).
    ENDIF.

    DATA(journal_entry) = journal_entry_ref->*.
    result = xsdbool( journal_entry-postingdate <> clock->today( ) ).
  ENDMETHOD.

ENDCLASS.
