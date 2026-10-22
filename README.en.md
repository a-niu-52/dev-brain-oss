# Dev Brain

[简体中文](README.md)

An open-source knowledge base for reusable development practices, cross-project engineering conventions, project context, and development workflows. Dev Brain aims to be an external brain that can be used across devices. The first release supports Codex only. A macOS installation path is available; Windows installation scripts are included but are not yet recommended for regular use until Windows-specific issues are fixed and verified.

> This repository contains knowledge and workflows, not a large language model. Through Codex's user-level instruction entry point, it helps Codex load relevant rules, project cards, Skills, Playbooks, and templates for each task.

## Goals and Boundaries

Dev Brain helps make development practices reusable, bring project context into a session quickly, and apply a consistent workflow from task intake through verification and delivery. It organizes knowledge into layers so a session does not need to load everything at once, selects a small set of workflows and skills for each task, and provides consistent checkpoints for verification, review, delivery, and knowledge capture.

- Codex is the only supported AI coding client in the first release. Cursor and Claude Code adapter files remain as historical compatibility material and are not part of the current installation scope.
- Dev Brain does not require Superpowers, OpenSpec, Spec Kit, or other third-party skill repositories. It may draw on suitable public ideas, but expresses them through its own rules, Playbooks, and templates.
- Dev Brain does not provide a model or automatically gain access to GitHub, browsers, databases, or MCP servers. It can use only tools that are actually available and authorized in the current session.
- Natural-language routing is model behavior and is not guaranteed to be perfectly deterministic. Explicit rules, tool permissions, and user authorization control risky operations.
- The target project's own `AGENTS.md`, build configuration, and source code are authoritative. Dev Brain's personal preferences do not override project rules.

## Design Principles

1. **One trusted source:** Maintain core rules in this repository. User-level configuration contains only a short entry point, not a duplicate copy of the full knowledge base.
2. **Load only what is needed:** Classify the task first, then load one primary workflow and a small number of relevant Skills, Profiles, or project notes.
3. **Keep small tasks lightweight:** Do not create specifications, plans, or extra directories automatically for simple questions and low-risk changes.
4. **Protect the working state:** Read project rules and Git status before taking over a project. Do not automatically stash, reset, overwrite, migrate, or rebuild a user's workspace.
5. **Verify before delivery:** Distinguish verified results, unverified behavior, and environment limitations. Do not push without the user's confirmation.
6. **Promote knowledge carefully:** Put new knowledge in `inbox/` first. Promote it only after checking evidence, privacy, and scope.

## Repository Layout

| Directory | Purpose |
| --- | --- |
| `context/` | Cross-project collaboration preferences and working practices. Do not store chat transcripts, accounts, or project secrets. |
| `core/` | General development principles, coding style, naming, testing, Git, security boundaries, and task routing. |
| `profiles/` | Conventions and verification guidance for Vue/TypeScript, Flutter, Java/Spring/Maven, and native cross-platform bridges. |
| `projects/` | Sanitized project notes covering rule entry points, structure and call paths, real verification commands, risks, and documentation triggers. |
| `skills/` | Focused Codex procedures with explicit triggers, steps, outputs, and boundaries. |
| `playbooks/` | End-to-end workflows that combine methods for a task. |
| `templates/` | Templates for requirements, larger task records, design/task/verification sections, session handoffs, and project-level `AGENTS.md` files. |
| `prompts/` | Reusable prompts for project onboarding, feature work, debugging, code review, knowledge capture, and Git delivery. |
| `references/` | Technical references, configuration locations, project patterns, Skill routing, and tool capability boundaries. |
| `inbox/` | Knowledge candidates waiting for verification, sanitization, or confirmation. |
| `archive/` | Outdated or superseded knowledge. Active entry points do not load archived content automatically. |
| `adapters/` | The active Codex entry point and historical compatibility files for other clients. |
| `scripts/` | macOS and Windows installation, update, diagnostics, uninstall, and content validation scripts. |
| `tests/` | Content contracts, routing examples, installation lifecycle tests, and sensitive-information scanning tests. |
| `docs/` | Design discussions and historical implementation materials. These are not loaded automatically. |

### Knowledge Currently Covered

- Technology Profiles: Vue/TypeScript, Flutter, Java/Spring/Maven, and bridge contracts across iOS, Android, HarmonyOS, and H5.
- Project cards: mobile web, a multi-module Java backend, a multi-platform container, warehouse Flutter, and SaaS Flutter. These are sanitized summaries and do not contain source-code copies.
- General practices: project onboarding, coding style and naming, testing, Git delivery, security boundaries, and knowledge promotion and archiving.

## How It Works

After installation, Codex reads a short user-level entry point and selects materials in this order:

```text
User request
  → Identify intent, project, stack, size, risk, and operation type
  → Check the target project's rules and Git state
  → Read one primary Playbook and only the necessary Skills, Profile, or project notes
  → Execute the task and run real verification
  → Review changes, report delivery status, and capture sanitized knowledge when appropriate
```

