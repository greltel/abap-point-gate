"! <p class="shorttext synchronized" lang="EN">ABAP Point Gate authorization</p>
"! Adapter around authorization object ZAPG_POINT and the single place in
"! the framework that issues AUTHORITY-CHECK. Consumers depend on
"! {@link zif_apg_authorization} so they stay testable.
CLASS zcl_apg_authorization DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_apg_authorization.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_APG_AUTHORIZATION IMPLEMENTATION.


  METHOD zif_apg_authorization~is_allowed.
*    AUTHORITY-CHECK OBJECT 'ZAPG_POINT'
*      ID 'ZAPG_PID' DUMMY
*      ID 'ACTVT'    FIELD activity.
*    result = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.


  METHOD zif_apg_authorization~is_allowed_for_point.
*    AUTHORITY-CHECK OBJECT 'ZAPG_POINT'
*      ID 'ZAPG_PID' FIELD point_id
*      ID 'ACTVT'    FIELD activity.
*    result = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.
ENDCLASS.
