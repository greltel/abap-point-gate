"! <p class="shorttext synchronized" lang="EN">ABAP Point Gate authorization</p>
"! Authority checks of the Point Gate configuration business object.
"! The implementing adapter owns the only AUTHORITY-CHECK statement of the
"! framework, so behavior handlers can be tested against a double.
INTERFACE zif_apg_authorization
  PUBLIC.

  "! Activity code of authorization object ZAPG_POINT (field ACTVT)
  TYPES ty_activity TYPE c LENGTH 2.

  "! Activities the configuration business object distinguishes
  CONSTANTS:
    BEGIN OF activity,
      create  TYPE ty_activity VALUE '01',
      change  TYPE ty_activity VALUE '02',
      display TYPE ty_activity VALUE '03',
      delete  TYPE ty_activity VALUE '06',
    END OF activity.

  "! Checks the activity without narrowing it to a single point.
  "! Used for the global authorization of the business object.
  "! @parameter activity | One of the activity constants
  "! @parameter result   | abap_true if the user may perform the activity
  METHODS is_allowed
    IMPORTING activity      TYPE ty_activity
    RETURNING VALUE(result) TYPE abap_bool.

  "! Checks the activity for one specific point.
  "! @parameter activity | One of the activity constants
  "! @parameter point_id | Point the activity refers to
  "! @parameter result   | abap_true if the user may perform the activity
  METHODS is_allowed_for_point
    IMPORTING activity      TYPE ty_activity
              point_id      TYPE zapg_point_id
    RETURNING VALUE(result) TYPE abap_bool.

ENDINTERFACE.
