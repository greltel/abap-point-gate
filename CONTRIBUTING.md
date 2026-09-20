# Contributing to ABAP Point Gate

Thanks for taking the time. Issues and pull requests are both welcome.

## The source of truth is an SAP system, not this repository

The ABAP source here is serialized by [abapGit](https://abapgit.org). You cannot
develop against these files directly — they are written by, and read back into, an ABAP
system. The workflow is:

1. Clone the repository into a package in your own system with abapGit.
2. Make the change in ADT, activate it, and run the unit tests.
3. Stage and push from abapGit, then open a pull request.

Set the repository's **ABAP Language Version** to *ABAP for Cloud Development* in the
abapGit repository settings. The framework targets ABAP Cloud only; a change that needs
Standard ABAP will not be merged.

## Requirements for a pull request

- **SAP S/4HANA 2023 FPS03 or higher** (ABAP 7.58), or SAP BTP ABAP Environment.
- **abaplint passes.** Run `npm install && npm run lint` locally, or let CI do it. A new
  rule exception needs a `_comment` in `abaplint.json` saying why it exists.
- **Released APIs only.** No `SY-DATUM`, no `SY-UNAME`, no unreleased classes. System
  context is read through `ZIF_APG_CLOCK` and its siblings, never inline.
- **ABAP Doc (`"!`) on every public declaration.** Comments say *why*, never *what*.
- **A unit test for every behaviour you add or change.** New global classes ship with a
  test include. The two exceptions are the boundary adapters `ZCL_APG_AUTHORIZATION` and
  `ZCL_APG_SYSTEM_CLOCK`, which exist precisely so that everything else can be doubled.
- **No exceptions out of RAP handlers.** Report through `failed` / `reported`; draft
  validations write `%state_area` messages.

## Naming

| Prefix | Object |
|---|---|
| `ZIF_APG_*` | Interfaces |
| `ZCL_APG_*` | Classes |
| `ZCX_APG_*` | Exceptions |
| `ZCM_APG_*` | RAP message classes |
| `ZR_APG_*` / `ZC_APG_*` | Base and projection CDS views |
| `ZBP_R_APG_*` | Behavior pools |
| `ZI_APG_*_VH` | Value helps |

## Reporting a bug

Include the release and feature pack of your system, the object that fails, and the exact
message or short dump text. If it is a runtime problem in a handler chain, the point ID
and the sequence numbers of the gates involved help more than anything else.

## License

By contributing you agree that your contribution is licensed under the
[MIT License](LICENSE).
