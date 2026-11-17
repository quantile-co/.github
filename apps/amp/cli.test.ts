import assert from "node:assert/strict";
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { mock, test } from "node:test";

const setup = mock.fn();
const resume = mock.fn();
const connect = mock.fn();
mock.module("@quantile-co/factory-amp", {
  namedExports: { setup, resume, connect, list: mock.fn() },
});
const { cli } = await import("./cli.ts");

test("delegates this repository and replaces only retired Factory plugins with its unified bundle", async () => {
  const temporary = mkdtempSync(join(tmpdir(), "amp-cli-"));
  const previous = process.env.XDG_CONFIG_HOME;
  process.env.XDG_CONFIG_HOME = temporary;
  try {
    const directory = join(temporary, "amp/plugins");
    mkdirSync(directory, { recursive: true });
    for (const name of [
      "factory-orb-awake.js",
      "factory-observability.js",
      "unrelated.js",
    ])
      writeFileSync(join(directory, name), "unrelated");
    await cli.parseAsync(["setup"], { from: "user" });
    assert.equal(setup.mock.callCount(), 1);
    const plugin = join(directory, "quantile-co-factory-amp.js");
    assert.equal(
      readFileSync(plugin, "utf8"),
      readFileSync(
        new URL(import.meta.resolve("@quantile-co/factory-amp/plugin")),
        "utf8",
      ),
    );
    assert.equal(statSync(plugin).mode & 0o777, 0o644);
    assert.equal(existsSync(join(directory, "factory-orb-awake.js")), false);
    assert.equal(
      existsSync(join(directory, "factory-observability.js")),
      false,
    );
    assert.equal(
      readFileSync(join(directory, "unrelated.js"), "utf8"),
      "unrelated",
    );
    await cli.parseAsync(
      ["resume", "--directory", "/disposable/repo", "--thread", "test-thread"],
      { from: "user" },
    );
    assert.deepEqual(resume.mock.calls[0].arguments, [
      { repository: "quantile-co/.github", thread: "test-thread" },
      "/disposable/repo",
    ]);
    await cli.parseAsync(
      ["connect", "--thread", "test-thread", "--title", "Manual test"],
      { from: "user" },
    );
    assert.deepEqual(connect.mock.calls[0].arguments, [
      {
        repository: "quantile-co/.github",
        thread: "test-thread",
        title: "Manual test",
      },
    ]);
  } finally {
    if (previous === undefined) delete process.env.XDG_CONFIG_HOME;
    else process.env.XDG_CONFIG_HOME = previous;
    rmSync(temporary, { recursive: true, force: true });
  }
});
