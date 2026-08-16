# Documentation Cleanup Plan

Purpose: Consolidate, normalize, and reorder repository documentation into a single, discoverable `_CLEANED_/` tree. Originals remain untouched; cleaned files are copies placed under `_CLEANED_/` with standardized filenames and minimal metadata. This plan documents the mapping, actions, and open decisions.

Overview

- Create a clear folder hierarchy under `_CLEANED_/` for installs, guides, apps, common docker notes, and archives.

Proposed folder structure (app-first)

- _CLEANED_/README.md
- _CLEANED_/plan.md (this file)
- _CLEANED_/apps/          # All app/project-specific documentation lives here
   - opencode/             # All OpenCode docs, configs, scripts, howto in one place
      - docs/
      - configs/
      - scripts/
   - lemonade/
   - <other-apps>/
- _CLEANED_/guides/       # Cross-cutting OS or platform guides (e.g., unified Ubuntu guide)
   - ubuntu/
      - unified-ubuntu-setup.md
- _CLEANED_/docker/       # General Docker tips and reusable snippets (non-app-specific)
- _CLEANED_/notes/        # Misc short snippets not tied to a single app
- _CLEANED_/archives/
   - llms/
   - originals/

High-level steps
1. Inventory & Mapping (already completed)
   - Use the repository scan results to map each documentation file to a cleaned destination.

2. Create folders
   - Create the folders listed above under `_CLEANED_/`.

3. Copy and normalize files
   - For each mapped file: create a cleaned copy with
     - top-level H1 title
     - one-line `Purpose:` summary containing original path and language
     - normalized filename (kebab-case, platform suffix when needed)
     - ensured codeblock language markers (```bash, ```yaml, etc.)
     - preserved executable bit for `.sh` files
   - Merge very small snippet files into canonical guides where appropriate. When merging, add a short "Source:" note linking to original path.

4. Archive legacy content
   - Move raw legacy files from `_OLD_/` into `_CLEANED_/archives/llms/` with names indicating origin and platform (e.g., `llama_cpp_windows_cmds.txt`).
   - Add `TODO` headers for archive files that require curation.

5. Add index and metadata
   - Create `_CLEANED_/README.md` containing a TOC linking to cleaned files.
   - Optionally add YAML frontmatter to cleaned files with `tags`, `language`, and `source-path`.

6. Verification
   - Render-check a subset of cleaned files.
   - Run `markdownlint` (if available) and fix high-severity issues.
   - Ensure scripts keep executable permissions.

7. Review & approval
   - Present the cleaned tree and request decisions on language policy, canonical duplicates, empty-file actions, and safety checks for scripts.

Key file mappings (examples)


Open questions / blockers


Next actions (awaiting approval)

1. Confirm language policy and filename conventions.
2. Approve copying of docs into `_CLEANED_/` (no deletion of originals).
3. Approve publishing scripts that need verification (e.g., ROCm pinning).

When you approve, I will create the `_CLEANED_/` folders and copy files according to the mapping, preserving originals and adding `Purpose:` headers and a cleaned `_CLEANED_/README.md`.

## Cleanup & Consolidation Plan (refined)

Purpose
--------
Consolidate and normalize repository documentation into the `_CLEANED_/` tree. Originals outside `_CLEANED_` remain unchanged. Cleaned files are English translations or consolidated documents placed under `_CLEANED_/` with standardized filenames, a one-line `Purpose:` summary, and metadata linking back to the original source.

Scope
-----
- All documentation files and documentation-like scripts outside `_CLEANED_/` (Markdown `.md`, text snippets, `.sh` installer scripts, and small note files).
- Do NOT modify source files outside `_CLEANED_/`.

Final decisions
---------------
- Language: translate cleaned files to English. For each cleaned file add a `Original-language:` line and `Source-path:` pointing to the original file. Preserve the original files unchanged in their original locations; optionally copy original-language files into `_CLEANED_/archives/originals/` if the original is likely to be deleted later.
- Empty files: delete empty files (zero bytes or containing only placeholder headings). If a file appears to be an intentional placeholder, add a `TODO` note in the plan and do not delete until confirmed.
- Scripts: copy scripts verbatim into `_CLEANED_/` and preserve executable permissions and shebangs. Do not edit script internals during copying.
- `llama.cpp` and other model invocation arguments: never alter `llama.cpp` arguments, model flags, or other runtime parameter blocks. Preserve those lines exactly when copying or merging.
- Merge same-topic content: consolidate same-topic material into a single canonical file when possible (see merging rules below). Keep originals in archives so no content is lost.

