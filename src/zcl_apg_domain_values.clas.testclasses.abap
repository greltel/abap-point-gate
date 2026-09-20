*"* use this source file for your ABAP unit test classes
CLASS ltc_domain_values DEFINITION
  FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    CONSTANTS activation_status TYPE string VALUE `ZAPG_ACTIVE`.
    CONSTANTS point_type        TYPE string VALUE `ZAPG_POINT_TYPE`.

    DATA cut TYPE REF TO zif_apg_domain_values.

    METHODS setup.
    METHODS given_status_then_3_values  FOR TESTING.
    METHODS given_status_then_texts     FOR TESTING.
    METHODS given_point_type_then_10    FOR TESTING.
    METHODS given_unknown_then_empty    FOR TESTING.
    METHODS given_class_name_then_empty FOR TESTING.
ENDCLASS.


CLASS ltc_domain_values IMPLEMENTATION.

  METHOD setup.
    cut = NEW zcl_apg_domain_values( ).
  ENDMETHOD.

  METHOD given_status_then_3_values.
    " ACT & ASSERT - the domain carries exactly X, - and C
    cl_abap_unit_assert=>assert_equals( act = lines( cut->read( activation_status ) )
                                        exp = 3
                                        msg = `ZAPG_ACTIVE must expose exactly three fixed values` ).
  ENDMETHOD.

  METHOD given_status_then_texts.
    " ACT
    DATA(values) = cut->read( activation_status ).

    " ASSERT
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( values[ code = 'X' ] ) )
        msg = `The active code X must be among the fixed values` ).
    cl_abap_unit_assert=>assert_not_initial(
        act = values[ code = 'X' ]-description
        msg = `Every fixed value must carry a description` ).
  ENDMETHOD.

  METHOD given_point_type_then_10.
    " ACT & ASSERT
    cl_abap_unit_assert=>assert_equals( act = lines( cut->read( point_type ) )
                                        exp = 10
                                        msg = `ZAPG_POINT_TYPE must expose ten fixed values` ).
  ENDMETHOD.

  METHOD given_unknown_then_empty.
    " ACT & ASSERT - fail soft instead of dumping
    cl_abap_unit_assert=>assert_initial( act = cut->read( `ZAPG_DOES_NOT_EXIST` )
                                         msg = `An unknown data element must yield no values` ).
  ENDMETHOD.

  METHOD given_class_name_then_empty.
    " ACT & ASSERT - a class is not an elementary type
    cl_abap_unit_assert=>assert_initial( act = cut->read( `ZCL_APG_CONTEXT` )
                                         msg = `A non-elementary name must yield no values` ).
  ENDMETHOD.

ENDCLASS.
