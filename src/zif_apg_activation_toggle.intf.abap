"! <p class="shorttext synchronized" lang="EN">ABAP Point Gate activation toggle</p>
"! Contract for a custom activation decision (activation status 'C').
INTERFACE zif_apg_activation_toggle
  PUBLIC.

  "! Decides whether the point or gate is active for this execution.
  "! @parameter context | Shared execution context
  "! @parameter result  | abap_true if active
  "! @raising zcx_apg_error | Evaluation failed
  METHODS is_active
    IMPORTING context       TYPE REF TO zif_apg_context
    RETURNING VALUE(result) TYPE abap_bool
    RAISING   zcx_apg_error.

ENDINTERFACE.
