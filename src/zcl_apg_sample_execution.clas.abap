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

    CONSTANTS:
      BEGIN OF msg_posting_date_filled,
        id     TYPE symsgid VALUE 'ZAPG',
        number TYPE symsgno VALUE '010',
        type   TYPE bapiret2-type VALUE 'E',
      END OF msg_posting_date_filled.

ENDCLASS.


CLASS zcl_apg_sample_execution IMPLEMENTATION.

METHOD zif_apg_handler~execute.
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

    IF journal_entry-postingdate IS NOT INITIAL.
      MESSAGE e010(zapg) INTO DATA(message_text).
      INSERT VALUE #( id      = msg_posting_date_filled-id
                      type    = msg_posting_date_filled-type
                      number  = msg_posting_date_filled-number
                      message = message_text ) INTO TABLE messages.
      RETURN.
    ENDIF.

    journal_entry-postingdate = cl_abap_context_info=>get_system_date( ).
    journal_entry_ref->* = journal_entry.
  ENDMETHOD.

ENDCLASS.
