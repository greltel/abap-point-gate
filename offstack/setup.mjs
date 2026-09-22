// Off-stack database bootstrap, wired in via abap_transpile.json -> "setup".
// Connects an in-memory SQLite database as the DEFAULT connection and creates
// the DDIC tables the transpiler discovered (ZAPG_POINT, ZAPG_GATE_HANDLE, ...).
// CL_OSQL_TEST_ENVIRONMENT asserts sy-dbsys = 'sqlite' and clones these tables
// into an attached "double" schema, so without this hook every OSQL test double fails.
import {SQLiteDatabaseClient} from "@abaplint/database-sqlite";

export async function setup(abap, schemas, insert) {
  const db = new SQLiteDatabaseClient();
  abap.context.databaseConnections["DEFAULT"] = db;
  await db.connect();
  await db.execute(schemas.sqlite);
  await db.execute(insert);
}
