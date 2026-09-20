# ABAP Point Gate
# ✅ Status: Production Ready (v3.0.0)
> **Open Source Contribution:** This project is community-driven and **Open Source**! 🚀
> If you spot a bug or have an idea for a cool enhancement, your contributions are more than welcome. Feel free to open an **Issue** or submit a **Pull Request** — see [CONTRIBUTING.md](CONTRIBUTING.md).

[![abaplint](https://github.com/greltel/abap-point-gate/actions/workflows/abaplint.yml/badge.svg)](https://github.com/greltel/abap-point-gate/actions/workflows/abaplint.yml)
[![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)](https://github.com/greltel/abap-point-gate/releases)
[![ABAP Cloud](https://img.shields.io/badge/ABAP-Cloud%20Ready-green)](https://abaplint.app/stats/greltel/abap-point-gate/object_classifications)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/greltel/abap-point-gate/blob/main/LICENSE)
[![ABAP 7.58+](https://img.shields.io/badge/ABAP-7.58%2B-brightgreen)](https://abaplint.app/stats/greltel/abap-point-gate/statement_compatibility)
[![Code Statistics](https://img.shields.io/badge/CodeStatistics-abaplint-blue)](https://abaplint.app/stats/greltel/abap-point-gate)

# Table of contents
1. [ABAP Point Gate](#abap-point-gate)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [License](#license)
5. [Contributing](#contributing)
6. [Contributors-Developers](#contributors-developers)
7. [Motivation for Creating the Repository](#motivation-for-creating-the-repository)
8. [Key Technical Features](#key-technical-features)
9. [Maintaining the Configuration](#maintaining-the-configuration)
10. [Authorization](#authorization)
11. [Usage Examples](#usage-examples)
12. [Testing Your Handlers](#testing-your-handlers)
13. [Design Goals-Features](#design-goals-features)
14. [Changelog](#changelog)
15. [Roadmap](#roadmap)

# ABAP Point Gate

ABAP Point Gate is a configuration-driven framework designed to decouple custom enhancements from standard SAP objects, ensuring a clean and maintainable architecture. By leveraging Dependency Injection and Type-Safe Context management, it enables seamless unit testing and granular, hierarchical control over enhancement execution.

Define **Points** (hook locations in your code) and attach an ordered chain of **Gate Handlers** to each of them — activated, deactivated, sequenced, and parameterized through a Fiori app instead of code changes.

# Architecture

```
Consumer code                       ABAP Point Gate                    Configuration
─────────────                       ───────────────                    ─────────────
build ZCL_APG_CONTEXT   ──────▶   ZCL_APG_EXECUTION (facade)
                                        │
                                        ▼
                                  ZCL_APG_FACTORY          ◀────────  ZAPG_POINT
                                        │  evaluates activation        ZAPG_GATE_HANDLE
                                        │  (point level, then gate)    (maintained via
                                        ▼                               Fiori app)
                                  ZCL_APG_INJECTOR
                                        │  resolves instances
                                        ▼
                                  ZIF_APG_HANDLER chain
                                  executed in SEQNO order
```

1. The consumer fills a `ZCL_APG_CONTEXT` with named data references and calls `ZCL_APG_EXECUTION=>EXECUTE_GATE` for a point ID.
2. The factory reads the configuration, evaluates the **hierarchical activation model** (point first, then each gate) and resolves the handler instances.
3. The handlers run in sequence order. A failing handler is converted into an error message — it never aborts the host transaction or the remaining chain.

| Object | Role |
|---|---|
| `ZIF_APG_HANDLER` | Contract for a gate handler (Strategy) |
| `ZIF_APG_ACTIVATION_TOGGLE` | Contract for a custom activation decision |
| `ZIF_APG_CONTEXT` / `ZCL_APG_CONTEXT` | Named data-reference container shared along the chain |
| `ZIF_APG_EXECUTION` / `ZCL_APG_EXECUTION` | Facade — the only class consumers call |
| `ZCL_APG_FACTORY` | Resolves the active handlers of a point |
| `ZCL_APG_INJECTOR` | DI registry — dynamic instantiation and test-double injection |
| `ZIF_APG_CLOCK` / `ZCL_APG_SYSTEM_CLOCK` | System date behind an interface — no `SY-DATUM` anywhere |
| `ZIF_APG_CLASS_INSPECTOR` | RTTI lookups behind an interface, doubled in tests |
| `ZIF_APG_DOMAIN_VALUES` | Domain fixed values for the value-help custom entities |
| `ZIF_APG_AUTHORIZATION` / `ZCL_APG_AUTHORIZATION` | The framework's only `AUTHORITY-CHECK` (object `ZAPG_POINT`) |
| `ZCX_APG_ERROR` | T100 exception (message class `ZAPG`) |
| `ZCM_APG_POINT` | RAP message class of the configuration business object |
| `ZR_APG_Point` / `ZR_APG_GateHandle` + BDEF | RAP managed, draft-enabled configuration BO |
| `ZC_APG_*`, `ZUI_APG_POINT_V4` | Projection layer and OData V4 UI service |

# Prerequisites

* SAP S/4HANA 2023 FPS03 (ABAP 7.58) or higher, OR SAP BTP ABAP Environment.
* Set the abapGit repository's **ABAP Language Version** to *ABAP for Cloud Development*. The framework targets ABAP Cloud exclusively.
* The framework itself uses released APIs only. The two **sample classes** reference the released CDS view `I_JournalEntry`.
* [Statement Compatibility](https://abaplint.app/stats/greltel/abap-point-gate/statement_compatibility)

## License
This project is licensed under the [MIT License](https://github.com/greltel/abap-point-gate/blob/main/LICENSE).

## Contributing
Pull requests are welcome. The ABAP source here is serialized by abapGit, so development happens in your own system and not against these files — the workflow, the quality bar and the naming rules are described in [CONTRIBUTING.md](CONTRIBUTING.md).

## Contributors-Developers
The repository was created by [George Drakos](https://www.linkedin.com/in/george-drakos/).

## Motivation for Creating the Repository

ABAP Point Gate provides a standardized "gate" around ABAP exit points/enhancements, so custom logic stays isolated from the SAP core instead of being scattered across standard objects. This helps keep the system clean, maintainable, and upgrade-friendly, while offering a consistent way to implement enhancements that aligns with Clean Core / ABAP Cloud readiness practices and encourages quality through automated checks (e.g. abaplint) and unit testing.

## Key Technical Features

* **Hierarchical Activation:** Control execution at both Point and Gate levels.
* **Type-Safe Context:** Easily pass and retrieve data with built-in type-safe getters — missing or non-convertible values raise a typed `ZCX_APG_ERROR` instead of failing silently.
* **Handler Parameters:** Two configuration parameters per gate (`PARAM_1` / `PARAM_2`) are maintained in the Fiori app and delivered to every handler, enabling parameterized handler variants without new classes.
* **Dependency Injection:** Built-in support for mocking handlers, toggles and configurations for Unit Testing. Every dependency on the outside world — the system date, RTTI lookups, domain values, authority checks — sits behind an interface that tests can replace.
* **T100 Error Handling:** Every framework error carries a message from message class `ZAPG` with full diagnostics (failing class, context name, original exception in `previous`).
* **High Performance:** Uses Hashed Tables ($O(1)$ complexity) for context and configuration lookups; point-level custom toggles are evaluated exactly once per execution; the configuration read is table-buffer friendly.
* **Clean ABAP:** Modern syntax, ABAP Doc on every public declaration, robust exception handling.
* **RAP Maintenance App:** Managed, draft-enabled Fiori app with optimistic locking, authorization checks, side effects and full input validation.

### ⚙️ Hierarchical Activation Logic

ABAP Point Gate supports a sophisticated activation model (domain `ZAPG_ACTIVE`):

| Status | Meaning |
|---|---|
| `X` | Globally Active |
| `-` | Inactive |
| ` ` | Unknown — treated as inactive |
| `C` | Custom — a `ZIF_APG_ACTIVATION_TOGGLE` class decides at runtime |

* **Parent-Child Rule:** If the Point is inactive (or its custom toggle returns false), none of its assigned Gates will execute, regardless of their individual status.
* A point-level custom toggle is evaluated **exactly once** per execution, not once per gate.

# Maintaining the Configuration

The Fiori app (service binding `ZUI_APG_POINT_V4_O4`, OData V4) maintains points and their handler chains with draft handling and optimistic locking. The following rules are enforced on save, as state messages that stay visible while the draft is being edited:

* The handler class must exist and implement `ZIF_APG_HANDLER` (messages 001/002/009).
* An activation class is required when the status is *Custom* (006), forbidden otherwise (007), and must implement `ZIF_APG_ACTIVATION_TOGGLE` (001/002).
* All value helps for statuses, point types, programs, includes and classes are served from domain fixed values or released repository views, so every valid value is selectable with its proper text.

# Authorization

The configuration app is protected by authorization object **`ZAPG_POINT`**:

| Field | Meaning |
|---|---|
| `ZAPG_PID` | Point ID, or `*` for all points |
| `ACTVT` | `01` create, `02` change, `03` display, `06` delete |

Checks happen in three places and nowhere else:

* **Global authorization** — decides whether the user may create, change or delete at all.
* **Instance authorization** — decides it again per point, so a user can be restricted to a subset of point IDs.
* **DCL roles** `ZR_APG_POINT`, `ZC_APG_POINT` and `ZI_APG_VALUE_HELPS` — restrict what is readable.

`ZCL_APG_AUTHORIZATION` holds the framework's single `AUTHORITY-CHECK` statement. Everything above it is written against `ZIF_APG_AUTHORIZATION`, which is what makes the behavior handlers testable without a user master record.

Assign the authorization object to a role in PFCG before handing the app to end users. Without it, nobody can maintain the configuration.

# Usage Examples

### 1. Prepare the Context
Prepare the data environment before triggering a gate.

```abap
DATA(context) = NEW zcl_apg_context( ).
context->set_data( name  = `SALES_ORDER`
                   value = REF #( sales_order ) ).
context->set_data( name  = `POSTING_DATE`
                   value = NEW d( cl_abap_context_info=>get_system_date( ) ) ).
context->set_data( name  = `RETRY_COUNT`
                   value = NEW i( 3 ) ).
```

### 2. Execute the Gate
Trigger the execution logic. The framework automatically identifies and runs all active handlers.

```abap
DATA messages TYPE zcl_apg_execution=>tt_messages.

TRY.
    " The Point ID 'SAMPLE_SAVE_BEFORE' must be configured in table ZAPG_POINT
    zcl_apg_execution=>execute_gate( EXPORTING point_id = 'SAMPLE_SAVE_BEFORE'
                                               context  = context
                                     CHANGING  messages = messages ).
  CATCH zcx_apg_error INTO DATA(configuration_error).
    " Configuration problems (unknown class, broken toggle) - surface them
    " through the host's own error channel, e.g. reported/failed in RAP
    INSERT VALUE #( type    = 'E'
                    message = configuration_error->get_text( ) ) INTO TABLE messages.
ENDTRY.
```

Handler exceptions are converted into `E` messages by the framework; only configuration errors raise `ZCX_APG_ERROR` to the consumer.

The static call above stays supported. Where the consumer itself is unit tested, inject the facade instead:

```abap
DATA(execution) = CAST zif_apg_execution( NEW zcl_apg_execution( ) ).
```

### 3. Handle Results
Retrieve modified data or typed values without manual casting.

```abap
" A. Check for validation messages returned by handlers
IF line_exists( messages[ type = 'E' ] ).
  " Handle errors (e.g. abort save, show log)
ENDIF.

" B. Retrieve potentially modified data
" If a handler modified the data, the updated reference is available again
DATA(changed_order) = context->get_data( `SALES_ORDER` ).

DATA(posting_date) = context->get_date( `POSTING_DATE` ).
DATA(retry_count)  = context->get_integer( `RETRY_COUNT` ).
```

### 4. Implement a Handler

```abap
CLASS zcl_my_enrichment DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_apg_handler.
ENDCLASS.


CLASS zcl_my_enrichment IMPLEMENTATION.

  METHOD zif_apg_handler~execute.
    " Named data references shared along the handler chain
    DATA(order_ref) = context->get_data( `SALES_ORDER` ).

    " Gate configuration parameters (PARAM_1 / PARAM_2 from the Fiori app)
    IF parameters-param_1 = 'STRICT'.
      " variant-specific behavior without a new handler class
    ENDIF.

    " Findings go into the shared message container
    INSERT VALUE #( type    = 'W'
                    message = 'Order enriched with defaults' ) INTO TABLE messages.
  ENDMETHOD.

ENDCLASS.
```

### 5. Implement an Activation Toggle

```abap
CLASS zcl_weekday_toggle DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_apg_activation_toggle.

    "! @parameter clock | Injected by tests, defaults to the system clock
    METHODS constructor
      IMPORTING clock TYPE REF TO zif_apg_clock OPTIONAL.

  PRIVATE SECTION.
    "! 1 January 2024 was a Monday - the anchor of the weekday calculation
    CONSTANTS reference_monday TYPE d VALUE '20240101'.

    DATA clock TYPE REF TO zif_apg_clock.
ENDCLASS.


CLASS zcl_weekday_toggle IMPLEMENTATION.

  METHOD constructor.
    me->clock = COND #( WHEN clock IS BOUND
                        THEN clock
                        ELSE NEW zcl_apg_system_clock( ) ).
  ENDMETHOD.

  METHOD zif_apg_activation_toggle~is_active.
    " 0 = Monday. Counted from a known Monday, so no system field is read here
    DATA(weekday) = ( clock->today( ) - reference_monday ) MOD 7.
    result = xsdbool( weekday < 5 ).
  ENDMETHOD.

ENDCLASS.
```

Assign the class to a point or gate with activation status `C` in the Fiori app. Because the clock is injected, the toggle can be tested for every day of the week without waiting for one.

# Testing Your Handlers

`ZCL_APG_INJECTOR` doubles as the test seam — no database needed:

```abap
" Inject the configuration for a point
zcl_apg_injector=>inject_configurations(
    point_id       = 'SAMPLE_SAVE_BEFORE'
    configurations = VALUE #( ( point_id      = 'SAMPLE_SAVE_BEFORE'
                                point_active  = zcl_apg_factory=>activation_status-active
                                seqno         = '001'
                                handler_class = 'ZCL_MY_ENRICHMENT'
                                gate_active   = zcl_apg_factory=>activation_status-active ) ) ).

" Inject a test double for a class name
zcl_apg_injector=>inject_instance( classname = 'ZCL_MY_ENRICHMENT'
                                   instance  = my_test_double ).

" Always clean up in setup/teardown
zcl_apg_injector=>clear( ).
```

An injected configuration always wins, even when it is empty on purpose — a test asking for "no gates" never falls back to the database.

# Design Goals-Features

* Install via [abapGit](http://abapgit.org).
* ABAP Cloud / Clean Core compatibility. Passed SCI check variants S4HANA_READINESS_2023 and ABAP_CLOUD_READINESS; ATC variant `ABAP_CLOUD_DEVELOPMENT_DEFAULT` with zero priority-1/2 findings.
* **94 ABAP Unit tests** across 11 test includes: core classes, the factory database path via `CL_OSQL_TEST_ENVIRONMENT`, the value-help query classes, the toggle error paths, and the RAP validations via `CL_CDS_TEST_ENVIRONMENT`. The only untested objects are the two boundary adapters `ZCL_APG_AUTHORIZATION` and `ZCL_APG_SYSTEM_CLOCK`, which exist so that everything else can be doubled.
* [abaplint](https://github.com/apps/abaplint) runs in GitHub Actions on every push and pull request; the documented rule exceptions live in `abaplint.json`, each with a comment saying why it is there.
* ABAP Doc on every public declaration; all messages are T100-based (message class `ZAPG`, 000-011) — no hardcoded texts.

# Changelog

See [CHANGELOG.md](CHANGELOG.md) for the full history.

### [3.0.0] - 2026-09-20
Hardening release: authorization layer (authorization object, DCL roles, RAP global and instance authorization), every external dependency moved behind an injectable interface, `%state_area` draft messages, typed RAP messages, side effects, and 94 unit tests. Fixes a context bug that silently discarded all stored values. Contains one breaking change — see the changelog.

### [2.0.0] - 2026-08-09
Full production-hardening rewrite: ABAP Cloud readiness, T100-based error handling, handler parameters, hardened RAP layer (validations, optimistic locking, domain-based value helps), and complete unit-test coverage. Contains breaking API changes — see the changelog.

### [1.0.0] - 2026-01-04
Initial Release.

# Roadmap

* Integrated Logging & Monitoring System (`IF_BALI_LOG`) for suppressed handler errors.
* Parallel Processing for independent handlers.
* Unit tests for the RAP authorization handlers once the typed request declarations are verified on the target release.
* Additional typed context getters (`get_boolean`, structures, tables).
* Rename the service definition to `ZSD_APG_Point` with a new service binding (breaking change, next major version).
