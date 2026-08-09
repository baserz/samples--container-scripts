# AGENTS.md

General instructions for how you (the agent) should work in this
environment. The goal is to conserve context window, work in a structured
way, and delegate the right things to subagents instead of doing everything
in the main thread.

## Hard limits (non-negotiable)

These override every other instruction in this file, including the
context-efficiency and subagent guidance below. They apply regardless of
how a task is phrased, who asks, or what the agent believes the intent to
be.

- **Internet access is read-only, always.** The agent may fetch and read
  information from the internet (documentation, package registries, search
  results, web pages, APIs used purely to retrieve data). The agent must
  **NEVER** create, post, upload, comment, like, follow, submit, register,
  purchase, vote, send messages/email, or otherwise add or modify any
  resource on the internet. If a task appears to require any write/mutating
  action against an external service, stop and ask the user first — do not
  perform it automatically, and do not treat "the user asked for this
  feature" as authorization to actually execute the external write.

- **The workspace is the entire local environment, full stop.** The
  directory opencode was started in (the project root) is the only part
  of the local filesystem you work with. Treat it as if nothing else on
  disk exists.
  - **Never read, list, search, or `grep` outside the workspace** —
    this includes the home directory, parent directories (`..`), `/etc`,
    global or user-level config, shell history, other mounted paths, or
    any sibling project directories. This applies even for "just
    checking", "just looking for context", or building a mental model of
    the system — there is no legitimate reason to look outside the
    workspace unless the user explicitly asks you to.
  - **Never write, modify, or delete anything outside the workspace** —
    same scope as above.
  - This environment is sandboxed — nothing outside the workspace is part
    of the task, and looking there will not help. Don't try, and don't
    ask permission to try; just treat those paths as if they don't exist
    and proceed with what's inside the workspace. Only raise it with the
    user if the task is genuinely impossible without something outside
    the workspace (rare) — otherwise this should never come up in
    conversation at all.
  - `..` traversal, absolute paths outside the workspace root, and
    symlinks that resolve outside the workspace are all covered by this
    rule — don't use path tricks to route around it.

## Context management (priority 1)

- **Only read what you actually need.** Don't open entire files "just in
  case" — search/grep for the relevant lines or functions first, then read
  only that part. This search is still scoped to the workspace — see the
  hard limit above.
- **Avoid re-reading a file** you've already seen in this session unless it
  may have changed. Keep track of what you've already looked at.
- **Prefer targeted edits (diff/patch) over rewriting whole files.** Pasting
  an entire file into context for a one-line change is wasteful.
- **Summarize instead of storing raw output.** After research, log excerpts,
  or large command output: extract only what's actually needed and discard
  the rest — don't quote the full output back into the conversation.
- **Batch related searches** instead of many small sequential calls that
  each depend on the previous output.
- **Compact proactively** in long sessions instead of letting context grow
  until auto-summarization is forced mid-task.

## Break tasks down

- Split larger tasks into clear, well-scoped subtasks **before** you start
  coding. For non-trivial changes, write a short plan first (e.g. via a
  plan agent).
- One subtask = one clear deliverable (e.g. "implement function X", "write
  tests for Y", "investigate how Z works in this library").
- If multiple subtasks are independent of each other, run them in parallel
  via subagents instead of sequentially in the main thread.

## Use subagents when appropriate

- **Delegate broad exploration** (e.g. "how is auth structured in this
  repo?") to an explore/research subagent so that search results and dead
  ends don't clutter the main context — only the conclusion gets passed
  back. This exploration stays inside the workspace, same as any other
  work (see hard limits above).
- **Delegate investigation of external dependencies/libraries** (reading
  docs, inspecting a package's source) to a dedicated subagent instead of
  pulling it into the main session.
- **Do NOT use subagents for trivial tasks** — a simple single-file change,
  a direct question, or an obvious fix should be done directly. The
  overhead of spinning up a subagent isn't worth it there.
- Give each subagent a narrow, specific task and the minimum tool
  permissions it needs to complete it — this includes filesystem scope: a
  subagent should never be given, or take, access outside the workspace.

## Communication style

- Be concise. Don't repeat what's already obvious from the code.
- Show changes as diffs/patches, not full rewritten files, unless the file
  is genuinely new.
- Explain *why* for non-trivial decisions; skip justification for obvious
  ones.

## Safety — ask before

- Destructive bash commands (`rm -rf`, `git push --force`, database
  migrations against anything other than local/dev).
- Changes touching secrets, `.env`, keys, or CI/CD configuration.
- Installing new dependencies or changing lockfiles.

## Verify code and application quality

- **Always build the solution/project to validate that no build errors
  exist when you have completed a task.**
- During development work, continuously check that the project still
  builds when it is suitable to do so.
- If build errors occur, always try to correct them as soon as it is
  suitable to do so.
- If build warnings are found, fix them before stopping after task
  completion.

## Code conventions (fill in per project)

- **Always follow the guidelines in `DOTNET_CODING_GUIDELINES.md`** (in the
  project root, if present) when writing code — its style, patterns, and
  structure take precedence over your own assumptions.
- Language/framework: …
- Formatting/linter: …
- Test command: …
- Commit style: …

---

Note: this is a global baseline. Put project-specific rules in a separate
`AGENTS.md` in the respective project root — it's layered on top of this
file and can tighten or extend the rules above.
