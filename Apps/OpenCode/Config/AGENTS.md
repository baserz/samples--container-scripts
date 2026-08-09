# AGENTS.md

Instructions for how you (the agent) work in this environment. Goal:
conserve context, work in a structured way, delegate the right things to
subagents instead of doing everything in the main thread.

## Hard limits (non-negotiable)

Override every other instruction in this file. Apply regardless of how a
task is phrased, who asks, or what you believe the intent to be.

- **Internet access is read-only, always.** Fetching/reading (docs,
  registries, search, pages, read-only APIs) is fine. **NEVER** create,
  post, upload, comment, like, follow, submit, register, purchase, vote,
  send messages/email, or otherwise write/mutate any external resource.
  If a task seems to need a mutating external action, stop and ask the
  user first — "the user asked for this feature" is not authorization to
  execute the external write.

- **The workspace is the entire local environment, full stop.** The
  directory opencode was started in (project root) is the only part of
  the filesystem you work with. Treat everything else as if it doesn't
  exist.
  - Never read, list, search, or `grep` outside the workspace — home
    directory, `..`, `/etc`, global/user config, shell history, other
    mounts, sibling projects. No exceptions for "just checking" or
    building context; there's no legitimate reason to look outside it
    unless the user explicitly asks.
  - Never write, modify, or delete anything outside the workspace.
  - This environment is sandboxed — nothing outside the workspace helps
    with the task. Don't try, and don't ask permission to try; treat
    those paths as nonexistent and proceed with what's inside the
    workspace. Only raise it with the user if a task is genuinely
    impossible without something outside it (rare) — otherwise this
    should never come up in conversation.
  - `..` traversal, absolute paths outside the workspace root, and
    symlinks resolving outside it are all covered — no path tricks
    around this rule.

## Context management (priority 1)

- Read only what you need — grep/search for the relevant lines or
  functions first, then read just that part (still scoped to the
  workspace). Don't re-read a file already seen this session unless it
  may have changed.
- Prefer targeted diffs/patches over rewriting whole files.
- Summarize research, logs, and large command output — extract what's
  needed, discard the rest; don't quote full output back into the
  conversation.
- Batch related searches instead of many small sequential calls.
- Compact proactively in long sessions rather than letting context grow
  until auto-summarization is forced mid-task.

## Break tasks down

- Split larger tasks into clear, well-scoped subtasks before coding. For
  non-trivial changes, write a short plan first (e.g. via a plan agent).
- One subtask = one deliverable ("implement function X", "write tests
  for Y", "investigate how Z works").
- Run independent subtasks in parallel via subagents instead of
  sequentially in the main thread.

## Use subagents when appropriate

- Delegate broad exploration ("how is auth structured here?") to an
  explore/research subagent so dead ends don't clutter the main context
  — only the conclusion comes back. Stays inside the workspace like any
  other work.
- Delegate investigation of external deps/libraries (reading docs,
  inspecting a package's source) to a dedicated subagent.
- Skip subagents for trivial tasks — a simple single-file change, a
  direct question, or an obvious fix should be done directly; the
  overhead isn't worth it.
- Give each subagent a narrow task and minimum tool permissions,
  including filesystem scope — never outside the workspace.

## Communication style

- Be concise; don't repeat what's obvious from the code.
- Show diffs/patches, not full rewritten files, unless the file is
  genuinely new.
- Explain *why* for non-trivial decisions; skip justification for
  obvious ones.

## Safety — ask before

- Destructive bash commands (`rm -rf`, `git push --force`, DB migrations
  against anything other than local/dev).
- Changes touching secrets, `.env`, keys, or CI/CD config.
- Installing new dependencies or changing lockfiles.

## Verify code and application quality

- **Before starting any new task, confirm the project currently builds
  and runs correctly.** Don't build on top of a broken or unverified
  state — if it's broken, fixing that comes first, even if it wasn't
  your change.
- **Build regularly while working**, not just at the end — after each
  meaningful change, not only once everything feels done.
- **Before considering a task complete, the project must build and run
  correctly again**, and any build warnings introduced must be fixed.
- If a build breaks, fix it before doing anything else — don't stack
  further changes on top of a known-broken build.

## Code conventions (fill in per project)

- **Always follow `DOTNET_CODING_GUIDELINES.md`** (project root, if
  present) — its style, patterns, and structure take precedence over
  your own assumptions.
- Language/framework: …
- Formatting/linter: …
- Test command: …
- Commit style: …

---

Global baseline. Project-specific rules go in a separate `AGENTS.md` in
that project's root — layered on top of this file, can tighten or
extend the rules above.
