"! <p class="shorttext synchronized" lang="EN">ABAP Point Gate handler sample</p>
"! Sample handler: validates and defaults the posting date of a journal
"! entry passed through the context.
CLASS zcl_apg_sample_execution DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_apg_handler.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS context_name_journal_entry TYPE string VALUE `JOURNAL_ENTRY`.
ENDCLASS.


CLASS zcl_apg_sample_execution IMPLEMENTATION.

  METHOD zif_apg_handler~execute.
    DATA journal_entry TYPE i_journalentry.

    DATA(journal_entry_ref) = context->get_data( context_name_journal_entry ).
    TRY.
        journal_entry = journal_entry_ref->*.
      CATCH cx_sy_ref_is_initial cx_sy_move_cast_error INTO DATA(conversion_error).
        RAISE EXCEPTION NEW zcx_apg_error( textid       = zcx_apg_error=>context_conversion_failed
                                           context_name = context_name_journal_entry
                                           previous     = conversion_error ).
    ENDTRY.

    IF journal_entry-postingdate IS NOT INITIAL.
      MESSAGE e010(zapg) INTO DATA(message_text).
      INSERT VALUE #( id      = sy-msgid
                      type    = sy-msgty
                      number  = sy-msgno
                      message = message_text ) INTO TABLE messages.
      RETURN.
    ENDIF.

    journal_entry-postingdate = cl_abap_context_info=>get_system_date( ).
    journal_entry_ref->* = journal_entry.
    context->set_data( name  = context_name_journal_entry
                       value = journal_entry_ref ).
  ENDMETHOD.

ENDCLASS.
