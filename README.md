# Smart Model Router for Claude Code

A `/smart` command that reads your request, classifies it, and hands it to the
**cheapest Claude model that can do it well** — so you only pay for a big model
when the task actually needs one. It always tells you **which model answered**.

Two layers do the saving:

1. The router itself runs on **Haiku** (cheap) — it just classifies and delegates.
2. The real work runs inside a specialist sub-agent whose model is **pinned** to
   the right tier. Expensive models are used only when the task earns them.

## Routing table

| Your task | Sub-agent | Model | Rel. cost* |
|---|---|---|---|
| Summaries, weekly digest, recap, TL;DR, "explain simply" | `summarizer` | **Haiku** | 1× |
| Simple question, one-line edit, rename, format, boilerplate | `quick` | **Haiku** | 1× |
| Build / add / write / refactor a feature, endpoint, migration | `implementer` | **Sonnet** | 2× |
| "Is this right?", verify, double-check, fact-check a diff | `reviewer` | **Sonnet** | 2× |
| Hard bug, crash, "why isn't this working", perf, security | `debugger` | **Opus** | 5× |

\* Rough per-token cost vs Haiku (Haiku $1/$5, Sonnet $2/$10, Opus $5/$25 per 1M
in/out). The model names (`opus`/`sonnet`/`haiku`) resolve to whatever models
your Claude Code is configured to use.

## Install

```bash
git clone <this-repo-url> claude-smart-router
cd claude-smart-router
./install.sh            # global: all your repos get /smart  (installs into ~/.claude)
# or
./install.sh --project  # just the current repo (installs into ./.claude)
```

Then open Claude Code and run `/reload-skills` (or start a new session) so the
command and agents are picked up.

## Use

```
/smart why is the channel limit still 10 after my change?   → Opus (debug)
/smart add a scope to Channel for active ones               → Sonnet (implement)
/smart is my fix to the channel limit correct?              → Sonnet (review)
/smart give me a weekly summary of my commits               → Haiku (summary)
/smart what does ApplicationController#current_user do?      → Haiku (quick)
```

Before answering, the router prints one line so you always know the model:

```
🧠 Routed as **DEBUG** → **Opus** (debugger) · max-cost
```

…and every answer ends with a badge, e.g. `— answered by Opus · debugger`.

## Customize

It's just Markdown — edit freely:

- **Change a model:** open `agents/<name>.md`, edit the `model:` line
  (`opus` / `sonnet` / `haiku`), re-run `./install.sh`.
- **Change behavior:** edit the agent's system prompt (the body below the `---`).
- **Add a category:** drop a new `agents/<thing>.md` with pinned model, then add
  a row for it in the classify table inside `commands/smart.md`.

Re-run `./install.sh` after any change to push it to your `~/.claude`.

## Uninstall (safe & surgical)

```bash
./uninstall.sh            # removes only this package's files from ~/.claude
./uninstall.sh --project  # ditto from ./.claude
```

It removes **only** the five agents and the `smart` command that `install.sh`
added (tracked via a `.smart-router-installed` receipt) and **never touches your
other agents or commands**. A file you customized after installing is kept by
default — add `--force` to remove it too. Empty directories we created are
cleaned up; directories that still hold your files are left alone.

## What's in here

```
agents/       debugger · implementer · reviewer · summarizer · quick
commands/     smart.md   (the router)
install.sh    copy into ~/.claude (or ./.claude), write a receipt
uninstall.sh  remove only our files, using the receipt
```
