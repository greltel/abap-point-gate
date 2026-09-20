*"* use this source file for your ABAP unit test classes
CLASS ltd_fixed_clock DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_apg_clock.

    METHODS constructor
      IMPORTING fixed_date TYPE d.

  PRIVATE SECTION.
    DATA fixed_date TYPE d.
ENDCLASS.

CLASS ltd_fixed_clock IMPLEMENTATION.
  METHOD constructor.
    me->fixed_date = fixed_date.
  ENDMETHOD.

  METHOD zif_apg_clock~today.
    result = fixed_date.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_sample_execution DEFINITION
  FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    CONSTANTS today      TYPE d VALUE '20260301'.
    CONSTANTS filled_day TYPE d VALUE '20260228'.
    CONSTANTS entry_name TYPE string VALUE `JOURNAL_ENTRY`.

    DATA context TYPE REF TO zif_apg_context.
    DATA cut     TYPE REF TO zif_apg_handler.

    METHODS setup.
    METHODS given_entry
      IMPORTING posting_date  TYPE d
      RETURNING VALUE(result) TYPE REF TO i_journalentry.

    METHODS given_initial_date_then_set FOR TESTING RAISING zcx_apg_error.
    METHODS given_filled_date_then_kept FOR TESTING RAISING zcx_apg_error.
    METHODS given_filled_date_then_msg  FOR TESTING RAISING zcx_apg_error.
    METHODS given_no_entry_then_raises  FOR TESTING.
ENDCLASS.


CLASS ltc_sample_execution IMPLEMENTATION.

  METHOD setup.
    context = NEW zcl_apg_context( ).
    cut     = NEW zcl_apg_sample_execution( NEW ltd_fixed_clock( today ) ).
  ENDMETHOD.

  METHOD given_entry.
    result = NEW i_journalentry( ).
    result->postingdate = posting_date.
    context->set_data( name  = entry_name
                       value = result ).
  ENDMETHOD.

  METHOD given_initial_date_then_set.
    " ARRANGE
    DATA(entry) = given_entry( VALUE #( ) ).
    DATA messages TYPE zif_apg_handler=>tt_messages.

    " ACT
    cut->execute( EXPORTING context  = context
                  CHANGING  messages = messages ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = entry->postingdate
                                        exp = today
                                        msg = `An initial posting date must be defaulted to today` ).
    cl_abap_unit_assert=>assert_initial( act = messages
                                         msg = `Defaulting the date must not report a message` ).
  ENDMETHOD.

  METHOD given_filled_date_then_kept.
    " ARRANGE
    DATA(entry) = given_entry( filled_day ).
    DATA messages TYPE zif_apg_handler=>tt_messages.

    " ACT
    cut->execute( EXPORTING context  = context
                  CHANGING  messages = messages ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = entry->postingdate
                                        exp = filled_day
                                        msg = `A posting date that is already filled must not be overwritten` ).
  ENDMETHOD.

  METHOD given_filled_date_then_msg.
    " ARRANGE
    given_entry( filled_day ).
    DATA messages TYPE zif_apg_handler=>tt_messages.

    " ACT
    cut->execute( EXPORTING context  = context
                  CHANGING  messages = messages ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = lines( messages )
                                        exp = 1
                                        msg = `A filled posting date must report exactly one message` ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-number
                                        exp = '010'
                                        msg = `The reported message must be ZAPG 010` ).
  ENDMETHOD.

  METHOD given_no_entry_then_raises.
    " ARRANGE - context left empty
    DATA messages TYPE zif_apg_handler=>tt_messages.

    TRY.
        " ACT
        cut->execute( EXPORTING context  = context
                      CHANGING  messages = messages ).
        cl_abap_unit_assert=>fail( `A missing journal entry must raise zcx_apg_error` ).
      CATCH zcx_apg_error INTO DATA(error).
        " ASSERT
        cl_abap_unit_assert=>assert_equals(
            act = error->if_t100_message~t100key
            exp = zcx_apg_error=>context_value_missing
            msg = `A missing journal entry must surface textid context_value_missing` ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
