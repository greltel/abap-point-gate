# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2026-09-20

Hardening release. The framework keeps its shape; what changed is that every
dependency on the outside world now sits behind an interface, the configuration
business object has an authorization layer, and nothing is left untested.

### Added

- **Authorization layer.** Authorization object `ZAPG_POINT` (`ZAPG_PID` / `ACTVT`),
  `ZIF_APG_AUTHORIZATION` with `ZCL_APG_AUTHORIZATION` — the single `AUTHORITY-CHECK`
  of the framework — and global/instance authorization handlers in the behavior pool.
- **DCL roles** `ZR_APG_POINT`, `ZC_APG_POINT` and `ZI_APG_VALUE_HELPS`, so the
  `@AccessControl.authorizationCheck: #CHECK` annotations are actually backed by rules.
- **`ZIF_APG_CLOCK` / `ZCL_APG_SYSTEM_CLOCK`** — system date behind an interface, so
  time-dependent toggles are testable and no consumer reads the system context directly.
- **`ZIF_APG_CLASS_INSPECTOR` / `ZCL_APG_CLASS_INSPECTOR`** — RTTI lookups behind an
  interface, replacing the duplicated class checks in the injector and the behavior pool.
- **`ZIF_APG_DOMAIN_VALUES` / `ZCL_APG_DOMAIN_VALUES`** — domain fixed values for the
  value-help custom entities.
- **`ZIF_APG_EXECUTION`** — the facade is now instantiable and injectable; the static
  `ZCL_APG_EXECUTION=>EXECUTE_GATE` stays as a thin wrapper.
- **`ZCM_APG_POINT`** — RAP message class, so validation messages are named constants
  the tests assert on instead of message numbers.
- `ZCL_APG_INJECTOR=>HAS_CONFIGURATIONS` and `INJECT_CLASS_INSPECTOR`.
- Message `ZAPG 011` — "Context value &1 is stored but empty".
- **RAP layer:** `use etag` in the projection, `side effects` on the activation fields,
  `%state_area` state messages in every draft validation, administrative-data facet on
  the Gate entity, and the five missing value helps exposed in the service definition.
- **94 ABAP Unit tests** across 11 test includes, including RAP validation tests through
  `CL_CDS_TEST_ENVIRONMENT`.

### Fixed

- **`ZCL_APG_CONTEXT=>SET_DATA` deleted the entire context.** `DELETE entries WHERE
  name = name` compared the table component with itself, which is always true, so every
  stored value was dropped on each call. Replaced with a keyed `DELETE TABLE`. The
  existing test passed only because it re-stored the same key.
- `ZCL_APG_FACTORY` read the configuration through a join, which bypasses the table
  buffer. Split into two single-table reads ordered by primary key.
- An injected but empty configuration is now honoured instead of silently falling back
  to the database — a test asking for "no gates" no longer reads the persistent tables.
- `ZCL_APG_CONTEXT` reported a missing name and an unusable reference with the same
  message; the second case now has its own.

### Changed

- **Breaking:** `ZCL_APG_EXECUTION` is no longer a pure static utility. Existing calls to
  `ZCL_APG_EXECUTION=>EXECUTE_GATE` keep working unchanged.
- The behavior pool no longer performs RTTI lookups or system-context reads of its own;
  both go through injectable adapters.
- DDIC: `PROGNAME` replaced by `SYREPID`, blank domain fixed value removed.

## [2.0.0] - 2026-08-09

Full production-hardening rewrite: ABAP Cloud readiness, T100-based error handling,
handler parameters, hardened RAP layer (validations, optimistic locking, domain-based
value helps) and unit-test coverage. Contains breaking API changes.

## [1.0.0] - 2026-01-04

Initial release.

[3.0.0]: https://github.com/greltel/abap-point-gate/releases/tag/v3.0.0
[2.0.0]: https://github.com/greltel/abap-point-gate/releases/tag/v2.0.0
[1.0.0]: https://github.com/greltel/abap-point-gate/releases/tag/v1.0.0
