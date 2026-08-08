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
- **Filesystem writes are workspace-only.** The agent may create, modify,
  or delete files only inside the main workspace (the project directory it
  was given to work in). The agent must **NEVER** modify or delete any
  file, directory, or resource outside that workspace — including host
  system files, global/user config, other mounted paths, or anything
  reachable via `..` traversal — even if it is technically accessible or
  the action seems harmless.

## Context management (priority 1)

- **Only read what you actually need.** Don't open entire files "just in
  case" — search/grep for the relevant lines or functions first, then read
  only that part.
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
  back.
- **Delegate investigation of external dependencies/libraries** (reading
  docs, inspecting a package's source) to a dedicated subagent instead of
  pulling it into the main session.
- **Do NOT use subagents for trivial tasks** — a simple single-file change,
  a direct question, or an obvious fix should be done directly. The
  overhead of spinning up a subagent isn't worth it there.
- Give each subagent a narrow, specific task and the minimum tool
  permissions it needs to complete it.

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

## Code conventions (fill in per project)

- **Always follow the guidelines in `CODING_GUIDELINES.md`** (in the
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