import assert from "node:assert/strict";
import {
  existsSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { type TestContext, test } from "node:test";
import { setTimeout as delay } from "node:timers/promises";
import {
  migrateBackend,
  migrationAnswer,
  runOwned,
  stateDigest,
  verifySourceInventory,
  verifyTransition,
} from "./migration.ts";

function fixture(t: TestContext) {
  const directory = mkdtempSync(join(tmpdir(), "organization-migration-"));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  return directory;
}

const emptyPrompt =
  'No existing state was found in the newly configured "gcs" backend.\nDo you want to copy existing state to the new backend?\nEnter a value:';

test("only the pinned empty-destination prompt is acknowledged", () => {
  assert.equal(migrationAnswer(emptyPrompt), "yes\n");
  for (const prompt of [
    "Enter a value:",
    emptyPrompt.replace("gcs", "local"),
    emptyPrompt.replace(
      'No existing state was found in the newly configured "gcs" backend.',
      "An existing non-empty state already exists in the new backend.",
    ),
  ])
    assert.equal(migrationAnswer(prompt), "no\n");
});

test("accepts only GCS serial +1 without changing any other canonical field", () => {
  const original = {
    version: 4,
    terraform_version: "1.13.1",
    serial: 78,
    lineage: "same-lineage",
    resources: [],
    outputs: { sentinel: { value: "unchanged", type: "string" } },
  };
  const bytes = (value: unknown) => Buffer.from(JSON.stringify(value));
  assert.doesNotThrow(() =>
    verifyTransition(bytes(original), bytes({ ...original, serial: 79 })),
  );
  for (const after of [
    { ...original, serial: 80 },
    { ...original, serial: 79, lineage: "foreign" },
    { ...original, serial: 79, terraform_version: "1.13.0" },
    { ...original, serial: 79, outputs: {} },
  ])
    assert.throws(
      () => verifyTransition(bytes(original), bytes(after)),
      /transition/,
    );
});

test("preserves numeric lexemes outside JavaScript integer precision", () => {
  const before = Buffer.from(
    '{"version":4,"terraform_version":"1.13.1","serial":78,"lineage":"same","resources":[],"outputs":{"number":{"type":"number","value":9007199254740992}}}',
  );
  const changedPayload = Buffer.from(
    before.toString().replace("9007199254740992", "9007199254740993"),
  );
  assert.notEqual(stateDigest(before), stateDigest(changedPayload));
  assert.throws(
    () =>
      verifyTransition(
        before,
        Buffer.from(
          changedPayload.toString().replace('"serial":78', '"serial":79'),
        ),
      ),
    /transition/,
  );
  assert.doesNotThrow(() =>
    verifyTransition(
      before,
      Buffer.from(before.toString().replace('"serial":78', '"serial":79')),
    ),
  );
});

test("rejects immediate source workspaces, locks and pagination", () => {
  const prefix = "example/prod";
  const inventory = {
    items: [{ name: `${prefix}/default.tfstate` }],
    prefixes: [`${prefix}/application/`, `${prefix}/migrations/`],
  };
  assert.doesNotThrow(() => verifySourceInventory(prefix, inventory));
  for (const listing of [
    { items: [...inventory.items, { name: `${prefix}/other.tfstate` }] },
    { items: [...inventory.items, { name: `${prefix}/other.tflock` }] },
    { ...inventory, nextPageToken: "more" },
  ])
    assert.throws(() => verifySourceInventory(prefix, listing), /inventory/);
});

test("captures stdout and private diagnostics without printing provider output", async (t) => {
  const directory = fixture(t);
  const log = join(directory, "private.log");
  const output = await runOwned(
    process.execPath,
    [
      "-e",
      'process.stdout.write("saved bytes"); process.stderr.write("private diagnostic");',
    ],
    process.env,
    log,
  );
  assert.equal(output.toString(), "saved bytes");
  assert.match(readFileSync(log, "utf8"), /private diagnostic/);
  assert.equal(statSync(log).mode & 0o777, 0o600);
  assert.equal(
    (
      await runOwned(
        process.execPath,
        ["-e", 'process.stdout.write("fixture-token")'],
        process.env,
      )
    ).toString(),
    "fixture-token",
  );
  await assert.rejects(
    runOwned(join(directory, "missing"), [], process.env, log),
    /could not start/,
  );
  const abort = new AbortController();
  abort.abort(new Error("stopped before spawn"));
  await assert.rejects(
    runOwned(
      process.execPath,
      ["-e", "process.exit(99)"],
      process.env,
      undefined,
      undefined,
      abort.signal,
    ),
    /stopped before spawn/,
  );
});

function alive(pid: number) {
  try {
    process.kill(pid, 0);
    // A dead orphan may remain a zombie until the host's init reaps it.
    if (process.platform === "linux")
      return !/^Z /.test(
        readFileSync(`/proc/${pid}/stat`, "utf8").split(") ").at(-1) ?? "",
      );
    return true;
  } catch (error) {
    if (
      ["ESRCH", "ENOENT"].includes((error as NodeJS.ErrnoException).code ?? "")
    )
      return false;
    throw error;
  }
}

for (const mode of ["interrupt", "timeout", "orphan"] as const) {
  test(`supervises uncooperative process and descendant: ${mode}`, {
    timeout: 15_000,
  }, async (t) => {
    const directory = fixture(t);
    const record = join(directory, "processes.json");
    const fake = join(directory, "native.mjs");
    writeFileSync(
      fake,
      `
import { spawn } from "node:child_process";
import { writeFileSync } from "node:fs";
process.on("SIGINT", () => {});
const child = spawn(process.execPath, ["--input-type=module", "-e", 'process.on("SIGINT",()=>{}); process.send("ready"); setInterval(()=>{},1000);'], { stdio: ["ignore", "inherit", "inherit", "ipc"] });
child.once("message", () => {
  writeFileSync(${JSON.stringify(record)}, JSON.stringify({ leader: process.pid, descendant: child.pid }));
  if (process.env.TEST_MODE === "orphan") process.exit(0);
});
setInterval(()=>{},1000);
`,
    );
    const abort = new AbortController();
    const started = Date.now();
    const outcome = runOwned(
      process.execPath,
      [fake],
      { ...process.env, TEST_MODE: mode },
      join(directory, "private.log"),
      undefined,
      abort.signal,
      mode === "timeout" ? 1_500 : 10_000,
    ).then(
      () => undefined,
      (error: unknown) => error,
    );
    let pids: { leader: number; descendant: number } | undefined;
    t.after(() => {
      if (pids && (alive(pids.leader) || alive(pids.descendant))) {
        try {
          process.kill(-pids.leader, "SIGKILL");
        } catch {
          /* Already exited. */
        }
      }
    });
    for (let i = 0; i < 300 && !existsSync(record); i++) await delay(10);
    assert.ok(
      existsSync(record),
      "fake native and descendant reached readiness",
    );
    pids = JSON.parse(readFileSync(record, "utf8"));
    assert.ok(pids);
    if (mode === "interrupt") abort.abort();
    const error = await outcome;
    assert.ok(error instanceof Error);
    assert.match(
      error.message,
      mode === "interrupt"
        ? /interrupted/
        : mode === "timeout"
          ? /timed out/
          : /descendants/,
    );
    assert.ok(Date.now() - started < 12_000, "bounded termination");
    assert.equal(
      alive(pids.leader),
      false,
      "leader has closed before settlement",
    );
    for (let i = 0; i < 100 && alive(pids.descendant); i++) await delay(10);
    assert.equal(
      alive(pids.descendant),
      false,
      "owned descendant is no longer running",
    );
  });
}

test("refuses a native overwrite prompt and handles stdin closure", async (t) => {
  const directory = fixture(t);
  const fake = join(directory, "fake.mjs");
  writeFileSync(
    fake,
    `process.stderr.write(${JSON.stringify(emptyPrompt.replace('No existing state was found in the newly configured "gcs" backend.', "An existing non-empty state already exists in the new backend."))}); process.stdin.resume(); process.stdin.on("data",()=>process.exit(0));`,
  );
  await assert.rejects(
    runOwned(
      process.execPath,
      [fake],
      process.env,
      join(directory, "private.log"),
      "gcs",
    ),
    /Refused/,
  );
  writeFileSync(
    fake,
    `import { closeSync } from "node:fs"; closeSync(0); process.stderr.write(${JSON.stringify(emptyPrompt)}); setInterval(()=>{},1000);`,
  );
  await assert.rejects(
    runOwned(
      process.execPath,
      [fake],
      process.env,
      join(directory, "private.log"),
      "gcs",
      undefined,
      3_000,
    ),
    /stdin failed/,
  );
});

test("wrapper performs real native local migration and refuses an occupied destination", {
  timeout: 30_000,
}, async (t) => {
  const directory = fixture(t);
  const env = {
    PATH: process.env.PATH,
    HOME: directory,
    TF_DATA_DIR: join(directory, ".terraform"),
    TF_IN_AUTOMATION: "true",
    TF_WORKSPACE: "default",
  };
  const old = join(directory, "old.tfstate"),
    destination = join(directory, "new.tfstate"),
    occupied = join(directory, "occupied.tfstate"),
    log = join(directory, "private.log");
  const state = {
    version: 4,
    terraform_version: "1.13.1",
    serial: 7,
    lineage: "440620c2-1ddd-4632-bc57-61247c862334",
    outputs: { sentinel: { value: "preserve", type: "string" } },
    resources: [],
  };
  writeFileSync(
    join(directory, "backend.tf"),
    'terraform {\n backend "local" {}\n}\n',
  );
  writeFileSync(old, JSON.stringify(state));
  const run = (...args: string[]) =>
    runOwned("tofu", [`-chdir=${directory}`, ...args], env, log);
  await run("init", "-input=false", `-backend-config=path=${old}`);
  const before = await run("state", "pull");
  await migrateBackend(
    [
      `-chdir=${directory}`,
      "init",
      "-migrate-state",
      "-input=true",
      "-no-color",
      `-backend-config=path=${destination}`,
    ],
    env,
    log,
    "local",
  );
  verifyTransition(before, await run("state", "pull"), 2);
  writeFileSync(
    occupied,
    JSON.stringify({
      ...state,
      lineage: "cb708b52-2270-42b6-8790-006bfbcf9437",
      outputs: { sentinel: { value: "foreign", type: "string" } },
    }),
  );
  const foreign = readFileSync(occupied);
  await assert.rejects(
    migrateBackend(
      [
        `-chdir=${directory}`,
        "init",
        "-migrate-state",
        "-input=true",
        "-no-color",
        `-backend-config=path=${occupied}`,
      ],
      env,
      log,
      "local",
    ),
    /Refused/,
  );
  assert.ok(readFileSync(occupied).equals(foreign));
});
