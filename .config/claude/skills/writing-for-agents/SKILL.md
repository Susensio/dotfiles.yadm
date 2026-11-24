---
name: writing-for-agents
description: Use when writing or editing a skill, agent, rule or CLAUDE.md, or when a document is too long, vague or ignored. Covers description vs body, ranking, leading words, and what to cut.
user-invocable: false
---

Reference for writing any document an agent consumes: a skill, a `CLAUDE.md`, a doc reached by a pointer.
The packaging differs; the writing does not: the same levers make each one predictable, since the agent takes the same _process_ every run rather than producing the same output.

When deciding which slot a piece of content belongs in (agent vs skill vs path-scoped rule vs context file), consult the `harness-design` skill first.
When the document is a skill, read [`SKILL-MECHANICS.md`](SKILL-MECHANICS.md) for frontmatter, invocation choice, and router skills.

## Context pointers

A **context pointer** is a reference held in the agent's context that names out-of-context material and encodes the condition for reaching it.
A skill's `description:` is one; a line in `CLAUDE.md` naming a doc is the same object.
The pointer's _wording_, not its target, decides when and how reliably the agent reaches the material.
A must-have target behind a weakly worded pointer is a variance bug: sharpen the wording first, and inline the material only if sharpening fails.

A pointer states what the material is and lists the **branches** that should trigger reaching it (a branch is a distinct case the document handles).
Every word of an always-loaded pointer costs on every turn:

- **Front-load the leading word.**
- **One trigger per branch.** Synonyms renaming a single branch are one branch written twice.
- **Cut identity the body already carries.**

## The two loads

- **Context load** is the cost of always-loaded material on the agent's window: a `CLAUDE.md` line, a skill description, spending tokens whether or not it fires.
- **Cognitive load** is the cost on the human: which documents exist and when to reach for each.
  The human is the index.
  It is the price of human agency, spent where human judgement matters.

Material reached only through a pointer escapes context load at the price of the pointer's line; material with no pointer rides entirely on cognitive load.

## Information hierarchy

A document is built from **steps** (ordered actions) and **reference** (definitions, rules, facts consulted on demand), mixed freely.
Each piece sits on a ladder ranked by how immediately the agent needs it:

1. **In-file step**: what the agent does, in order.
2. **In-file reference**: consulted on demand.
   Often a flat peer-set (every rule of a review on one rung), which is fine.
3. **Disclosed reference**: a separate file, reached by a context pointer, loaded only when it fires.

Push too little down and the top bloats; push too much and you hide material the agent needs.

**Progressive disclosure** is the move down the ladder so the top stays legible; it protects the hierarchy more than it saves tokens.
Branching is the cleanest test: inline what every branch needs, and push behind a pointer what only some branches reach.
In-file reference that should be disclosed buries the steps and makes attending to them a coin-flip.

**Co-location** is the within-file companion: keep a concept's definition, rules and caveats under one heading, so reading one part brings its neighbours.
Distinct from duplication, which repeats one meaning in two places; scattering fragments one meaning across many.

**Sprawl** is a document simply too long, even when every line is live and unique: attention thins across the excess.
The cure is the ladder: disclose reference behind pointers, and split by branch or sequence so each path carries only what it needs.

## Steps and completion criteria

Every step ends on a **completion criterion**, the condition telling the agent the work is done:

- **Clarity**: can the agent tell done from not-done?
  A vague bound ("understanding reached") invites **premature completion**, attention slipping to _being done_ because the visible post-completion steps pull.
  **Sharpen the bound first**; only if it is irreducibly fuzzy _and_ you observe the rush, hide the later steps by splitting the sequence.
  Hiding works only across a real context boundary (a hand-off or subagent dispatch).
- **Demand**: how much it requires.
  "Every modified model accounted for" forces thorough work where "produce a change list" does not.
  Demand drives **legwork** and is not step-bound: "every rule applied" binds flat reference just as "every step done" binds a sequence.

The strongest criteria are both checkable and exhaustive.

## When to split

Split only when the cut earns it:

- **By sequence**: split a run of steps where the post-completion steps tempt the agent to rush the one in front of it.
  Merging sequences exposes each step's later steps to what follows.
- **By invocation**, skill-specific: see [`SKILL-MECHANICS.md`](SKILL-MECHANICS.md).

## Leading words

A **leading word** is a compact concept already in the model's pretraining that the agent thinks with while running the document (_lesson_, _fog of war_, _tracer bullets_).
Repeated as a token, never as a sentence, it anchors a whole region of behaviour in the fewest tokens by recruiting priors the model already holds.
A made-up word recruits none: reach for an existing word first.

It anchors twice: in the body, _execution_ (the same behaviour each time the word appears); in a pointer, _invocation_ (the shared word across prompts, docs and codebase links to the material).

Hunt for restatements a leading word retires -- a triad spelled out at three sites, a pointer spending a sentence on one idea:

- "fast, deterministic, low-overhead" → _tight_ (a _tight_ loop).
- "a loop you believe in" → _red_, a fuzzy gate turned into a binary observable state.

**Negation** is the failure mode beside this lever: steering by prohibition drags the forbidden behaviour into context and makes it _more_ available.
Prompt the **positive**: state the target behaviour ("write one-line comments") so the banned one is never spoken.
A prohibition earns its place only as a hard guardrail you cannot phrase positively, and then paired with the positive target.

## Naming tools

A tool name is a literal from the runtime, so it carries backticks every time it appears in prose: `Bash`, `Write`, `Agent`.
Without them `Read` the tool and _read_ the verb are one token doing two jobs.
Frontmatter is exempt: `tools: Bash, Read, Skill` is a list of values.

## Pruning

- Keep each meaning in a **single source of truth**, so changing behaviour is a one-place edit.
  **Duplication** costs maintenance and tokens, and inflates a meaning's prominence past its rank.
  (A leading word repeats a token on purpose, never the meaning.)
- The **environment** is a source of truth too (`package.json` scripts, config files, directory layout, `--help` output); a document restating it is a **cache**, earning its load only when the lookup is expensive.
  Cache what the agent cannot find by looking: the unwritten convention, the reason behind a choice, the gotcha no config confesses.
- Check every line for **relevance**: a line loses it by never bearing on the task (exposition, or a branch that should be disclosed) or by going stale.
  Without a pruning discipline the default fate is **sediment**: stale layers settling because adding feels safe and removing feels risky.
- Hunt **no-ops** sentence by sentence: an instruction the model already obeys by default pays load to say nothing.
  The test (does it change behaviour versus the default?) is model-relative; settle disagreement by running the document.
  When a sentence fails, delete the whole sentence rather than trimming words.
  A leading word too weak to beat the default (_be thorough_) is a no-op too; the fix is a stronger word (_relentless_).
