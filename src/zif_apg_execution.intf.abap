"! <p class="shorttext synchronized" lang="EN">ABAP Point Gate execution</p>
"! Entry point of the framework. Consumers depend on this interface so the
"! whole gate execution can be replaced by a double in their own tests.
INTERFACE zif_apg_execution
  PUBLIC.

  TYPES tt_messages TYPE zif_apg_handler=>tt_messages.

  "! Executes all active handlers of the point in sequence order.
  "! A failing handler is turned into an error message; only configuration
  "! problems reach the caller as an exception.
  "! @parameter point_id | Point to execute
  "! @parameter context  | Shared execution context
  "! @parameter messages | Message container filled by the handlers
  "! @raising zcx_apg_error | Configuration or instantiation error
  METHODS execute_gate
    IMPORTING point_id TYPE zapg_point_id
              context  TYPE REF TO zif_apg_context
    CHANGING  messages TYPE tt_messages
    RAISING   zcx_apg_error.

ENDINTERFACE.
