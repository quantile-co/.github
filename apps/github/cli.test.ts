import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  chmodSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

test("CLI retains the backend and saved bytes while isolating provider credentials", () => {
  const root = mkdtempSync(join(tmpdir(), "organization-cli-"));
  try {
    const bin = join(root, "bin");
    mkdirSync(bin);
    const providerLog = join(root, "provider");
    const storageLog = join(root, "storage");
    const saved = join(root, "saved.tfplan");
    const fail = join(root, "fail");
    const executable = (name: string, code: string) => {
      const path = join(bin, name);
      writeFileSync(path, `#!${process.execPath}\n${code}`);
      chmodSync(path, 0o755);
    };
    executable(
      "tofu",
      `
const fs = require("node:fs"), a = process.argv.slice(2);
fs.appendFileSync(${JSON.stringify(providerLog)}, JSON.stringify({args:a,env:process.env,cwd:process.cwd()})+"\\n");
console.log("private-provider-diagnostic");
if(a.includes("plan")) {
  if(fs.existsSync(${JSON.stringify(fail)})) process.exit(7);
  fs.writeFileSync(a.find(x=>x.startsWith("-out=")).slice(5),"reviewed saved bytes");
}
if(a.includes("apply") && fs.readFileSync(a.at(-1),"utf8") !== "reviewed saved bytes") process.exit(81);
`,
    );
    executable(
      "gcloud",
      `
const fs = require("node:fs"), path = require("node:path"), a = process.argv.slice(2);
fs.appendFileSync(${JSON.stringify(storageLog)}, JSON.stringify({args:a,env:process.env})+"\\n");
if(a.slice(0,3).join(" ") === "storage cp --recursive") fs.copyFileSync(path.join(a[3],"plan.tfplan"),${JSON.stringify(saved)});
else if(a.slice(0,3).join(" ") === "storage objects describe") console.log("42");
else if(a[0] === "storage" && a[1] === "cp" && a[2].endsWith("#42")) fs.copyFileSync(${JSON.stringify(saved)},a[3]);
else if(a[0] !== "storage" || a[1] !== "cp") process.exit(82);
`,
    );
    const invoke = (phase: "plan" | "apply", withHindsightToken = true) =>
      spawnSync(
        process.execPath,
        [
          "--import",
          "tsx",
          fileURLToPath(new URL("./cli.ts", import.meta.url)),
          phase,
          "--tf-layer",
          "infrastructure",
          "--gcp-tf-state-bucket",
          "private-bucket",
          "--gcp-wif-pool",
          "approved-pool",
          ...(phase === "apply" ? ["--gh-plan-ref", "456/1/42"] : []),
        ],
        {
          encoding: "utf8",
          env: {
            ...process.env,
            PATH: `${bin}:${process.env.PATH}`,
            GH_REPO_TOKEN: "fixture-credential",
            HINDSIGHT_API_TOKEN: withHindsightToken
              ? "fixture-hindsight-token"
              : undefined,
            TF_VAR_hindsight_api_token: "unapproved-hindsight-token",
            GITHUB_TOKEN: "unapproved-native",
            REST_API_BEARER: "unapproved-native",
            TF_VAR_unapproved: "must-not-leak",
            TF_BACKEND_PREFIX: "must-not-leak",
            GITHUB_REPOSITORY: "quantile-co/.github",
            GITHUB_REPOSITORY_ID: "123",
            GITHUB_RUN_ID: "456",
            GITHUB_RUN_ATTEMPT: "1",
            GITHUB_STEP_SUMMARY: join(root, "summary"),
            RUNNER_TEMP: root,
          },
        },
      );
    for (const phase of ["plan", "apply"] as const) {
      const missingToken = invoke(phase, false);
      assert.notEqual(missingToken.status, 0);
      assert.match(missingToken.stderr, /Missing HINDSIGHT_API_TOKEN/);
      assert.equal(existsSync(providerLog), false);
      assert.equal(existsSync(storageLog), false);
    }
    for (const phase of ["plan", "apply"] as const) {
      const result = invoke(phase);
      assert.equal(result.status, 0, result.stderr);
      assert.doesNotMatch(
        result.stdout + result.stderr,
        /fixture-credential|fixture-hindsight-token|private-provider-diagnostic/,
      );
    }
    assert.match(readFileSync(join(root, "summary"), "utf8"), /456\/1\/42/);
    const providers = readFileSync(providerLog, "utf8")
      .trim()
      .split("\n")
      .map((line) => JSON.parse(line));
    assert.deepEqual(providers[0].args, [
      "-chdir=tf",
      "init",
      "-input=false",
      "-lockfile=readonly",
      "-backend-config=bucket=private-bucket",
      "-backend-config=prefix=.github/prod/infrastructure",
    ]);
    assert.equal(
      providers.filter((call) => call.args.includes("plan")).length,
      1,
    );
    assert.equal(
      providers.filter((call) => call.args.includes("apply")).length,
      1,
    );
    for (const call of providers) {
      assert.equal(call.args[0], "-chdir=tf");
      assert.equal(call.env.GITHUB_TOKEN, "fixture-credential");
      assert.equal(call.env.REST_API_BEARER, "fixture-credential");
      assert.equal(call.env.TF_VAR_gcp_wif_pool, "approved-pool");
      assert.equal(
        call.env.TF_VAR_hindsight_api_token,
        "fixture-hindsight-token",
      );
      assert.equal(call.env.HINDSIGHT_API_TOKEN, undefined);
      assert.equal(call.env.TF_VAR_unapproved, undefined);
      assert.equal(call.env.TF_BACKEND_PREFIX, undefined);
    }
    const storage = readFileSync(storageLog, "utf8")
      .trim()
      .split("\n")
      .map((line) => JSON.parse(line));
    assert.ok(
      storage.some((call) =>
        call.args.some((value: string) => value.endsWith("plan.tfplan#42")),
      ),
    );
    for (const call of storage) {
      assert.equal(call.env.GH_REPO_TOKEN, undefined);
      assert.equal(call.env.GITHUB_TOKEN, undefined);
      assert.equal(call.env.REST_API_BEARER, undefined);
      assert.equal(call.env.TF_VAR_gcp_wif_pool, undefined);
      assert.equal(call.env.TF_VAR_hindsight_api_token, undefined);
      assert.equal(call.env.HINDSIGHT_API_TOKEN, undefined);
    }
    writeFileSync(fail, "fail");
    const failed = invoke("plan");
    assert.equal(failed.status, 7);
    assert.doesNotMatch(
      failed.stdout + failed.stderr,
      /fixture-credential|fixture-hindsight-token|private-provider-diagnostic/,
    );
    assert.equal(existsSync(join(root, "saved-plan")), false);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test("Hindsight provisioning is ephemeral and protected; native memory is repository-scoped", () => {
  const source = (path: string) =>
    readFileSync(new URL(`../../${path}`, import.meta.url), "utf8");
  const variable = source("tf/variables.tf").match(
    /variable "hindsight_api_token" \{([\s\S]*?)\n\}/,
  )?.[1];
  assert.ok(variable);
  assert.match(variable, /sensitive\s*=\s*true/);
  assert.match(variable, /ephemeral\s*=\s*true/);
  assert.doesNotMatch(variable, /default\s*=/);
  assert.match(
    source("tf/providers.tf"),
    /bearer_token\s*=\s*var\.hindsight_api_token/,
  );
  assert.match(source("tf/main.tf"), /restapi\s*=\s*restapi\.hindsight/);
  assert.match(source("tf/main.tf"), /bank_id\s*=\s*"quantile-co--github"/);
  assert.match(source("tf/main.tf"), /name\s*=\s*"quantile-co\/\.github"/);
  for (const phase of ["plan", "apply"]) {
    const workflow = source(`.github/workflows/${phase}.yaml`);
    assert.match(
      workflow,
      /HINDSIGHT_API_TOKEN: \$\{\{ secrets\.HINDSIGHT_API_TOKEN \}\}/,
    );
    assert.match(workflow, /refs\/heads\/main/);
    assert.match(workflow, /environment: prod/);
    assert.match(workflow, /group: organization-production/);
  }
  for (const phase of ["check", "test"]) {
    assert.doesNotMatch(
      source(`.github/workflows/${phase}.yaml`),
      /HINDSIGHT_API_TOKEN/,
    );
  }
  const settings = JSON.parse(source(".pi/settings.json"));
  assert.ok(
    settings.packages.includes(
      "npm:@vectorize-io/hindsight-coding-agents@0.8.7",
    ),
  );
  assert.ok(
    settings.packages.includes("npm:@langfuse/pi-observability-plugin@0.1.2"),
  );
  assert.ok(
    settings.extensions.includes(
      "./npm/node_modules/@vectorize-io/hindsight-coding-agents/dist/pi.js",
    ),
  );
  assert.doesNotMatch(JSON.stringify(settings), /pi-memory/);
  const config = JSON.parse(source(".pi/hindsight.json"));
  assert.equal(config.bankId, "quantile-co--github");
  assert.equal(config.apiUrl, "https://api.hindsight.vectorize.io");
  assert.equal(config.dynamicBankId, false);
  assert.equal(config.optInOnly, true);
  assert.equal(config.resolveWorktrees, true);
  assert.equal(config.autoSeed, false);
  assert.equal(config.gitIngest, "none");
  assert.equal(config.codebaseSurvey, false);
  assert.equal(config.observationScopes, "shared");
  assert.equal(config.recallOptions.max_tokens, 2000);
  assert.equal(config.apiToken, undefined);
  assert.equal(config.apiKey, undefined);
  for (const retired of [".pi/memory/MEMORY.md", ".qmd/index.yml"]) {
    assert.equal(
      existsSync(new URL(`../../${retired}`, import.meta.url)),
      false,
    );
  }
  assert.doesNotMatch(
    source("flake.nix"),
    /factory\.qmd|factory\.pi\.shellHook/,
  );
  assert.match(source("flake.nix"), /factory\.hindsight\.shellHook/);
  assert.match(source("package.json"), /@quantile-co\/factory-pi#hindsight/);
});
