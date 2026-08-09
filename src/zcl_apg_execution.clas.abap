"! <p class="shorttext synchronized" lang="EN">ABAP Point Gate execution</p>
"! Facade of the framework: executes all active handlers of a point.
"! A failing handler is converted into an error message so that the
"! remaining handlers and the host process are never aborted.
CLASS zcl_apg_execution DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES tt_messages TYPE zif_apg_handler=>tt_messages.

    "! Executes all active handlers of the point in sequence order.
    "! @parameter point_id | Point to execute
    "! @parameter context  | Shared execution context
    "! @parameter messages | Message container filled by the handlers
    "! @raising zcx_apg_error | Configuration or instantiation error
    CLASS-METHODS execute_gate
      IMPORTING point_id TYPE zapg_point_id
                context  TYPE REF TO zif_apg_context
      CHANGING  messages TYPE tt_messages
      RAISING   zcx_apg_error.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS message_type_error TYPE bapiret2-type VALUE 'E'.

    CLASS-METHODS as_error_message
      IMPORTING error         TYPE REF TO cx_root
      RETURNING VALUE(result) TYPE bapiret2.
ENDCLASS.


CLASS zcl_apg_execution IMPLEMENTATION.

  METHOD execute_gate.
    DATA(handlers) = zcl_apg_factory=>get_active_handlers_for_gate( point_id = point_id
                                                                    context  = context ).

    LOOP AT handlers INTO DATA(active_handler).
      TRY.
          active_handler-handler->execute( EXPORTING context    = context
                                                     parameters = active_handler-parameters
                                           CHANGING  messages   = messages ).
        " intentional: a broken handler must not abort the host transaction
        CATCH cx_root INTO DATA(error).
          INSERT as_error_message( error ) INTO TABLE messages.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD as_error_message.
    result = VALUE #( type    = message_type_error
                      message = error->get_text( ) ).
  ENDMETHOD.

ENDCLASS.
