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


CLASS ltc_act_toggle_sample DEFINITION
  FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    CONSTANTS today      TYPE d VALUE '20260301'.
    CONSTANTS other_day  TYPE d VALUE '20260228'.
    CONSTANTS entry_name TYPE string VALUE `JOURNAL_ENTRY`.

    DATA context TYPE REF TO zif_apg_context.

    METHODS setup.
    METHODS given_entry
      IMPORTING posting_date TYPE d.

    METHODS given_other_date_then_active FOR TESTING RAISING zcx_apg_error.
    METHODS given_today_then_inactive    FOR TESTING RAISING zcx_apg_error.
    METHODS given_no_entry_then_raises   FOR TESTING.
ENDCLASS.


CLASS ltc_act_toggle_sample IMPLEMENTATION.

  METHOD setup.
    context = NEW zcl_apg_context( ).
  ENDMETHOD.

  METHOD given_entry.
    DATA(journal_entry) = NEW i_journalentry( ).

    journal_entry->postingdate = posting_date.
    context->set_data( name  = entry_name
                       value = journal_entry ).
  ENDMETHOD.

  METHOD given_other_date_then_active.
    " ARRANGE
    given_entry( other_day ).
    DATA(cut) = NEW zcl_apg_act_toggle_sample( NEW ltd_fixed_clock( today ) ).

    " ACT & ASSERT
    cl_abap_unit_assert=>assert_true(
        act = cut->zif_apg_activation_toggle~is_active( context )
        msg = `A posting date other than today must activate the toggle` ).
  ENDMETHOD.

  METHOD given_today_then_inactive.
    " ARRANGE
    given_entry( today ).
    DATA(cut) = NEW zcl_apg_act_toggle_sample( NEW ltd_fixed_clock( today ) ).

    " ACT & ASSERT
    cl_abap_unit_assert=>assert_false(
        act = cut->zif_apg_activation_toggle~is_active( context )
        msg = `A posting date equal to today must not activate the toggle` ).
  ENDMETHOD.

  METHOD given_no_entry_then_raises.
    " ARRANGE - context left empty
    DATA(cut) = NEW zcl_apg_act_toggle_sample( NEW ltd_fixed_clock( today ) ).

    TRY.
        " ACT
        cut->zif_apg_activation_toggle~is_active( context ).
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
