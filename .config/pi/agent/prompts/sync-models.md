---
description: Refresh pi's model catalog and propose model-alias.json and enabledModels updates
---
Refresh the model catalog and reconcile `~/.config/pi/agent/model-alias.json` and `enabledModels` in `~/.config/pi/agent/settings.json` with it. Read ADR-0093 first; it owns the tier ordering rules.

1. `pi update --models`, then `pi --list-models` for the current catalog.
2. Dead entries: every alias target and `enabledModels` entry (except `alias/*`) must exist in the catalog. A dead alias target fails its whole chain, so list these first with a replacement when one is obvious.
3. New models: for providers already used in the config, list models that are not referenced anywhere. Skip ones that are previews, embeddings, or otherwise unsuitable for an agent; say why. Check the benchmark source in the alias `$comment` before placing one in a tier.
4. Show the proposed edits as a short list (entry, tier or list, reason) and wait for approval. Do not write anything before it.
5. After approval, record the catalog as seen so the startup warning stops repeating: `pi --list-models | tail -n +2 | grep -v '^alias ' | tr -s ' ' | cut -d' ' -f1,2 | tr ' ' '/' | sort > ~/.config/pi/agent/state/models-seen.txt`. Do this even if you declined every new model.
6. Also after approval, edit both files, update the `$comment` read date and scores if you used new ones, and rerun `pi --list-models` to confirm every target resolves.
