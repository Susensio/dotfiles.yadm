---
name: coding
description: Guides minimal implementation, debugging, and verification. Use when reading, changing, or reviewing code, or when a test, lint, build, or type check fails.
---

# Coding

Search before writing. Prefer deleting, reusing an existing solution, or using a maintained dependency over adding another local mechanism. Add only what the request needs.

## Change code

- Keep data flow explicit and control flow flat.
- Let unexpected errors surface; catch only errors that can be handled.
- Preserve the project's interfaces and conventions unless changing them is part of the request.
- Comment only constraints or workarounds the code cannot express.

## Diagnose failures

1. Reproduce the smallest failing case.
2. State a root-cause claim supported by the code path, error, or log.
3. Change that mechanism without weakening the check that exposed it.
4. Rerun the focused failure, then the broader checks its impact justifies.

## Finish

Use the repository's declared format, lint, type-check, build, and test commands.
Scale verification to what could plausibly break.
Verify behavioural changes through the project's public interface when practical; verify prose-only changes from the rendered result or diff.

When verification could attach to or mutate a user's live server, session, database, or working tree, use a disposable fixture and clean it up on every exit path.
If the check cannot be isolated, stop and report what live access would be required instead of running it.

Report any check that could not run.
