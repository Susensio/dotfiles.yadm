---
description: Refresh pi's model catalog and propose model-alias.json and enabledModels updates
---
Refresh the model catalog and reconcile `~/.config/pi/agent/model-alias.json` and `enabledModels` in `~/.config/pi/agent/settings.json` with it. Read ADR-0103 first; it owns the rung ordering rules, and ADR-0118 owns the quota arithmetic.

1. `pi update --models`, then `pi --list-models` for the current catalog.
2. Run `~/.config/pi/agent/bin/pi-model-cost` (add `--all` if a new Go model needs pricing) and read the table before proposing anything: the live multipliers, 5h drain and IPD override any prices or scores frozen in the `$comment`, which the last sync recorded and only that sync verified. If an `intel` cell is `n/a`, the site has not scored the model: do not guess a score, and weigh it only on drain and evidence. Record the index version line with any score you use.
3. Dead entries: every alias target and `enabledModels` entry (except `alias/*`) must exist in the catalog. A dead alias target fails its whole chain, so list these first with a replacement when one is obvious.
4. New models: for providers already used in the config, list models that are not referenced anywhere. Skip ones that are previews, embeddings, or otherwise unsuitable for an agent; say why. Place one in a tier only using the script's drain/IPD and the benchmark source in the alias `$comment`.
5. Show the proposed edits as a short list (entry, tier or list, reason, and the drain/IPD behind it) and wait for approval. Do not write anything before it.
6. After approval, record the catalog as seen so the startup warning stops repeating: `pi --list-models | tail -n +2 | grep -v '^alias ' | tr -s ' ' | cut -d' ' -f1,2 | tr ' ' '/' | sort > ~/.config/pi/agent/state/models-seen.txt`. Do this even if you declined every new model.
7. Also after approval, edit both files, update the `$comment` read date and scores if you used new ones, and rerun `pi --list-models` to confirm every target resolves.