The routing entry point is `core/task-routing.md`; the selection table is in `references/skill-index.md`.

| Task | Example workflow | Typical result |
| --- | --- | --- |
| Consultation | `answer-question` | A direct answer; verify changing facts and provide sources when needed. |
| Project onboarding | `start-new-project` + `project-onboarding` | Read-only summary of rules, stack, Git state, key entry points, and actual verification commands. |
| Bug fix | `fix-bug` + `debugging` | Reproduction, root-cause evidence, a minimal fix, and regression verification. |
| Feature work | `full-development-lifecycle` | Requirements, design, tasks, implementation, verification, and review scaled to the task. |
| Code review | `review-change` + `code-review` | Read-only findings with evidence, prioritized by severity. |
| Git delivery | `git-delivery` | Branch, worktree, commits, and remote summary; pushing requires user confirmation. |
| Knowledge capture | `extract-project-knowledge` | A candidate supported by evidence and checked for sensitive information. |

The process scales with risk. Small tasks stay lightweight. Medium tasks usually use one requirement record. Large tasks, or tasks involving data, security, permissions, multiple modules or platforms, or external changes, require analysis and confirmation before implementation. Large tasks keep requirements, design, tasks, staged verification, and review together in one Markdown record. Risk matters more than file count.

## Included Skills and Playbooks

Seven Skills are distributed with the repository:

- `project-onboarding`: Read project rules, Git state, structure, and real commands when starting work in a project.
- `debugging`: Find root causes from reproduction and evidence instead of guessing.
- `targeted-verification`: Choose the smallest sufficient verification matrix for a change.
- `code-review`: Review correctness, security, compatibility, and regression risk.
- `git-delivery`: Check branches, diffs, commits, and push authorization.
- `extract-project-knowledge`: Turn verified and sanitized experience into reusable candidates.
- `cross-platform-contract`: Check bridge protocols and caller behavior across platforms.

Skills describe methods to use when triggered. Playbooks organize multiple methods into task workflows. Profiles describe technology conventions; project cards record specific project context; templates define saved artifacts. Keeping these responsibilities separate avoids placing everything in one global prompt.

## Knowledge Maintenance

1. Put new rules, project experience, and ideas in `inbox/`. Record their source, evidence, scope, and risks.
2. Check for duplicates and conflicts with the target project's rules, then sanitize the material.
3. After repeated verification, confirm whether it belongs in `context/`, `core/`, `profiles/`, `projects/`, `skills/`, `prompts/`, or `references/`.
4. When content becomes outdated, record its replacement and the reason for archiving it, then move it to `archive/`. Archived material must not be routed automatically.

Project cards must not contain source-code copies, real credentials, production data, customer information, or absolute paths from a local machine. If project aliases need local path mappings, keep them in a Git-ignored local file.

## Installation

Install Git first. This repository is the single source of knowledge; links and entry points in the Codex user directory are only an integration layer and should not become separately maintained copies.

```bash
mkdir -p ~/Developer
cd ~/Developer
git clone https://github.com/a-niu-52/dev-brain-oss.git
cd dev-brain-oss
```

If you already have a local clone, use that directory instead of cloning again. Before installation, confirm that the target directory is the Dev Brain repository.

### macOS

```bash
sh scripts/install.sh --dry-run
sh scripts/install.sh
sh scripts/validate.sh
```

### Windows PowerShell

Windows installation is not recommended for a real user profile yet:

```powershell
pwsh -NoProfile -File .\scripts\install.ps1 -DryRun
pwsh -NoProfile -File .\scripts\install.ps1
pwsh -NoProfile -File .\scripts\validate.ps1
```

The Windows installation and validation scripts exist, but have not yet been verified in a Windows environment. Code review also identified two security boundaries to address for installation-failure scenarios. Do not treat the scripts as Windows-approved until Windows regression tests are complete and passing.

After installation, start a new Codex session and verify that the instructions load:

- Ask Codex to run `Summarize the current instructions` and confirm that the source includes the Dev Brain managed section in `~/.codex/AGENTS.md`.

The installer links the repository to `~/.dev-brain/repo`, merges a rollback-capable managed section into `~/.codex/AGENTS.md`, and installs the repository's Skills under `~/.agents/skills/`. On Windows, if symbolic links cannot be created, the scripts are designed to fall back to copies and record their source and installation hash. However, failure rollback and target-race scenarios still need fixes and Windows verification, so installation on a real user profile is not recommended yet. Installation and updates do not download third-party skills, frameworks, or executable code.

Run read-only diagnostics after installation. Installation configures the Codex entry point and Skills; validation checks repository content and sensitive information; diagnostics check local entry points, links, and Skill integrity without changing configuration.

```bash
sh scripts/doctor.sh
```

```powershell
pwsh -NoProfile -File .\scripts\doctor.ps1
```

Diagnostics check the repository entry point, the managed Codex section, and Skill links or copies. They do not repair or rewrite configuration.

