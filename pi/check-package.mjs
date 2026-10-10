// Offline smoke checks; never use the caller's Pi configuration or contact a model.
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { createRequire } from "node:module";
import { mkdtempSync, mkdirSync, readFileSync, realpathSync, readdirSync, lstatSync } from "node:fs";
import { homedir } from "node:os";
import path from "node:path";
import { pathToFileURL } from "node:url";

const [rootArg, version] = process.argv.slice(2);
assert(rootArg && version, "usage: node check-package.mjs <install-root> <version>");
const root = realpathSync(rootArg);
const scratchRoot = process.env.TMPDIR || path.join(homedir(), ".local/state/agents/tmp");
mkdirSync(scratchRoot, { recursive: true });
const scratch = mkdtempSync(path.join(scratchRoot, "pi-check-"));
console.log(`Pi test fixtures: ${scratch}`);
for (const key of Object.keys(process.env)) {
  if (key.startsWith("PI_")) delete process.env[key];
}
process.env.HOME = scratch;
process.env.XDG_CONFIG_HOME = path.join(scratch, "config");
process.env.XDG_CACHE_HOME = path.join(scratch, "cache");
process.env.PI_CODING_AGENT_DIR = path.join(scratch, "agent");
process.chdir(scratch);

const modules = path.join(root, "node_modules");
const agent = path.join(modules, "@earendil-works/pi-coding-agent");
const manifest = JSON.parse(readFileSync(path.join(agent, "package.json"), "utf8"));
assert.equal(manifest.version, version);
const cli = path.join(agent, manifest.bin.pi);
for (const [flag, check] of [
  ["--version", (output) => assert.equal(output.trim(), version)],
  ["--help", (output) => assert.match(output, /Usage:/)],
]) {
  const result = spawnSync(process.execPath, [cli, flag], {
    encoding: "utf8", timeout: 30_000,
  });
  assert.equal(result.status, 0, result.error?.message || result.stderr);
  check(result.stdout);
}

const sdk = await import(pathToFileURL(path.join(agent, "dist/index.js")));
assert.equal(typeof sdk.createAgentSession, "function");
const require = createRequire(path.join(agent, "package.json"));
const esbuild = require("esbuild");
assert.match(esbuild.transformSync("const n: number = 1", { loader: "ts" }).code, /const n = 1/);
require("@silvia-odwyer/photon-node"); // Loads the image-processing WASM.
require(path.join(modules, "@earendil-works/pi-tui/native/linux/prebuilds/linux-x64/linux-platform-x11.node"));

for (const file of [
  "README.md", "CHANGELOG.md", "docs/quickstart.md", "examples/extensions/hello.ts",
  "dist/index.d.ts", "dist/bundle/rpc-entry.js", "dist/extensions/codemode/worker.js",
  "dist/modes/interactive/theme/dark.json", "dist/core/export-html/template.html",
]) {
  assert(lstatSync(path.join(agent, file)).isFile(), `missing runtime asset: ${file}`);
}
function checkLinks(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const file = path.join(dir, entry.name);
    if (entry.isSymbolicLink()) {
      const target = realpathSync(file);
      assert(target.startsWith(`${root}${path.sep}`), `external symlink: ${file} -> ${target}`);
    } else if (entry.isDirectory()) {
      checkLinks(file);
    }
  }
}
checkLinks(modules);
console.log(`Pi ${version}: CLI, SDK, esbuild, WASM, native module, assets and symlinks OK`);
