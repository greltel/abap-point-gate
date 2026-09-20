*"* use this source file for your ABAP unit test classes
CLASS ltd_domain_values DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_apg_domain_values.

    METHODS constructor
      IMPORTING values TYPE zif_apg_domain_values=>tt_values.

    DATA requested_element TYPE string READ-ONLY.

  PRIVATE SECTION.
    DATA values TYPE zif_apg_domain_values=>tt_values.
ENDCLASS.

CLASS ltd_domain_values IMPLEMENTATION.
  METHOD constructor.
    me->values = values.
  ENDMETHOD.

  METHOD zif_apg_domain_values~read.
    requested_element = data_element.
    result            = values.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_active_vh DEFINITION
  FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA double TYPE REF TO ltd_domain_values.
    DATA cut    TYPE REF TO zcl_apg_active_vh.

    METHODS given_values
      IMPORTING values TYPE zif_apg_domain_values=>tt_values.

    METHODS given_values_then_mapped  FOR TESTING.
    METHODS given_values_then_ordered FOR TESTING.
    METHODS given_none_then_empty     FOR TESTING.
    METHODS when_read_then_right_elem FOR TESTING.
ENDCLASS.

CLASS zcl_apg_active_vh DEFINITION LOCAL FRIENDS ltc_active_vh.

CLASS ltc_active_vh IMPLEMENTATION.

  METHOD given_values.
    double = NEW ltd_domain_values( values ).
    cut    = NEW zcl_apg_active_vh( double ).
  ENDMETHOD.

  METHOD given_values_then_mapped.
    " ARRANGE
    given_values( VALUE #( ( code = 'X' description = 'First' )
                           ( code = 'C' description = 'Second' ) ) ).

    " ACT
    DATA(values) = cut->read_values( ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = lines( values )
                                        exp = 2
                                        msg = `Every fixed value must become one value-help row` ).
    cl_abap_unit_assert=>assert_equals( act = values[ 1 ]-activationstatus
                                        exp = 'X'
                                        msg = `The fixed value code must reach the key field` ).
    cl_abap_unit_assert=>assert_equals( act = values[ 1 ]-description
                                        exp = 'First'
                                        msg = `The fixed value text must reach the description` ).
  ENDMETHOD.

  METHOD given_values_then_ordered.
    " ARRANGE - the dictionary order is the order the value help must show
    given_values( VALUE #( ( code = 'C' description = 'Second' )
                           ( code = 'X' description = 'First' ) ) ).

    " ACT
    DATA(values) = cut->read_values( ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = values[ 1 ]-activationstatus
                                        exp = 'C'
                                        msg = `The dictionary order must be preserved` ).
  ENDMETHOD.

  METHOD given_none_then_empty.
    " ARRANGE
    given_values( VALUE #( ) ).

    " ACT & ASSERT
    cl_abap_unit_assert=>assert_initial( act = cut->read_values( )
                                         msg = `No fixed values must yield no rows` ).
  ENDMETHOD.

  METHOD when_read_then_right_elem.
    " ARRANGE
    given_values( VALUE #( ) ).

    " ACT
    cut->read_values( ).

    " ASSERT
    cl_abap_unit_assert=>assert_equals( act = double->requested_element
                                        exp = `ZAPG_ACTIVE`
                                        msg = `The query must read the fixed values of ZAPG_ACTIVE` ).
  ENDMETHOD.

ENDCLASS.
