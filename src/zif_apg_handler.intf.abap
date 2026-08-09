"! <p class="shorttext synchronized" lang="EN">ABAP Point Gate handler</p>
"! Contract for a gate handler executed by the framework.
INTERFACE zif_apg_handler
  PUBLIC.

  TYPES tt_messages TYPE STANDARD TABLE OF bapiret2 WITH EMPTY KEY.

  TYPES: BEGIN OF ty_parameters,
           param_1 TYPE zapg_parameter,
           param_2 TYPE zapg_parameter,
         END OF ty_parameters.

  "! Executes the handler logic for the given context.
  "! @parameter context    | Shared execution context
  "! @parameter parameters | Gate parameters from the configuration
  "! @parameter messages   | Message container filled by the handler
  "! @raising zcx_apg_error | Handler-specific processing error
  METHODS execute
    IMPORTING context    TYPE REF TO zif_apg_context
              parameters TYPE ty_parameters OPTIONAL
    CHANGING  messages   TYPE tt_messages
    RAISING   zcx_apg_error.

ENDINTERFACE.
