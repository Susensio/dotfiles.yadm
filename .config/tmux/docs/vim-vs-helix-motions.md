# Vim vs Helix: two editing grammars

This document exists to give an unambiguous, source-backed reference for the two motion paradigms that `conf.d/21_copy.conf`'s `@copy_profile` switch is trying to emulate in tmux copy-mode.
It's the shared ground truth for (a) building a copy-mode config from scratch and (b) auditing the existing one for paradigm leakage — keys from one model behaving like the other.

Sources: Vim/Neovim's own `runtime/doc/*.txt`, and Helix's own `docs/vision.md`, `book/src/textobjects.md`, `docs.helix-editor.com`, and project wiki/FAQ.
URLs are inlined per claim.

## The one-sentence difference

- **Vim: verb → noun.**
  You press an operator (the verb), which puts you in a pending state, then a motion or text object (the noun) that supplies the range.
  The action and the range are two separate keystrokes composed together; nothing happens until the noun arrives.
- **Helix: noun → verb.**
  A selection (possibly zero-width, i.e. a bare cursor) always exists first.
  Movement commands change what's selected.
  Actions (`d`, `y`, `c`, ...) act *immediately* on whatever is currently selected — there's no pending state to complete.

Helix's own design doc states this directly:

> "Selection → Action, not Verb → Object.
> Interaction models aren't linguistics, and 'selection first' lets you see what you're doing (among other benefits)."
> — [`docs/vision.md`](https://github.com/helix-editor/helix/blob/master/docs/vision.md)

And its FAQ is explicit that this is a permanent design choice, not a gap:

> "We are not interested in supporting alternative paradigms.
> The core of Helix's editing is based on `Selection → Action`, and it would require extensive changes to create a true Vi/Vim keymap."
> — [Helix wiki FAQ](https://github.com/helix-editor/helix/wiki/FAQ)

Vim's manual describes the mirror-image idea — operator and motion as independently reusable primitives that multiply combinatorially:

> "The operators, movement commands and text objects give you the possibility to make lots of combinations.
> [...] you can use N operators with M movement commands to make N * M commands!"
> — [`usr_04.txt`](https://github.com/vim/vim/blob/master/runtime/doc/usr_04.txt)

## Vim: verb-then-motion (operator-pending)

### Grammar

```
{count}{operator}{motion}          e.g. 2dw
{operator}{count}{motion}          e.g. d2w
{count}{operator}{count}{motion}   e.g. 2d3w   (counts multiply: deletes 6 words)
```

A **doubled operator** (`dd`, `yy`, `cc`, `gUU`, `>>`, `==`, ...) is shorthand for "apply to the current line(s)" — a count still works (`3dd` = delete 3 lines).
This is the *only* place vim implicitly picks a range without an explicit motion/text-object keystroke.

Source: [`change.txt`](https://github.com/vim/vim/blob/master/runtime/doc/change.txt), [`usr_04.txt`](https://github.com/vim/vim/blob/master/runtime/doc/usr_04.txt)

### Motions (the "noun" half)

Motions carry a **charwise vs. linewise vs. blockwise** type, and (for charwise) an **inclusive vs. exclusive** endpoint — this determines whether the character under the destination cursor is included in the operator's range.

| Motion | Type | Endpoint | Meaning |
|---|---|---|---|
| `w` / `W` | charwise | exclusive | start of next word / WORD |
| `b` / `B` | charwise | exclusive | start of previous word / WORD |
| `e` / `E` | charwise | inclusive | end of current/next word / WORD |
| `ge` | charwise | inclusive | end of previous word |
| `0` | charwise | exclusive | column 1 |
| `^` | charwise | exclusive | first non-blank |
| `$` | charwise | inclusive | end of line |
| `f{c}` / `t{c}` | charwise | inclusive | to / till char, forward |
| `F{c}` / `T{c}` | charwise | exclusive | to / till char, backward |
| `%` | charwise | inclusive | matching bracket |
| `{` / `}` | charwise | exclusive | previous/next paragraph |
| `gg` / `G` | linewise | — | first line / line N (default last) |

Special case: an exclusive motion that lands in column 1 of a line gets bumped back to end-of-previous-line (and, if it also started at/before the first non-blank, the whole thing becomes linewise).
This is why `dw` at the end of a line doesn't eat the newline character the way you'd naively expect from "exclusive."

Source: [`motion.txt`](https://github.com/vim/vim/blob/master/runtime/doc/motion.txt)

### Operators (the "verb" half)

| Operator | Action | Doubled = whole line |
|---|---|---|
| `d` | delete | `dd` |
| `y` | yank | `yy` |
| `c` | change (delete, enter insert) | `cc` |
| `gu` / `gU` / `g~` | lower / upper / toggle case | `guu` / `gUU` / `g~~` |
| `>` / `<` | indent right / left | `>>` / `<<` |
| `=` | reindent | `==` |
| `gq` / `gw` | format (move / keep cursor) | `gqq` / `gww` |
| `!` | filter through external command | (rare) |
| `g@` | call `operatorfunc` (plugin hook) | user-defined |

Every deleting/yanking operator can target a register: `"ayy`, `"add`.

Source: [`index.txt`](https://github.com/vim/vim/blob/master/runtime/doc/index.txt)

### Text objects — `i`/`a` as a special class of "noun"

Text objects slot into the motion position, but describe a *structural* range rather than a cursor destination — there's no independent cursor movement, just "the object here."

- **`i` (inner)** — the object's contents only.
- **`a` (around)** — the object plus its delimiter and, for word/sentence objects, trailing whitespace.

| Object | `i` | `a` |
|---|---|---|
| `iw` / `aw` | inner word | word + trailing space |
| `iW` / `aW` | inner WORD | WORD + trailing space |
| `i"` `i'` `` i` `` | inside quotes | quotes included |
| `i(`/`ib` `i[` `i{`/`iB` `i<` | inside bracket pair | bracket pair included |
| `ip` / `ap` | paragraph | paragraph + trailing blank line |
| `is` / `as` | sentence | sentence + trailing space |
| `it` / `at` | tag contents | tag contents + the tags |

Composition examples: `diw` (delete inner word), `caw` (change a word + space), `yip` (yank inside paragraph), `gUaw` (uppercase a word).

Source: [`index.txt`](https://github.com/vim/vim/blob/master/runtime/doc/index.txt)

### Visual mode — the alternative entry point

`v` (charwise), `V` (linewise), `Ctrl-v` (blockwise) select a range *first*, then any operator key applies to it — e.g. `vwd` ≈ `dw`, `vapY` ≈ `yap`.
This looks superficially like Helix's model, but it's a secondary path bolted onto the same operator set, not the primary grammar: operator-pending is still how most vim users compose most commands, and Visual mode has its own extra behavior (blockwise insert/append with `I`/`A`, `gv` to reselect the last visual range) that doesn't exist in operator-pending at all.

An operator can also force a different motion-type via `v`/`V`/`Ctrl-v` immediately after it: `dvj` forces the normally-linewise `j` to act charwise.

Source: [`visual.txt`](https://raw.githubusercontent.com/vim/vim/master/runtime/doc/visual.txt), [`motion.txt`](https://github.com/vim/vim/blob/master/runtime/doc/motion.txt)

## Helix: selection-first (select-then-act)

### The core mechanic

A cursor **is** a zero-width selection — there's no separate "cursor mode" vs "selection mode" at the data-model level, just selections of size ≥ 0.
Movement keys don't just move the cursor, they **replace the selection** with the span just moved over; actions consume whatever selection currently exists, synchronously, with no pending state:

> "In helix, there is no waiting around; a `d` immediately deletes whatever text is selected."

Source: [`docs.helix-editor.com/keymap.html`](https://docs.helix-editor.com/keymap.html), [`docs.helix-editor.com/usage.html`](https://docs.helix-editor.com/usage.html)

### Movement = selection

| Key | Effect |
|---|---|
| `h` `l` | move left/right by character (zero-width) |
| `j` `k` | move by **visual** (soft-wrapped) line — use `gj`/`gk` for logical lines |
| `w` / `W` | select from cursor to next word / WORD start |
| `b` / `B` | select from cursor to previous word / WORD start |
| `e` / `E` | select from cursor to next word / WORD end |
| `x` | select current line; repeat to extend to next line |
| `X` | extend selection to full line bounds |

The crucial point: `w`/`b`/`e` in Helix **select the span traversed**, not just relocate a cursor the way vim's `w`/`b`/`e` do as bare motions.
This is what makes them usable as the "noun" *and* leaves something for `d`/`y`/`c` to act on without an explicit text object — e.g. `wd` deletes the word just selected, `ed` (end-of-word) deletes the rest of the current word.

Source: [`docs.helix-editor.com/keymap.html`](https://docs.helix-editor.com/keymap.html), [FAQ (j/k rationale)](https://github.com/helix-editor/helix/wiki/FAQ), [discussion #10458](https://github.com/helix-editor/helix/discussions/10458)

### Select (extend) mode — `v`

`v` toggles a persistent mode where subsequent movement keys **extend** the current selection instead of replacing it, until toggled off.
This is conceptually different from vim's Visual mode: vim's `v` opens a scoped "selecting right now" state that a following operator closes; Helix's `v` just changes what movement keys *do* to the selection that always exists — you can toggle it off and the selection persists into normal mode.

> "Select (extend) mode echoes Normal mode, but changes any movements to extend selections rather than replace them."

Source: [`docs.helix-editor.com/keymap.html`](https://docs.helix-editor.com/keymap.html), [`from-vim.html`](https://docs.helix-editor.com/from-vim.html)

### Actions

| Key | Effect |
|---|---|
| `d` | delete selection |
| `c` | delete selection, enter insert mode |
| `y` | yank selection |
| `r` | replace selection with one typed character |
| `Alt-d` / `Alt-c` | delete/change without touching the yank register |

No motion argument is ever supplied to these — by the time you press them, the selection already says what they apply to.

### Match mode — `m`, Helix's rough analogue of vim's text objects

`m` is a prefix key (its own mode), not an operator:

| Combo | Effect |
|---|---|
| `mm` | jump to matching bracket |
| `mi<obj>` | select **inside** object (interior only) |
| `ma<obj>` | select **around** object (interior + delimiters) |
| `ms<char>` | surround current selection with `<char>` |
| `mr<from><to>` | replace surround char |
| `md<char>` | delete surround char |

Objects for `mi`/`ma`: `w` word, `W` WORD, `p` paragraph, bracket/quote pairs, `m` closest surrounding pair — plus tree-sitter-powered ones (`f` function, `t` type, `a` argument, `c` comment, ...) not available without a grammar installed.

The structural difference from vim: `mi`/`ma` **select** the object as a standalone step; a following action key is a separate keystroke that acts on the now-current selection (`miw` then `d`, i.e. `miwd`), rather than the object being consumed directly as an operator's argument (`diw`) in one compound command.

Source: [`textobjects.md`](https://github.com/helix-editor/helix/blob/master/book/src/textobjects.md), [`docs.helix-editor.com/keymap.html`](https://docs.helix-editor.com/keymap.html)

### Multiple selections (context, not the focus here)

`C` / `Alt-C` add a cursor on the next/previous line; `s` splits the current selection into one selection per regex match within it; `,` collapses back to one.
Actions apply to every active selection at once.
Mentioned for completeness — tmux copy-mode has no multi-cursor concept, so this doesn't map onto anything in `21_copy.conf`.

Source: [`docs.helix-editor.com/keymap.html`](https://docs.helix-editor.com/keymap.html)

## Side-by-side: same intent, different grammar

| Intent | Vim | Helix |
|---|---|---|
| Delete a word | `dw` (or `daw` for the "clean" version) | `wd` (word already selects the span) |
| Delete inside quotes | `di"` | `mi"d` |
| Change around parens | `cab` | `mabc` |
| Yank a paragraph | `yip` | `mipy` |
| Select then act, explicitly | `v` + motion + operator | *(always the default state)* |
| Extend a selection across multiple movements | `v` then keep moving, operator at the end | `v` (toggles extend mode) then keep moving, action at the end |

## What this means for `21_copy.conf`

- Anything that makes Helix's `w`/`b`/`e`/`y` **wait for a second key** before acting is vim leakage — in real Helix these either select immediately (`w`/`b`/`e`) or act immediately on the existing selection (`y`/`d`/`c`).
- Anything that makes vim's `i`/`a` reachable **without** a preceding operator, or that lets Helix reach the vim-only `yank`/block-selection machinery, is grammar leakage the other way — vim's text objects are only ever an operator's argument, never a standalone action.
- `m` in the Helix profile should require a selection already being active before it does anything (matches real Helix: `mi`/`ma` narrow an existing/default selection, they don't manufacture one from nothing the way vim's `di`/`da` implicitly do by starting from a zero-width cursor).
