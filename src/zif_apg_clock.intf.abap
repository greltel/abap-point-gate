"! <p class="shorttext synchronized" lang="EN">ABAP Point Gate clock</p>
"! System clock adapter. The implementing class is the only place in the
"! framework that reads the system date, so every consumer can be tested
"! against a fixed date instead of the real clock.
INTERFACE zif_apg_clock
  PUBLIC.

  "! Returns the current system date.
  "! @parameter result | System date in ABAP date format
  METHODS today
    RETURNING VALUE(result) TYPE d.

ENDINTERFACE.
