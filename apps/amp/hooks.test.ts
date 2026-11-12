import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  chmodSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../../", import.meta.url));
test("rejects non-orbs and keeps ingestion credentials out of Nix evaluation", () => {
  const temporary = mkdtempSync(join(tmpdir(), "amp-hooks-"));
  const log = join(temporary, "calls");
  try {
    for (const tool of ["nix", "pnpm"]) {
      const path = join(temporary, tool);
      writeFileSync(
        path,
        `#!${process.execPath}
const fs = require("node:fs");
const args = process.argv.slice(2);
fs.appendFileSync(${JSON.stringify(log)}, JSON.stringify({
  tool: ${JSON.stringify(tool)}, args, cwd: process.cwd(),
  endpoint: !!process.env.CLICKSTACK_OTLP_ENDPOINT,
  key: !!process.env.CLICKSTACK_API_KEY,
  docker: !!process.env.OTEL_DOCKER_STATS,
  config: process.env.NIX_CONFIG,
  shell: process.env.SHELL_READY,
}) + "\\n");
if (${JSON.stringify(tool)} === "nix") {
  if (args[0] === "store") console.log('{"trusted":true}');
  if (args[0] === "print-dev-env") console.log("export SHELL_READY=1");
}
`,
      );
      chmodSync(path, 0o755);
    }
    for (const phase of ["setup", "resume"]) {
      const invoke = (orb: string) =>
        spawnSync("bash", [join(root, ".agents", phase)], {
          encoding: "utf8",
          env: {
            PATH: `${temporary}:${process.env.PATH}`,
            HOME: temporary,
            AMP_ORB: orb,
            CLICKSTACK_OTLP_ENDPOINT: "https://ingest.example.invalid",
            CLICKSTACK_API_KEY: "fixture",
            OTEL_DOCKER_STATS: "1",
          },
        });
      writeFileSync(log, "");
      assert.equal(invoke("0").status, 1);
      assert.equal(readFileSync(log, "utf8"), "");
      const result = invoke("1");
      assert.equal(result.status, 0, result.stderr);
      const calls = readFileSync(log, "utf8")
        .trim()
        .split("\n")
        .map((line) => JSON.parse(line));
      const nix = calls.filter((call) => call.tool === "nix");
      assert.ok(
        nix.every((call) => !call.endpoint && !call.key && !call.docker),
      );
      assert.match(nix.at(-1).config, /extra-trusted-public-keys/);
      assert.doesNotMatch(nix.at(-1).config, /require-sigs\s*=\s*false/);
      if (phase === "resume") {
        const last = calls.at(-1);
        assert.equal(last.tool, "pnpm");
        assert.deepEqual(last.args, [
          "amp",
          "resume",
          "--directory",
          root.slice(0, -1),
        ]);
        assert.ok(last.endpoint && last.key && last.docker);
        assert.equal(last.shell, "1");
      } else {
        assert.match(nix.at(-1).args.at(-1), /pnpm install --frozen-lockfile/);
        assert.match(nix.at(-1).args.at(-1), /pnpm amp setup/);
      }
    }
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
});
