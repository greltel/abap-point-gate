"! <p class="shorttext synchronized" lang="EN">ABAP Point Gate context</p>
"! Type-safe, name-based data container that carries data references
"! between the gate consumer and the handlers.
INTERFACE zif_apg_context
  PUBLIC.

  "! Stores a data reference under a name, replacing any existing value.
  "! @parameter name  | Name of the context entry
  "! @parameter value | Data reference to store
  METHODS set_data
    IMPORTING name  TYPE string
              value TYPE REF TO data.

  "! Returns the data reference stored under the given name.
  "! @parameter name   | Name of the context entry
  "! @parameter result | Stored data reference
  "! @raising zcx_apg_error | No value stored under the given name
  METHODS get_data
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE REF TO data
    RAISING   zcx_apg_error.

  "! Checks whether a value is stored under the given name.
  "! @parameter name   | Name of the context entry
  "! @parameter result | abap_true if a value exists
  METHODS has_data
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE abap_bool.

  "! Returns the stored value converted to a string.
  "! @parameter name   | Name of the context entry
  "! @parameter result | Stored value as string
  "! @raising zcx_apg_error | Value missing or not convertible
  METHODS get_string
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE string
    RAISING   zcx_apg_error.

  "! Returns the stored value converted to an integer.
  "! @parameter name   | Name of the context entry
  "! @parameter result | Stored value as integer
  "! @raising zcx_apg_error | Value missing or not convertible
  METHODS get_integer
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE i
    RAISING   zcx_apg_error.

  "! Returns the stored value converted to a date.
  "! @parameter name   | Name of the context entry
  "! @parameter result | Stored value as date
  "! @raising zcx_apg_error | Value missing or not convertible
  METHODS get_date
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE xsddate_d
    RAISING   zcx_apg_error.

ENDINTERFACE.
