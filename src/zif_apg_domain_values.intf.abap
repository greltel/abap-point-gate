"! <p class="shorttext synchronized" lang="EN">ABAP Point Gate domain values</p>
"! Supplies the fixed values of a DDIC data element together with their
"! language-dependent texts. The implementing class owns the runtime type
"! information and the language handling, so value-help query classes can
"! be unit-tested against canned values instead of the dictionary.
INTERFACE zif_apg_domain_values
  PUBLIC.

  "! Fixed value code, sized like the dictionary fixed value itself
  TYPES ty_code TYPE c LENGTH 10.
  "! Language-dependent description of a fixed value
  TYPES ty_description TYPE c LENGTH 60.

  TYPES: BEGIN OF ty_value,
           code        TYPE ty_code,
           description TYPE ty_description,
         END OF ty_value.
  TYPES tt_values TYPE STANDARD TABLE OF ty_value WITH EMPTY KEY.

  "! Returns the fixed values of the given data element in the user language,
  "! falling back to English when the texts are maintained in English only.
  "! Returns an empty table when the name is unknown or not an elementary type.
  "! @parameter data_element | Name of the DDIC data element
  "! @parameter result       | Fixed values with their texts, in dictionary order
  METHODS read
    IMPORTING data_element  TYPE string
    RETURNING VALUE(result) TYPE tt_values.

ENDINTERFACE.