- Unified Ubuntu guide: create a single step-by-step `_CLEANED_/guides/ubuntu/unified-ubuntu-setup.md` that consolidates Ubuntu post-install tasks (ufw, rocm, docker, common tools, post-install tweaks). If the unified guide fully covers content found in other Ubuntu-related docs, those other docs may be cleaned (merged) or removed from the cleaned tree; originals will remain archived unless you approve deletion.

Filename & metadata conventions
-------------------------------
- Filenames: use kebab-case lowercase (e.g., `install-ubuntu.md`), append platform suffix when platform-specific (e.g., `-ubuntu`, `-mint`).
- App-first rule: all documentation for a given project/app must be placed under `_CLEANED_/apps/<app>/`. Do NOT split app content across top-level type folders.
- Examples inside an app folder:
  - `_CLEANED_/apps/opencode/docs/` — user-facing guides and howto
  - `_CLEANED_/apps/opencode/configs/` — config files and policies (AGENTS.md, coding guidelines)
  - `_CLEANED_/apps/opencode/scripts/` — installer or helper scripts
- Cross-cutting content (OS-level, security, general Docker tips) lives under `_CLEANED_/guides/`, `_CLEANED_/docker/`, or `_CLEANED_/notes/` as appropriate.
- Each cleaned file must start with:

   # <Title>

   Purpose: one-line summary.

   Original-language: <lang>
   Source-path: <relative/original/path>

- Include YAML frontmatter only if it helps automation; not required for every file.

Merge algorithm (how to consolidate same-topic content)
----------------------------------------------------
1. Identify all files covering the same topic (topic = same primary intent, e.g., "Docker install on Ubuntu").
2. Choose canonical source using this priority: most complete step-by-step document > most recently modified > clearly maintained by project owner. If priority cannot be decided, keep both variants under the same folder with clear labels.
3. Create canonical cleaned file:
    - Translate to English (preserve codeblocks and commands verbatim).
    - Insert a `Canonical:` line noting which original file was chosen as canonical.
    - Append any unique, non-conflicting snippets from other sources under a titled subsection "Additional notes (source: <path>)" with their `Source-path`.
4. For conflicting instruction variants (contradicting commands or settings), include both variants clearly labeled and add a short recommendation if one is known to be safer. Do NOT modify script or CLI argument lines; include them verbatim in labeled blocks.
5. Always copy original files into `_CLEANED_/archives/originals/` (or leave originals in place) so the repository retains full traceability.

6. Unified Ubuntu guide rule: if a unified Ubuntu guide is created and it fully subsumes the content of smaller Ubuntu-specific files, mark those files as duplicates in the cleaned TOC and either archive them under `_CLEANED_/archives/originals/` or remove them from the cleaned tree (deletion only after your explicit approval). The plan will list which files are affected before deletion.

Conflict & safety handling
--------------------------
- For commands that appear unsafe or that change system config (package pinning, apt sources, kernel tweaks), add a short warning line in the cleaned copy: `Warning: requires verification` and reference the original path. Do NOT remove or alter the commands.

Verification steps (after plan approval)
---------------------------------------
1. Render-check a representative subset of cleaned files for formatting and codeblock language markers.
2. Confirm executable bit preserved for `.sh` files.
3. Optionally run `markdownlint` and fix high-severity items in cleaned copies only.

Deliverables (what the cleanup will produce)
-------------------------------------------
- `_CLEANED_/plan.md` (this file, refined)
- `_CLEANED_/README.md` (cleaned index/TOC)
- Cleaned, English-translated files placed under `_CLEANED_/` in the agreed folder structure
- `_CLEANED_/archives/originals/` (copies of originals) and `_CLEANED_/archives/llms/` for legacy LLM snippets

Approvals and open items (requires your OK before implementing)
-------------------------------------------------------------
1. Confirm: English translations for cleaned files and that originals will remain untouched.
2. Confirm: empty files may be deleted.
3. Confirm: scripts are to be copied verbatim (no content edits).
4. Confirm: merge policy (canonical selection + append unique content) is acceptable.
5. Confirm: create unified Ubuntu guide and allow merging/removal of Ubuntu-specific duplicates when the unified guide subsumes them.

Next steps (I will NOT perform these until you explicitly approve)
-----------------------------------------------------------------
- After your approval I will create the `_CLEANED_/` folder structure and copy/merge files according to this plan. No deletions outside `_CLEANED_/` will be performed; empty files will be removed only after confirmation and from their original locations if you approve that.
- I will produce a short report of all files copied, merged, deleted (empty), and archived.

---

If this plan matches your intent, reply `approve` and I will proceed with implementation; otherwise list any edits you want in the plan.
