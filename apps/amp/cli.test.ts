import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, statSync } from "node:fs";
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

test("delegates this repository and installs the packaged keep-awake plugin", async () => {
  const temporary = mkdtempSync(join(tmpdir(), "amp-cli-"));
  const previous = process.env.XDG_CONFIG_HOME;
  process.env.XDG_CONFIG_HOME = temporary;
  try {
    await cli.parseAsync(["setup"], { from: "user" });
    assert.equal(setup.mock.callCount(), 1);
    const plugin = join(temporary, "amp/plugins/factory-orb-awake.js");
    assert.equal(
      readFileSync(plugin, "utf8"),
      readFileSync(
        new URL(import.meta.resolve("@quantile-co/factory-amp/plugin")),
        "utf8",
      ),
    );
    assert.equal(statSync(plugin).mode & 0o777, 0o644);
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
