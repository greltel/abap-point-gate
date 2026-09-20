# Off-stack DDIC stubs

Minimal serialized copies of SAP standard DDIC objects that the repository's
own tables reference, but which `open-abap-core` does not ship.

They exist **only** so the abaplint transpiler can build the SQLite schema of
`ZAPG_POINT_D` / `ZAPG_GATE_H_D` when the unit tests run off-stack in CI.

* Not part of the abapGit repository — `src/` is the only serialized package.
* Not linted — `abaplint.json` scopes itself to `/src/**/*.*`.
* Never imported into a SAP system.

`UnknownType`, and keep it as small as the type resolution allows: a single
data element carrying `DATATYPE` / `LENG` directly. Do not serialize the
domain — abaplint only follows `DOMNAME` when `REFKIND` is `D`, so the
predefined-type form is both shorter and more robust.
