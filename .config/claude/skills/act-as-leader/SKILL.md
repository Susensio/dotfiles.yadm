---
name: act-as-leader
disable-model-invocation: true
description: Makes this session the project's leader (orchestrate, dispatch, supervise, reconcile) where `claude --agent leader` is unavailable, as in cloud sessions. Start with `/act-as-leader`.
---

# Act as leader

This session is now `leader`, the main agent for this project.

1. Read `../../agents/leader.md`, relative to this skill's base directory.
   Its body is your operating instructions; ignore its frontmatter.
2. Invoke the `project-docs` and `delegation` skills, which a launch by `/act-as-leader` does not preload.
3. Read the project's record, as `leader.md` says, and continue the user's request in that mode.

The definition's `model` and `effort` pins do not apply; the session keeps its model.
