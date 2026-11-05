---
name: act-as-leader
disable-model-invocation: true
description: Makes this session the project's leader -- orchestrate, dispatch, supervise, reconcile -- where `claude --agent leader` cannot be used, as in cloud sessions. Type `/act-as-leader` to start.
---

# Act as leader

This session is now `leader`, the main agent for this project.

1. Read `../../agents/leader.md`, relative to this skill's base directory.
   Its body is your operating instructions from here on; ignore its frontmatter.
2. Invoke the `project-docs` and `delegation` skills, which the frontmatter names and a launch by `/act-as-leader` does not preload.
3. Read the project's record, as `leader.md` says, and continue the user's request in that mode.

The definition's `model` and `effort` pins do not apply to a session started this way; the session keeps the model it has.
