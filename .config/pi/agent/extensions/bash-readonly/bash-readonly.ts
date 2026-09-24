import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { createBashTool, type BashOperations } from "@earendil-works/pi-coding-agent";
import { runReadonlyCommand } from "./runner.mjs";

function createReadonlyOperations(): BashOperations {
  return {
    exec(command, cwd, options) {
      return runReadonlyCommand(command, cwd, options);
    },
  };
}

export default function (pi: ExtensionAPI) {
  const bashTool = createBashTool(process.cwd(), {
    operations: createReadonlyOperations(),
    exposeSessionEnvironment: false,
  });

  pi.registerTool({
    ...bashTool,
    name: "bash_readonly",
    label: "Bash (read-only host)",
    description:
      "Run a Bash command with the host filesystem mounted read-only. The current project, /tmp, and common caches are writable only in disposable per-command state. Project writes disappear when the command exits. Network access is not restricted.",
    promptSnippet: "Run shell commands without persisting filesystem changes",
    promptGuidelines: [
      "Use bash_readonly for command-line inspection and checks when host filesystem changes must not persist.",
    ],
    async execute(id, params, signal, onUpdate) {
      return bashTool.execute(id, params, signal, onUpdate);
    },
  });
}
