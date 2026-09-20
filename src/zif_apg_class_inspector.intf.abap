"! <p class="shorttext synchronized" lang="EN">ABAP Point Gate class inspector</p>
"! Answers what a class name refers to. The implementing class owns the
"! runtime type information, so the validations that check handler and
"! toggle classes can be tested without real repository objects.
INTERFACE zif_apg_class_inspector
  PUBLIC.

  "! Interfaces a configured class has to implement
  CONSTANTS:
    BEGIN OF interface,
      handler TYPE abap_classname VALUE 'ZIF_APG_HANDLER',
      toggle  TYPE abap_classname VALUE 'ZIF_APG_ACTIVATION_TOGGLE',
    END OF interface.

  "! Returns abap_true when the name refers to an existing global class.
  "! An interface or an unknown name yields abap_false.
  "! @parameter classname | Name to look up
  "! @parameter result    | abap_true when the name is a class
  METHODS is_class
    IMPORTING classname     TYPE clike
    RETURNING VALUE(result) TYPE abap_bool.

  "! Returns abap_true when the class implements the given interface.
  "! A class that does not exist yields abap_false.
  "! @parameter classname | Name of the class
  "! @parameter interface | Interface the class is expected to implement
  "! @parameter result    | abap_true when the class implements the interface
  METHODS implements
    IMPORTING classname     TYPE clike
              interface     TYPE abap_classname
    RETURNING VALUE(result) TYPE abap_bool.

ENDINTERFACE.
