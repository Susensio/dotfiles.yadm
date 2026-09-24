import { spawn } from "node:child_process";
import { chmod, mkdir, mkdtemp, rm } from "node:fs/promises";
import { join, resolve } from "node:path";

const SANDBOX_SCRIPT = String.raw`
set -eu
cwd=$1
upper=$2
work=$3
merged=$4
cache=$5
home=$6
command=$7

mount --make-rprivate /
mount -t overlay overlay -o "lowerdir=$cwd,upperdir=$upper,workdir=$work" "$merged"

set -- \
  bwrap \
  --die-with-parent \
  --new-session \
  --ro-bind / / \
  --dev /dev \
  --proc /proc \
  --tmpfs /tmp \
  --dir /tmp/pi-cache \
  --bind "$cache" /tmp/pi-cache \
  --dir "$cwd" \
  --bind "$merged" "$cwd" \
  --chdir "$cwd" \
  --setenv TMPDIR /tmp \
  --setenv TMP /tmp \
  --setenv TEMP /tmp \
  --setenv XDG_CACHE_HOME /tmp/pi-cache \
  --setenv npm_config_cache /tmp/pi-cache/npm \
  --setenv PIP_CACHE_DIR /tmp/pi-cache/pip \
  --setenv UV_CACHE_DIR /tmp/pi-cache/uv

if [ -d "$home/.cache" ]; then
  set -- "$@" --bind "$cache" "$home/.cache"
fi

exec "$@" -- bash -lc "$command"
`;

function killProcessGroup(child) {
  if (!child.pid) return;

  try {
    process.kill(-child.pid, "SIGKILL");
  } catch {
    child.kill("SIGKILL");
  }
}

/**
 * Run a command with a read-only host filesystem and a disposable writable
 * OverlayFS view of cwd. Network access is intentionally unchanged.
 */
export async function runReadonlyCommand(command, cwd, options = {}) {
  const absoluteCwd = resolve(cwd);
  if (/[,:]/.test(absoluteCwd)) {
    throw new Error("bash_readonly does not support working-directory paths containing ',' or ':'");
  }

  const sandboxRoot = await mkdtemp("/var/tmp/pi-bash-readonly-");
  const upper = join(sandboxRoot, "upper");
  const work = join(sandboxRoot, "work");
  const merged = join(sandboxRoot, "merged");
  const cache = join(sandboxRoot, "cache");

  await Promise.all([
    mkdir(upper),
    mkdir(work),
    mkdir(merged),
    mkdir(join(cache, "npm"), { recursive: true }),
    mkdir(join(cache, "pip"), { recursive: true }),
    mkdir(join(cache, "uv"), { recursive: true }),
  ]);

  const child = spawn(
    "unshare",
    [
      "--user",
      "--map-root-user",
      "--mount",
      "--fork",
      "--",
      "bash",
      "-ceu",
      SANDBOX_SCRIPT,
      "bash-readonly",
      absoluteCwd,
      upper,
      work,
      merged,
      cache,
      process.env.HOME ?? "/nonexistent",
      command,
    ],
    {
      cwd: absoluteCwd,
      detached: true,
      env: process.env,
      stdio: ["ignore", "pipe", "pipe"],
    },
  );

  let timedOut = false;
  let timeoutHandle;

  if (options.timeout !== undefined && options.timeout > 0) {
    timeoutHandle = setTimeout(() => {
      timedOut = true;
      killProcessGroup(child);
    }, options.timeout * 1000);
  }

  const onAbort = () => killProcessGroup(child);
  options.signal?.addEventListener("abort", onAbort, { once: true });

  try {
    return await new Promise((resolvePromise, reject) => {
      let settled = false;

      const fail = (error) => {
        if (settled) return;
        settled = true;
        reject(error);
      };

      child.stdout?.on("data", options.onData ?? (() => {}));
      child.stderr?.on("data", options.onData ?? (() => {}));
      child.on("error", fail);
      child.on("close", (code) => {
        if (settled) return;
        settled = true;

        if (options.signal?.aborted) {
          reject(new Error("aborted"));
        } else if (timedOut) {
          reject(new Error(`timeout:${options.timeout}`));
        } else {
          resolvePromise({ exitCode: code ?? 1 });
        }
      });
    });
  } finally {
    if (timeoutHandle) clearTimeout(timeoutHandle);
    options.signal?.removeEventListener("abort", onAbort);

    // OverlayFS leaves its internal work/work directory inaccessible after the
    // mount namespace exits, so restore traversal before removing the fixture.
    await chmod(join(work, "work"), 0o700).catch((error) => {
      if (error.code !== "ENOENT") throw error;
    });
    await rm(sandboxRoot, { recursive: true, force: true });
  }
}
