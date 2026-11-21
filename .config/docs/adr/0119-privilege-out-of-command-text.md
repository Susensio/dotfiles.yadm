# ADR-0119: Keep agent privilege out of command text: a positional rule, a human-elevated TTY for remote root, and prose-safe reviewer policy, instead of a mid-string deny or glob-matched transports

Status: Accepted
Date: 2026-11-21

## Context

The Pi permission system judged a bash call by matching its text against glob rules, so every statement about privilege had to be written as a pattern.
An agent driving a tmux pane that was SSH'd into a remote machine could not run privileged commands there: ADR-0071's `sudo *` and `* sudo *` denies fired on the payloads it typed.
That pair of rules failed in both directions.
`* sudo *` matched the word anywhere it sat between spaces, so it denied commit messages and ADR titles that merely mentioned it, and it denied `…; sudo …` and `… && sudo …`; it did not match `"sudo …"` or `'sudo …'` at all, because the character before the verb was a quote.
The gaps were not a tuning problem: the matcher has no word boundaries, and the verb's position in free text is not what decides whether it runs.
Three alternatives were weighed.
Ranking every transport by glob (`tmux send-keys*sudo*`, `ssh *sudo*`) reproduced the same false positives and misses one level up, and pinned the policy to whatever spelling the agent happened to use.
`run0` on the remote host would have been the systemd-native sibling of the local pkexec path, but its reusable authorization (`--validate`) arrived in systemd 262 and the target ran Debian 13's 257, and a headless SSH session usually has no polkit agent to carry the prompt.
A bounded wrapper installed on each target (`pi-root` plus a NOPASSWD entry) bound root to a reviewed verb list, but required an artifact per machine, which is what the operator wanted to avoid.

## Decision

Privilege is a property of the process, not of the command's spelling, so the policy no longer reads privilege out of free text.

- One positional rule remains: `sudo *` denies a command whose own first word is the verb. A pattern anchored at the start cannot misfire on prose, and a command led by the verb is exactly the case ADR-0071 describes, where the prompt has no terminal to appear on.
- The mid-string `* sudo *` rule was removed. It was the pattern that produced the prose denials and the quote-dependent misses, and a rule that must guess at word boundaries cannot be made reliable.
- Local root stays on pkexec, asked and routed to the operator by the always-ask link, as ADR-0071 decided.
- Remote root happens in a TTY the operator elevates: `ssh -t host sudo -i` (or `sudo -i` in the pane they are watching). The agent then types ordinary commands into that session, so its text carries no privilege verb and no rule has to interpret one. This is target-agnostic by construction: any host with sshd and a shell, no artifact installed, nothing named per machine.
- Every remaining spelling - a verb inside `bash -c`, `eval`, a substitution, or behind `env`/`xargs`/`nohup`/`timeout` - is left to the automatic reviewer's written `hard_deny` policy, which names privilege escalation as an execution, not a word, and states that a verb appearing only as prose (a commit message, an ADR title, a filename, a search pattern) is not a denial.

## Consequences

Privileged remote work costs the operator one elevation per session rather than one confirmation per command, and the agent keeps working unimpeded inside that session.
Commands whose text mentions the verb for other reasons - commits, document writes, `grep` patterns - stopped being denied, which is what made writing an ADR that discusses privilege possible at all.

A privilege call hidden in a shell now reaches the automatic reviewer rather than a deterministic deny.
The reviewer's `hard_deny` is written to fail closed there, and an unavailable reviewer already denies, but a misjudging reviewer could allow one; that is a weaker guarantee than a rule, accepted because the alternative was a rule that also blocked the prose.

Remote privileged work depends on the operator opening the elevated session; an agent that needs root on a fresh machine has to ask for that session rather than escalate on its own.
What the agent types into an elevated pane is not parsed by any gate - the payload of `tmux send-keys` is an opaque argument - so that channel remains trusted-by-human-watching rather than mediated, which is the hole this record accepts alongside ADR-0071 rather than closing.

