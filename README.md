# ABAP Point Gate
# ✅ Status: Initial Release (v1.0.0)
> **Open Source Contribution:** This project is community-driven and **Open Source**! 🚀  
> If you spot a bug or have an idea for a cool enhancement, your contributions are more than welcome. Feel free to open an **Issue** or submit a **Pull Request**.

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/greltel/ABAP-Point-Gate/releases)
[![ABAP Cloud](https://img.shields.io/badge/ABAP-Cloud%20Ready-green)](https://abaplint.app/stats/greltel/abap-point-gate/object_classifications)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/greltel/ABAP-Point-Gate/blob/main/LICENSE)
[![ABAP 7.00+](https://img.shields.io/badge/ABAP-7.54%2B-brightgreen)](https://abaplint.app/stats/greltel/abap-point-gate/statement_compatibility)
[![Code Statistics](https://img.shields.io/badge/CodeStatistics-abaplint-blue)](https://abaplint.app/stats/greltel/abap-point-gate)

# Table of contents
1. [ABAP Point Gate](#ABAP-Point-Gate)
2. [Prerequisites](#Prerequisites)
3. [License](#License)
4. [Contributors-Developers](#Contributors-Developers)
5. [Motivation for Creating the Repository](#Motivation-for-Creating-the-Repository)
6. [Key Technical Features](#Key-Technical-Features)
7. [Usage Examples](#Usage-Examples)
8. [Design Goals-Features](#Design-Goals-Features)
9. [Changelog](#Changelog)
10. [Roadmap](#Roadmap)

# ABAP Point Gate

ABAP Point Gate is a configuration-driven framework designed to decouple custom enhancements from standard SAP objects, ensuring a clean and maintainable architecture. By leveraging Dependency Injection and Type-Safe Context management, it enables seamless unit testing and granular, hierarchical control over enhancement execution.

# Prerequisites

* SAP S/4HANA 2021 (or higher) OR SAP BTP ABAP Environment.
* XCO library availability
* [Statement Compatibility](https://abaplint.app/stats/greltel/abap-point-gate/statement_compatibility)

## License
This project is licensed under the [MIT License](https://github.com/greltel/ABAP-Point-Gate/blob/main/LICENSE).

## Contributors-Developers
The repository was created by [George Drakos](https://www.linkedin.com/in/george-drakos/).

## Motivation for Creating the Repository

ABAP Point Gate to provide a standardized “gate” around ABAP exit points/enhancements, so custom logic stays isolated from the SAP core instead of being scattered across standard objects. This helps keep the system clean, maintainable, and upgrade-friendly, while offering a consistent way to implement enhancements that aligns with Clean Core / ABAP Cloud readiness practices and encourages quality through automated checks (e.g. abaplint) and unit testing.

## Key Technical Features

* Hierarchical Activation: Control execution at both Point and Gate levels.
* Type-Safe Context: Easily pass and retrieve data with built-in type-safe getters.
* Dependency Injection: Built-in support for Mocking handles and configurations for Unit Testing.
* High Performance: Uses Hashed Tables ($O(1)$ complexity) for context and configuration lookups.
* Clean ABAP: Leverages modern 7.40+ syntax and robust exception handling.

⚙️ Hierarchical Activation Logic

ABAP Point Gate supports a sophisticated activation model:

* Status 'X': Globally Active.
* Status 'C' (Custom): Evaluation via a Custom Activation Class.
* Parent-Child Rule: If the Point is inactive (or its custom toggle returns false), none of its assigned Gates will execute, regardless of their individual status.

## Usage Examples

### 1. Prepare the Context
Prepare the data environment before triggering a gate.

```abap
DATA(lo_context) = NEW zcl_apg_context( ).
lo_context->set_data( i_name = 'BKPF' i_value = lr_bkpf ).
lo_context->set_data( i_name = 'STRING' i_value = REF #( 'TEST_STRING' ) ).
lo_context->set_data( i_name = 'DATE' i_value = REF #( syst-datum ) ).
lo_context->set_data( i_name = 'INTEGER' i_value = REF #( '123' ) ).
```

### 2.Execute the Gate
Trigger the execution logic. The framework automatically identifies and runs all active handlers.

```abap
TRY.
    " 2. Call the Gate
    " The Point ID 'SAMPLE_SAVE_BEFORE' must be configured in table ZAPG_POINT
    zcl_apg_execution=>execute_gate(
      EXPORTING
        i_point_id           = 'SAMPLE_SAVE_BEFORE'
        i_context            = lo_context
      CHANGING
        co_message_container = lt_msg_cont ).
  CATCH zcx_apg_error INTO DATA(lx_apg).
    " Handle framework errors (e.g., configuration missing, instantiation failed)
    MESSAGE lx_apg TYPE 'E'.
ENDTRY.
```

### 3.Handle Results
Retrieve modified data or parameters without manual casting.

```abap
TRY.    
    " A. Check for validation messages returned by handlers
    IF line_exists( lt_msg_cont[ type = 'E' ] ).
       " Handle errors (e.g., abort save, show log)
    ENDIF.

    " B. Retrieve potentially modified data
    " If a handler modified the data, we can get the updated reference back
    lo_context->get_data( EXPORTING i_name = 'BKPF' IMPORTING e_value = DATA(lr_changed_bkpf) ).

    DATA(lv_string)  = lo_context->get_string( 'STRING' ).
    DATA(lv_date)    = lo_context->get_date( 'DATE' ).
    DATA(lv_integer) = lo_context->get_integer( 'INTEGER' ).
CATCH zcx_apg_error INTO DATA(lx_apg).
    " Handle framework errors (e.g., configuration missing, instantiation failed)
    MESSAGE lx_apg TYPE 'E'.
ENDTRY.
```

## Changelog

### [1.0.0] - 2026-01-04
#### Initial Release

## Design Goals-Features

* Install via [ABAPGit](http://abapgit.org)
* ABAP Cloud/Clean Core compatibility.Passed SCI check variant S4HANA_READINESS_2023 and ABAP_CLOUD_READINESS
* Unit Testing for Context and Execution Classes.Full support for ABAP Unit and Test Doubles.
* [ABAPLint](https://github.com/apps/abaplint) enabled

## Roadmap

* Integrated Logging & Monitoring System.
* Parallel Processing for independent handlers.