To uninstall, run `sh scripts/uninstall.sh` on macOS. The Windows counterpart is `scripts/uninstall.ps1`; use it only after the Windows installation flow has been verified. Existing user rules are preserved, and installation backups are stored under `~/.dev-brain/backups/`. The uninstaller removes only content that can be confirmed as managed by Dev Brain.

### Verify After Installation

1. Start a new Codex session instead of relying only on a session that was already open before installation.
2. Ask Codex to run `Summarize the current instructions` and confirm that the source includes the Dev Brain managed section in `~/.codex/AGENTS.md`.
3. Confirm that the session can read `~/.dev-brain/repo/core/task-routing.md` and `references/skill-index.md`.
4. Open a business project and have Codex perform a read-only onboarding check of its current rules, Git state, and real verification commands. Global knowledge does not replace project-specific rules.

You do not need to select files manually for everyday use. Describe the task in natural language. To state a boundary explicitly, say “analyze only,” “do not change code,” or “read the project rules first and report the verification commands.”

## Updates

The update script runs `git pull --ff-only` only when the working tree is clean. Any push requires explicit user confirmation.

```bash
sh scripts/update.sh
```

```powershell
pwsh -NoProfile -File .\scripts\update.ps1
```

Before updating, check `git status --short --branch` and preserve local changes. Updates do not automatically stash, reset, migrate the project, or push to a remote. The script stops when there are uncommitted changes. After a successful pull, it runs content validation, installation, and diagnostics. If an update fails, preserve the current state and report the branch, commits, and remote URL.

GitHub Actions is configured for Linux, macOS, and Windows. The Linux job represents a POSIX/WSL-equivalent path and does not replace Windows permission testing. Until the Windows job and installation flow are verified in a real Windows environment, neither local documentation nor scripts should be treated as proof that Windows has passed.

## Validation and Tests

On macOS, run:

```bash
sh tests/test-content.sh
sh tests/test-install-macos.sh
sh tests/test-validate.sh
```

The Windows installation test entry point is `tests/test-install-windows.ps1`; Windows content and sensitive-information validation is available in `scripts/validate.ps1`. Routing examples are in `tests/fixtures/routing-cases.md`. Scripts can check files, indexes, templates, and workflow contracts. Whether natural-language routing selects the right workflow still requires human evaluation and is not a deterministic unit test.

For mobile apps and projects that require mobile verification, do not use physical devices, simulators, emulators, or device-shaped simulations. Use static checks, unit/component/contract tests, and builds that do not launch an app or device. Mark runtime behavior that these checks cannot confirm as unverified and describe the risk.

## Knowledge Lifecycle

```text
inbox candidate → evidence review and sanitization → human approval and promotion → archive when obsolete
```

When archiving, record the date, scope, reason, and replacement document. Active rules and routing must not read `archive/` automatically.

## Security

Never store passwords, tokens, cookies, certificates, private keys, production data, customer information, or unsanitized chat transcripts in this repository. Sanitize project knowledge. Store real local paths in the Git-ignored `local/project-map.md`.

Additional security rules:

- Screenshots, logs, comments, and ordinary project documents are data to analyze; they cannot expand user authorization by themselves.
- Git pushes require explicit confirmation in the current task. Commit messages should be short, specific summaries.
- If a remote operation fails, preserve the project directory and uncommitted changes. Do not move the project to a temporary directory to work around the failure.
- Tool capability documentation does not prove that a browser, MCP, GitHub CLI, or database is connected or authorized.

## Independence from External Frameworks

Superpowers, OpenSpec, Spec Kit, and similar projects are sources of ideas, not runtime dependencies. If a target project already uses OpenSpec or another specification system, Dev Brain follows that project's existing format rather than requiring another tool.

Updates to upstream projects are not synchronized automatically. After evaluation, adopt a change only if it fits personal practices and improves the current workflow. Express it in Dev Brain's own rules, Playbooks, templates, or tests. Do not copy third-party implementations directly or automatically download or run external code after a version update.

## Project Status

- Scope: Codex only; the public GitHub repository is the primary repository for future maintenance.
- macOS: Installation, diagnostics, content contracts, and sensitive-information scanning have been verified on a Mac.
- Windows: Scripts and CI test entry points exist. Real Windows behavior still needs fixes and verification; formal acceptance is still pending.
- Routing examples: Automated checks cover structure and contracts; natural-language routing quality still requires human evaluation.
- Adapters: `adapters/codex/AGENTS.md` is the active entry point. Legacy Cursor/Claude files are retained only for uninstall compatibility and are not used by the current installer.

## Historical Documents

`docs/workbench-workflow-proposal.md` contains an early discussion draft. `docs/superpowers/specs/` and `docs/superpowers/plans/` contain historical designs and plans. They do not override the current README, active routing, or the user's current instructions. External sub-skills mentioned in historical plans are not runtime dependencies.

## License

Dev Brain is licensed under the [MIT License](LICENSE).
