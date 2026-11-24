import type { Register } from 'claude-code'

// Port of pi's session-name.ts tab rename: one cheap call on the first prompt, never over a hand-set name.
const INSTRUCTION =
  'Name an AI prompting session from the message below. Reply with one plain-text line and nothing else: ' +
  'the single lowercase word a human would scan for in a tab bar, hyphenated only if one word will not do ' +
  '(e.g. permissions, auth, backups).\n\nMessage:\n'

const MAX_PROMPT_CHARS = 500
const MAX_LABEL_CHARS = 24

const slug = (line: string) =>
  line
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, MAX_LABEL_CHARS)

export const register: Register = on => {
  let isNamed = false

  on('prompt.submit', async ($, e, next) => {
    const ran = await next(e)
    if (isNamed || e.command || !e.text.trim()) return ran
    isNamed = true

    const tabId = await $.env.get('HERDR_TAB_ID')
    if (!tabId) return ran

    // Fire and forget: the prompt never waits on the title call.
    void (async () => {
      const got = await $.process.run(['herdr', 'tab', 'get', tabId], { timeoutMs: 3000 })
      if (got.exitCode !== 0) return
      const label: string = JSON.parse(got.stdout)?.result?.tab?.label ?? ''
      if (!/^\d*$/.test(label)) return

      const named = await $.model.complete({
        model: 'haiku',
        prompt: INSTRUCTION + e.text.slice(0, MAX_PROMPT_CHARS),
        effort: 'low',
      })
      if (!named.isAnswered) return
      const word = slug(named.text.trim().split('\n')[0] ?? '')
      if (!word) return

      await $.process.run(['herdr', 'tab', 'rename', tabId, word], { timeoutMs: 3000 })
    })().catch(() => {})

    return ran
  })
}
