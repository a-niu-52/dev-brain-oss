# Dev Brain 第一版实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立一个可在 macOS 与 Windows 安装、供 Codex、Cursor 和 Claude Code 复用，且包含个人上下文、项目知识、提示词、工作流和知识生命周期的个人 AI 开发工作台。

**Architecture:** `context/` 描述个人长期偏好，`core/` 保存跨项目底线，`profiles/` 保存按技术栈加载的约定，`projects/`、`references/` 和 `archive/` 保存按需读取的知识，`prompts/`、`skills/` 与 `playbooks/` 提供三层工作流入口。`adapters/` 只自动加载简短规则；安装器以受管区块合并已有 Codex/Claude 全局文件，以独立文件或链接安装 Cursor 规则和 Skills，所有用户目录变更先备份、支持 dry-run，并通过隔离用户目录测试。

**Tech Stack:** Markdown、POSIX Shell、Windows PowerShell、GitHub Actions、Git；知识 Profiles 覆盖 Vue/TypeScript、Flutter、Java/Spring/Maven 和多端原生桥接

---

## 文件职责图

- `README.md`：仓库用途、快速安装、更新和安全边界。
- `context/*.md`：个人长期上下文、协作偏好和工作方式，不保存工程硬规则。
- `core/*.md`：稳定的跨项目开发规则，每个文件只负责一个主题。
- `profiles/*.md`：按检测到的技术栈加载的命令、分层和验证矩阵，不自动覆盖项目规则。
- `projects/*.md`：近期活跃项目的脱敏知识卡片和项目模板。
- `prompts/*.md`：可复制到 Codex、Cursor 或 Claude 的跨工具简短入口。
- `references/*.md`：从近期项目提炼的技术模式、常见配置和工具加载说明。
- `archive/README.md`：过期知识的归档格式、进入条件和禁止自动加载规则。
- `adapters/codex/AGENTS.md`：Codex 自动加载的简短全局规则。
- `adapters/cursor/dev-brain.mdc`：Cursor 用户级 Always Apply 规则。
- `adapters/claude/CLAUDE.md`：Claude Code 用户级入口，使用 `@` 导入核心文档。
- `skills/*/SKILL.md`：代码审查、排错、Git 交付、项目接入和知识提炼流程。
- `playbooks/*.md`：面向人和 AI 的详细操作手册。
- `inbox/README.md`：候选规则的进入和提升条件。
- `templates/project-AGENTS.md`：项目级指令模板。
- `security/secret-scan-allowlist.txt`：敏感信息扫描的最小、可审计例外。
- `scripts/install.sh`、`scripts/uninstall.sh`：macOS 安装、受管区块合并与恢复。
- `scripts/install.ps1`、`scripts/uninstall.ps1`：Windows 安装与恢复。
- `scripts/update.*`：工作区干净时拉取并重新安装。
- `scripts/validate.*`：结构、Skill 元数据、链接和敏感信息检查。
- `tests/test-content.sh`：知识库结构与内容契约测试。
- `tests/test-install-macos.sh`：使用临时 HOME 验证 macOS 安装生命周期。
- `tests/test-install-windows.ps1`：使用临时用户目录验证 Windows 安装生命周期。
- `.github/workflows/validate.yml`：macOS、Windows 与 Linux/WSL 等价环境持续验证。

## 本次计划复审依据

- 近期项目同时覆盖 Vue/TypeScript、Flutter、Java 多模块和 iOS/Android/HarmonyOS 原生桥接，不能用单一技术栈规则覆盖所有项目。
- 多个项目已经使用项目级 `AGENTS.md`、`CLAUDE.md`、知识库文档、OpenSpec 或 CodeGraph；全局入口必须先发现这些规则再行动。
- 近期工作区普遍存在未提交修改，因此“不自动 stash、reset、迁移或覆盖”属于全局硬规则。
- 本机已有 `~/.codex/AGENTS.md`，安装器不得用符号链接整体替换，必须采用可回滚的受管区块合并。
- 近期提交记录证明“设计文档 → 实施计划 → 实现”适用于中大型任务，但各仓库的分支名、合并方式和提交前缀不同，必须由项目规则决定。
- 原始 AI Workbench 还要求长期上下文、可复制提示词、项目级知识和历史归档，因此第一版不能只创建规则模板，必须提供首批可用内容和完整知识生命周期。

### Task 1: 建立内容契约测试

**Files:**
- Create: `tests/test-content.sh`

- [ ] **Step 1: 写入会因文件缺失而失败的测试**

```sh
#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

required_files='README.md
context/README.md
context/collaboration-preferences.md
context/working-style.md
core/development-principles.md
core/coding-style.md
core/naming-conventions.md
core/git-workflow.md
core/testing-rules.md
core/security-boundaries.md
profiles/vue-typescript.md
profiles/flutter.md
profiles/java-spring-maven.md
profiles/multi-platform-bridge.md
projects/README.md
projects/project-template.md
projects/mobile-web.md
projects/java-multimodule-backend.md
projects/multiplatform-container.md
projects/warehouse-flutter.md
projects/saas-flutter.md
prompts/README.md
prompts/project-onboarding.md
prompts/feature-development.md
prompts/bug-diagnosis.md
prompts/code-review.md
prompts/knowledge-extraction.md
prompts/git-delivery.md
references/README.md
references/project-patterns.md
references/common-configurations.md
references/tool-loading.md
archive/README.md
adapters/codex/AGENTS.md
adapters/cursor/dev-brain.mdc
adapters/claude/CLAUDE.md
inbox/README.md
templates/project-AGENTS.md
security/secret-scan-allowlist.txt'

printf '%s\n' "$required_files" | while IFS= read -r file; do
  test -f "$ROOT/$file" || { echo "缺少文件: $file" >&2; exit 1; }
done

grep -q '未经用户明确确认，不执行.*git push' "$ROOT/core/git-workflow.md"
grep -q '不保存密码、Token、Cookie、证书或私钥' "$ROOT/core/security-boundaries.md"
grep -q '项目规则优先决定目标分支' "$ROOT/core/git-workflow.md"
grep -q 'flutter analyze' "$ROOT/profiles/flutter.md"
grep -q 'vue-tsc --noEmit' "$ROOT/profiles/vue-typescript.md"
grep -q 'mvn test -pl' "$ROOT/profiles/java-spring-maven.md"
grep -q '桥接协议矩阵' "$ROOT/profiles/multi-platform-bridge.md"
grep -q '默认语言' "$ROOT/context/collaboration-preferences.md"
for project in mobile-web java-multimodule-backend multiplatform-container warehouse-flutter saas-flutter; do
  grep -q '最后核验日期' "$ROOT/projects/$project.md"
  grep -q '脱敏状态：已脱敏' "$ROOT/projects/$project.md"
  grep -q '文档同步触发器' "$ROOT/projects/$project.md"
done
for prompt in project-onboarding feature-development bug-diagnosis code-review knowledge-extraction git-delivery; do
  grep -q '对应 Skill' "$ROOT/prompts/$prompt.md"
  grep -q '对应 Playbook' "$ROOT/prompts/$prompt.md"
  grep -q '可复制提示词' "$ROOT/prompts/$prompt.md"
done
grep -q '归档原因' "$ROOT/archive/README.md"
grep -q '^alwaysApply: true$' "$ROOT/adapters/cursor/dev-brain.mdc"
grep -q '@.*core/development-principles.md' "$ROOT/adapters/claude/CLAUDE.md"

echo '内容契约检查通过'
```

- [ ] **Step 2: 运行测试并确认按预期失败**

Run: `sh tests/test-content.sh`

Expected: `FAIL`，首个错误为 `缺少文件: README.md`。

- [ ] **Step 3: 仅提交测试**

```bash
git add tests/test-content.sh
git commit -m "新增知识库内容检查"
```

### Task 2: 输出内容层、适配入口和模板

**Files:**
- Create: `README.md`
- Create: `context/README.md`
- Create: `context/collaboration-preferences.md`
- Create: `context/working-style.md`
- Create: `core/development-principles.md`
- Create: `core/coding-style.md`
- Create: `core/naming-conventions.md`
- Create: `core/git-workflow.md`
- Create: `core/testing-rules.md`
- Create: `core/security-boundaries.md`
- Create: `profiles/vue-typescript.md`
- Create: `profiles/flutter.md`
- Create: `profiles/java-spring-maven.md`
- Create: `profiles/multi-platform-bridge.md`
- Create: `projects/README.md`
- Create: `projects/project-template.md`
- Create: `projects/mobile-web.md`
- Create: `projects/java-multimodule-backend.md`
- Create: `projects/multiplatform-container.md`
- Create: `projects/warehouse-flutter.md`
- Create: `projects/saas-flutter.md`
- Create: `prompts/README.md`
- Create: `prompts/project-onboarding.md`
- Create: `prompts/feature-development.md`
- Create: `prompts/bug-diagnosis.md`
- Create: `prompts/code-review.md`
- Create: `prompts/knowledge-extraction.md`
- Create: `prompts/git-delivery.md`
- Create: `references/README.md`
- Create: `references/project-patterns.md`
- Create: `references/common-configurations.md`
- Create: `references/tool-loading.md`
- Create: `archive/README.md`
- Create: `adapters/codex/AGENTS.md`
- Create: `adapters/cursor/dev-brain.mdc`
- Create: `adapters/claude/CLAUDE.md`
- Create: `inbox/README.md`
- Create: `templates/project-AGENTS.md`
- Create: `security/secret-scan-allowlist.txt`
- Create: `.gitignore`
- Test: `tests/test-content.sh`

- [ ] **Step 1: 写入 README 的确定内容**

README 必须包含以下命令和说明：

```markdown
# Dev Brain

个人长期上下文、项目知识、工作流程、提示词和 AI 编程工具知识库。

## 安装

macOS：`./scripts/install.sh --dry-run`，确认后运行 `./scripts/install.sh`。

Windows PowerShell：`./scripts/install.ps1 -DryRun`，确认后运行 `./scripts/install.ps1`。

## 更新

更新脚本只在仓库工作区干净时执行 `git pull --ff-only`。任何推送都必须由用户明确确认。

## 安全

私有仓库也禁止保存密码、Token、Cookie、证书、私钥、生产数据和客户资料。

## 知识生命周期

新经验先进入 `inbox/`，人工核验后进入 `context/`、`core/`、`profiles/`、`projects/`、`skills/`、`prompts/` 或 `references/`；失效或被替代后进入 `archive/`，归档内容不自动加载。
```

- [ ] **Step 2: 写入个人上下文和六个核心规则文件**

`context/README.md` 明确 Context 是描述性信息，不覆盖项目规则，不整份自动注入会话；`context/collaboration-preferences.md` 固定包含默认语言为中文、先给结论、复杂任务先设计和计划、高风险操作先确认、不确定信息先核实；`context/working-style.md` 固定包含先读后改、分阶段验证、保留用户现场、完成前提供新鲜证据和中大型任务维护设计与计划文档。

每个文件采用“规则、原因、例外”结构，并至少包含以下确定规则：

```markdown
# Git 工作流

## 提交信息使用简短中文概要
- 规则：一句话说明做了什么以及为什么改，通常控制在 20 个汉字左右。
- 原因：便于快速理解提交历史。
- 例外：没有。

## 推送必须由用户确认
- 规则：未经用户明确确认，不执行 `git push`。
- 原因：远程变更影响协作方，必须保留最终决定权。
- 例外：用户已在当前任务中明确要求“推送”“push”或“提交并推送”。

## 远程失败时保留现场
- 规则：远程操作失败后停止，报告当前分支、工作区、本地提交和远程地址。
- 原因：避免为绕过网络或认证问题而丢失本地工作。
- 例外：没有。

## 分支和提交格式服从项目规则
- 规则：项目规则优先决定目标分支、merge/rebase、提交前缀和功能分支是否允许推送；没有项目规则时才使用个人默认值。
- 原因：不同仓库实际使用 `main`、`dev`、发布分支和个人开发分支，不能由全局规则写死。
- 例外：用户在当前任务中明确指定流程时，以用户要求为准。
```

`development-principles.md` 包含聚焦任务、先读后改、保护用户修改、先读取项目入口和真实代码；`coding-style.md` 包含遵循现有风格、控制文件职责、避免无关重构；`naming-conventions.md` 包含表达业务含义、避免 `data/info/temp` 等模糊词；`testing-rules.md` 包含风险相称验证、修复必须有回归测试、完成前提供新鲜证据；`security-boundaries.md` 必须包含“不保存密码、Token、Cookie、证书或私钥”。

- [ ] **Step 3: 写入四个技术栈 Profile 和参考资料**

`profiles/` 不得写业务项目名、客户名或内部地址，只写可复用模式：

```markdown
# Vue / TypeScript 验证 Profile

1. 先读取 `package.json` 的实际 scripts，不猜测包管理器。
2. 优先验证顺序：相关单测 → `vue-tsc --noEmit` → ESLint → 构建。
3. 涉及跨页面主流程、登录、路由或真实提交时，再运行对应 Playwright 测试。
4. 单测沿用项目现有 colocated `*.spec.ts` 方式，不强制搬迁目录。
```

Flutter Profile 必须包含 `dart format`、`flutter analyze`、相关 `flutter test`，并把库存、金额、审批、扫码、文件、权限和平台配置视为高风险；Java Profile 必须先识别 Maven 模块和默认跳过测试配置，使用 `mvn test -pl <module> -am`；多端桥接 Profile 必须维护“桥接协议矩阵”，逐平台核对方法名、参数、回调、错误和降级行为。

`references/README.md` 说明参考资料只按需读取，不形成强制规则；`references/project-patterns.md` 记录本次脱敏观察：多技术栈并行、工作区常有用户改动、中大型功能采用设计和计划文档、项目文档存在同步维护触发器、分支策略不统一。每条观察必须写“证据类型、适用范围、不能推导出的结论”。

`references/common-configurations.md` 记录 `package.json`、`pubspec.yaml`、Maven 模块、Gradle 和桥接配置的定位方法，不复制任何项目私有配置；`references/tool-loading.md` 记录 Codex 全局/项目指令优先级、Skill 用户目录、Cursor 规则入口、Claude 导入入口以及修改后需要新建会话的验证方式。

- [ ] **Step 4: 写入五份首批项目知识卡片**

所有项目卡片使用安全别名，不写绝对路径、客户名、域名、账号或内部地址。`projects/project-template.md` 和每份卡片固定包含以下字段：

```markdown
# 项目知识标题

- 项目标识：稳定的安全别名
- 来源类型：近期活跃项目的脱敏观察
- 技术栈：实际检测到的框架和构建工具
- 适用范围：本卡片可用于哪些任务
- 最后核验日期：YYYY-MM-DD
- 脱敏状态：已脱敏

## 规则入口
## 目录与关键调用链
## 真实验证命令
## 高风险区域
## 已验证约定
## 文档同步触发器
## 尚未确认
```

五份卡片的确定内容边界为：

- `mobile-web.md`：Vue/TypeScript、Vitest、Playwright、路由与接口联调；不得写具体业务页面名。
- `java-multimodule-backend.md`：Java 8、Spring Boot、多模块 Maven、MyBatis、事务边界与模块级测试。
- `multiplatform-container.md`：H5 与 iOS/Android/HarmonyOS 桥接协议、方法名、参数、回调、异常与降级矩阵。
- `warehouse-flutter.md`：Flutter/GetX、库存或扫码类高风险流程、权限、设备和平台配置验证。
- `saas-flutter.md`：Flutter 页面流转、表单、金额或审批类风险、路由和 ViewModel 验证。

`projects/README.md` 说明真实仓库名只有确认不敏感时才可记录；实际本机路径写入被 Git 忽略的 `local/project-map.md`，不进入仓库。

- [ ] **Step 5: 写入跨工具 Prompt 和知识生命周期**

每个 Prompt 都包含“适用场景、需要填写的输入、可复制提示词、预期输出、对应 Skill、对应 Playbook”。`prompts/project-onboarding.md` 的可复制正文固定为：

```text
先读取当前目录及父级生效的项目规则，不修改任何文件。记录 Git 状态、当前分支、远程和未推送提交；再读取真实构建清单、架构文档和知识入口，识别技术栈与适用 Profile。输出项目入口、目标分支、风险、验证命令和仍需确认的问题，然后等待我的具体开发任务。
```

其余 Prompt 的核心要求分别为：功能开发先确认范围和验收标准；故障排查先复现和定位根因；代码审查优先正确性、安全和回归；知识提炼先脱敏并进入 `inbox/`；Git 交付先报告分支、工作区、未推送提交和远程，未经确认不推送。

`inbox/README.md` 写明候选知识的来源、证据、适用范围、冲突检查和人工提升条件；`archive/README.md` 固定要求归档时间、原适用范围、归档原因、替代文档，并明确适配器、Profile 和 Skill 不得自动引用归档内容。

- [ ] **Step 6: 写入三个工具入口**

Codex 入口保持在 120 行以内，并直接包含 Git 推送确认、保护本地修改、验证后再宣称完成三条硬规则。

Cursor 文件使用以下 frontmatter：

```markdown
---
description: 个人开发习惯、Git 安全规则和交付约定
globs:
alwaysApply: true
---
```

Claude 入口通过安装器创建的稳定仓库链接导入：

```markdown
# Personal development instructions

@~/.dev-brain/repo/core/development-principles.md
@~/.dev-brain/repo/core/coding-style.md
@~/.dev-brain/repo/core/naming-conventions.md
@~/.dev-brain/repo/core/git-workflow.md
@~/.dev-brain/repo/core/testing-rules.md
@~/.dev-brain/repo/core/security-boundaries.md
```

- [ ] **Step 7: 写入模板、文档同步触发器与忽略规则**

`.gitignore` 必须包含：

```gitignore
local/
.dev-brain/
*.pem
*.key
.env
.env.*
!.env.example
.DS_Store
```

`projects/project-template.md` 包含项目范围、技术栈、规则入口、目标分支、merge/rebase 策略、命令、已验证约定、常见风险、文档同步触发器和脱敏检查；`inbox/README.md` 规定候选规则只有重复验证、边界明确、无冲突后才能提升；`templates/project-AGENTS.md` 只放项目级命令、架构和例外，不复制个人通用规则。

文档同步触发器必须覆盖：技术栈、目录、入口、路由、公共架构、调用链、接口状态或质量门禁发生变化时，在同一任务中更新对应项目知识文档；文档与代码冲突时先核实并报告，不静默选择。

`security/secret-scan-allowlist.txt` 初始只有注释；有效行固定为 `sha256 <64位哈希> <精确相对路径>`，哈希与路径必须同时匹配，禁止使用 `*` 放行整个目录。

- [ ] **Step 8: 运行内容测试**

Run: `sh tests/test-content.sh`

Expected: `内容契约检查通过`。

- [ ] **Step 9: 提交内容层和工具入口**

```bash
git add README.md context core profiles projects prompts references archive adapters inbox templates security .gitignore
git commit -m "建立个人开发知识体系"
```

### Task 3: 输出可复用 Skills 和 Playbooks

**Files:**
- Create: `skills/code-review/SKILL.md`
- Create: `skills/debugging/SKILL.md`
- Create: `skills/git-delivery/SKILL.md`
- Create: `skills/project-onboarding/SKILL.md`
- Create: `skills/extract-project-knowledge/SKILL.md`
- Create: `skills/targeted-verification/SKILL.md`
- Create: `skills/cross-platform-contract/SKILL.md`
- Create: `playbooks/start-new-project.md`
- Create: `playbooks/fix-bug.md`
- Create: `playbooks/deliver-feature.md`
- Create: `playbooks/extract-project-knowledge.md`
- Modify: `tests/test-content.sh`

- [ ] **Step 1: 扩展测试，要求所有 Skill 有合法元数据**

在 `tests/test-content.sh` 追加：

```sh
for skill in code-review debugging git-delivery project-onboarding extract-project-knowledge targeted-verification cross-platform-contract; do
  file="$ROOT/skills/$skill/SKILL.md"
  test -f "$file" || { echo "缺少 Skill: $skill" >&2; exit 1; }
  head -n 1 "$file" | grep -q '^---$'
  grep -q "^name: $skill$" "$file"
  grep -q '^description: .\+' "$file"
done

for playbook in start-new-project fix-bug deliver-feature extract-project-knowledge; do
  test -f "$ROOT/playbooks/$playbook.md" || { echo "缺少 Playbook: $playbook" >&2; exit 1; }
done

if grep -R 'archive/' "$ROOT/adapters" "$ROOT/profiles" "$ROOT/skills"; then
  echo '自动加载入口不得引用 archive/' >&2
  exit 1
fi
```

- [ ] **Step 2: 运行测试确认失败**

Run: `sh tests/test-content.sh`

Expected: `FAIL`，错误为 `缺少 Skill: code-review`。

- [ ] **Step 3: 创建七个单一职责 Skill**

每个 `SKILL.md` 必须使用以下格式并将名称替换为对应目录名：

```markdown
---
name: code-review
description: 审查代码变更的正确性、安全性和回归风险。用于用户要求 review、审查 diff 或合并前检查时。
---

# Code Review

1. 读取最近的 `AGENTS.md` 和项目验证命令。
2. 先检查正确性、数据安全和破坏性变化，再检查可维护性。
3. 每个问题给出文件、行号、触发条件和影响。
4. 不把纯风格偏好报告为阻断问题。
5. 没有发现时明确说明，并列出尚未覆盖的测试风险。
```

其他 Skill 的核心输出分别为：根因与复现证据、推送前状态摘要、项目入口清单、候选知识及其适用范围、按改动范围选择的验证命令、多端桥接协议差异表。任何 Skill 都不得自动执行 `git push`。

`project-onboarding` 必须按以下顺序执行，不允许先套用技术栈假设：

```markdown
1. 记录 `git status`、当前分支、远程和未推送提交，不修改现场。
2. 查找最近的 `AGENTS.md`、`AGENTS.override.md`、`CLAUDE.md`、`CODEBUDDY.md`。
3. 检查 `.codegraph/`、知识库索引、OpenSpec、README 和项目架构文档。
4. 从 `package.json`、`pubspec.yaml`、`pom.xml`、Gradle 与 Makefile 读取真实命令。
5. 选择匹配的 Profile；项目规则与 Profile 冲突时项目规则优先。
6. 输出入口、技术栈、目标分支、风险、验证命令和仍需确认的问题。
```

`targeted-verification` 根据项目真实脚本生成最小但充分的验证矩阵，不把构建通过等同于测试通过；`cross-platform-contract` 以 H5/调用方协议为基线，分别检查 iOS、Android、HarmonyOS 的方法名、参数、回调、异常与降级能力。

- [ ] **Step 4: 创建四个 Playbook**

每个 Playbook 必须包含“输入、步骤、验证、停止条件”。`extract-project-knowledge.md` 明确执行：收集证据 → 删除客户和密钥信息 → 标注适用范围 → 写入 `inbox/` → 人工确认后提升。

- [ ] **Step 5: 运行内容测试**

Run: `sh tests/test-content.sh`

Expected: `内容契约检查通过`。

- [ ] **Step 6: 提交 Skills 和 Playbooks**

```bash
git add skills playbooks tests/test-content.sh
git commit -m "补充常用开发工作流程"
```

### Task 4: 用 TDD 实现 macOS 安装与卸载

**Files:**
- Create: `tests/test-install-macos.sh`
- Create: `scripts/install.sh`
- Create: `scripts/uninstall.sh`

- [ ] **Step 1: 写安装生命周期失败测试**

测试使用隔离目录，绝不能修改真实 HOME。先放入用户已有的 Codex 和 Claude 全局规则，验证安装器只追加带固定标记的受管区块：

```sh
#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FAKE_HOME=$(mktemp -d)
ROLLBACK_HOME=$(mktemp -d)
trap 'rm -rf "$FAKE_HOME" "$ROLLBACK_HOME"' EXIT

mkdir -p "$FAKE_HOME/.codex" "$FAKE_HOME/.claude" "$FAKE_HOME/.cursor/rules"
printf '用户原有 Codex 规则\n' > "$FAKE_HOME/.codex/AGENTS.md"
printf '用户原有 Claude 规则\n' > "$FAKE_HOME/.claude/CLAUDE.md"

DEV_BRAIN_HOME_DIR="$FAKE_HOME" "$ROOT/scripts/install.sh" --dry-run
grep -q '用户原有 Codex 规则' "$FAKE_HOME/.codex/AGENTS.md"
! grep -q '<!-- DEV-BRAIN:START -->' "$FAKE_HOME/.codex/AGENTS.md"

DEV_BRAIN_HOME_DIR="$FAKE_HOME" "$ROOT/scripts/install.sh"
test -L "$FAKE_HOME/.dev-brain/repo"
test -f "$FAKE_HOME/.codex/AGENTS.md"
grep -q '用户原有 Codex 规则' "$FAKE_HOME/.codex/AGENTS.md"
test "$(grep -c '<!-- DEV-BRAIN:START -->' "$FAKE_HOME/.codex/AGENTS.md")" -eq 1
test -L "$FAKE_HOME/.cursor/rules/dev-brain.mdc"
test -f "$FAKE_HOME/.claude/CLAUDE.md"
grep -q '用户原有 Claude 规则' "$FAKE_HOME/.claude/CLAUDE.md"
grep -q '@~/.dev-brain/repo/adapters/claude/CLAUDE.md' "$FAKE_HOME/.claude/CLAUDE.md"
for skill in code-review debugging git-delivery project-onboarding extract-project-knowledge targeted-verification cross-platform-contract; do
  test -L "$FAKE_HOME/.agents/skills/$skill"
done
find "$FAKE_HOME/.dev-brain/backups" -type f | grep -q .

DEV_BRAIN_HOME_DIR="$FAKE_HOME" "$ROOT/scripts/install.sh"
test "$(grep -c '<!-- DEV-BRAIN:START -->' "$FAKE_HOME/.codex/AGENTS.md")" -eq 1
test "$(grep -c '<!-- DEV-BRAIN:START -->' "$FAKE_HOME/.claude/CLAUDE.md")" -eq 1
DEV_BRAIN_HOME_DIR="$FAKE_HOME" "$ROOT/scripts/uninstall.sh"
grep -q '用户原有 Codex 规则' "$FAKE_HOME/.codex/AGENTS.md"
! grep -q '<!-- DEV-BRAIN:START -->' "$FAKE_HOME/.codex/AGENTS.md"
grep -q '用户原有 Claude 规则' "$FAKE_HOME/.claude/CLAUDE.md"
! grep -q '<!-- DEV-BRAIN:START -->' "$FAKE_HOME/.claude/CLAUDE.md"
test ! -e "$FAKE_HOME/.agents/skills/code-review"

printf '用户原有 Cursor 规则\n' > "$FAKE_HOME/.cursor/rules/dev-brain.mdc"
if DEV_BRAIN_HOME_DIR="$FAKE_HOME" "$ROOT/scripts/install.sh"; then
  echo '冲突文件未阻止安装' >&2
  exit 1
fi
grep -q '用户原有 Cursor 规则' "$FAKE_HOME/.cursor/rules/dev-brain.mdc"

mkdir -p "$ROLLBACK_HOME/.codex" "$ROLLBACK_HOME/.claude"
printf '回滚前 Codex 规则\n' > "$ROLLBACK_HOME/.codex/AGENTS.md"
printf '回滚前 Claude 规则\n' > "$ROLLBACK_HOME/.claude/CLAUDE.md"
if DEV_BRAIN_HOME_DIR="$ROLLBACK_HOME" DEV_BRAIN_TEST_FAIL_AFTER=3 "$ROOT/scripts/install.sh"; then
  echo '模拟失败未返回非零' >&2
  exit 1
fi
grep -q '回滚前 Codex 规则' "$ROLLBACK_HOME/.codex/AGENTS.md"
! grep -q '<!-- DEV-BRAIN:START -->' "$ROLLBACK_HOME/.codex/AGENTS.md"
grep -q '回滚前 Claude 规则' "$ROLLBACK_HOME/.claude/CLAUDE.md"
test ! -e "$ROLLBACK_HOME/.dev-brain/repo"

echo 'macOS 安装测试通过'
```

- [ ] **Step 2: 运行测试确认失败**

Run: `sh tests/test-install-macos.sh`

Expected: `FAIL`，因为 `scripts/install.sh` 不存在。

- [ ] **Step 3: 实现最小安装器**

`install.sh` 必须：计算仓库根目录；接受 `DEV_BRAIN_HOME_DIR` 覆盖 HOME；支持 `--dry-run`；在写入前预检全部独占目标；未知冲突返回非零且不改任何文件。仓库入口、Cursor 规则和 Skill 使用 `ln -s`；Codex 与 Claude 使用受管区块合并，保留文件中所有非受管内容。

真实安装开始后，把每个已完成操作追加到仅本次运行使用的操作日志；任何步骤失败时按相反顺序删除新建链接、恢复受管文件的本次备份并返回非零。`DEV_BRAIN_TEST_FAIL_AFTER=<数字>` 只作为隔离测试故障注入点，不写入用户文档，也不影响未设置该变量时的行为。

受管区块固定使用以下边界，重复安装只能替换此区块，不得追加第二份：

```text
<!-- DEV-BRAIN:START -->
...由 dev-brain 管理的内容...
<!-- DEV-BRAIN:END -->
```

`merge_managed_block` 在每次真实修改前把原文件备份到 `~/.dev-brain/backups/<时间戳>/`，并在目标文件所在目录创建临时文件后原子替换。Codex 区块写入 `adapters/codex/AGENTS.md` 的实际内容；Claude 区块只写入 `@~/.dev-brain/repo/adapters/claude/CLAUDE.md`，利用 Claude 的导入语法保持单一来源。

核心映射必须是：

```sh
link_one "$ROOT" "$HOME_DIR/.dev-brain/repo"
merge_managed_block "$ROOT/adapters/codex/AGENTS.md" "$HOME_DIR/.codex/AGENTS.md" codex
link_one "$ROOT/adapters/cursor/dev-brain.mdc" "$HOME_DIR/.cursor/rules/dev-brain.mdc"
merge_managed_block "$ROOT/adapters/claude/CLAUDE.md" "$HOME_DIR/.claude/CLAUDE.md" claude
for skill in code-review debugging git-delivery project-onboarding extract-project-knowledge targeted-verification cross-platform-contract; do
  link_one "$ROOT/skills/$skill" "$HOME_DIR/.agents/skills/$skill"
done
```

- [ ] **Step 4: 实现只删除受管内容的卸载器**

`uninstall.sh` 只删除由当前仓库创建且仍指向预期来源的符号链接，并从 Codex、Claude 文件中移除唯一的受管区块。文件中的用户原有内容与备份必须保留；普通文件、其他来源链接、重复或不完整标记均停止并报错，不猜测修复。

- [ ] **Step 5: 运行测试确认通过**

Run: `sh tests/test-install-macos.sh`

Expected: `macOS 安装测试通过`。

- [ ] **Step 6: 提交 macOS 安装器**

```bash
git add scripts/install.sh scripts/uninstall.sh tests/test-install-macos.sh
git commit -m "新增macOS安全安装流程"
```

### Task 5: 用 TDD 实现更新与内容校验

**Files:**
- Create: `tests/test-validate.sh`
- Create: `scripts/validate.sh`
- Create: `scripts/update.sh`

- [ ] **Step 1: 写校验器失败测试**

```sh
#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sh "$ROOT/scripts/validate.sh"

FIXTURE=$(mktemp -d)
trap 'rm -rf "$FIXTURE"' EXIT
printf '%s\n' '-----BEGIN PRIVATE'' KEY-----' > "$FIXTURE/leak.txt"
if DEV_BRAIN_SCAN_ROOT="$FIXTURE" sh "$ROOT/scripts/validate.sh"; then
  echo '敏感信息未被阻止' >&2
  exit 1
fi

mv "$FIXTURE/leak.txt" "$FIXTURE/allowed-test-key.txt"
if command -v shasum >/dev/null 2>&1; then
  HASH=$(shasum -a 256 "$FIXTURE/allowed-test-key.txt" | awk '{print $1}')
else
  HASH=$(sha256sum "$FIXTURE/allowed-test-key.txt" | awk '{print $1}')
fi
printf 'sha256 %s %s\n' "$HASH" 'allowed-test-key.txt' > "$FIXTURE/allowlist.txt"
DEV_BRAIN_SCAN_ROOT="$FIXTURE" DEV_BRAIN_ALLOWLIST_FILE="$FIXTURE/allowlist.txt" sh "$ROOT/scripts/validate.sh"

cp "$FIXTURE/allowed-test-key.txt" "$FIXTURE/same-secret-wrong-path.txt"
if DEV_BRAIN_SCAN_ROOT="$FIXTURE" DEV_BRAIN_ALLOWLIST_FILE="$FIXTURE/allowlist.txt" sh "$ROOT/scripts/validate.sh"; then
  echo '白名单错误放行了其他路径' >&2
  exit 1
fi
echo '校验器测试通过'
```

- [ ] **Step 2: 运行测试确认失败**

Run: `sh tests/test-validate.sh`

Expected: `FAIL`，因为 `scripts/validate.sh` 不存在。

- [ ] **Step 3: 实现校验脚本**

`validate.sh` 先运行 `tests/test-content.sh`，再检查 Git 跟踪文件中的私钥头、常见 Token 前缀、`.env` 和绝对用户名路径。扫描默认只读取 `git ls-files` 返回的文件；`DEV_BRAIN_SCAN_ROOT` 存在时改为扫描该夹具目录。允许项只能来自 `security/secret-scan-allowlist.txt`，每行固定为 `sha256 <64位哈希> <精确相对路径>`；哈希和路径必须同时匹配，禁止目录通配和全局忽略。`DEV_BRAIN_ALLOWLIST_FILE` 仅用于隔离测试指定清单。

测试覆盖两种情况：允许清单中的固定文件哈希与路径可以通过；相同内容出现在其他路径时仍然失败。脚本自身的检测模式必须拆分字符串，避免自检命中，例如：

```sh
private_key_pattern='BEGIN PRIVATE'' KEY'
token_pattern='ghp_[A-Za-z0-9]\{20,\}'
```

此外检查 `context/`、`core/`、`profiles/`、`prompts/`、`skills/`、`playbooks/`、`projects/`、`references/` 中不得出现客户名、内网地址、密钥、生产数据或 `/Users/<用户名>`、`C:\\Users\\<用户名>` 绝对路径。项目卡片可以使用经过确认的安全别名，但不能把客户标识或本机路径当作别名。`references/project-patterns.md` 只允许脱敏后的技术模式和适用范围。

- [ ] **Step 4: 实现安全更新脚本**

`update.sh` 必须先检查 `git status --porcelain`；非空则报告并退出。随后执行 `git pull --ff-only`，失败时输出当前分支、状态、未推送提交和远程地址并退出；成功后运行 `validate.sh` 和 `install.sh`。脚本不得执行 stash、reset、目录迁移、重新克隆或改变业务项目工作区。

- [ ] **Step 5: 运行验证**

Run: `sh tests/test-validate.sh && sh tests/test-install-macos.sh`

Expected: 两个脚本都输出通过。

- [ ] **Step 6: 提交校验与更新脚本**

```bash
git add scripts/validate.sh scripts/update.sh tests/test-validate.sh
git commit -m "增加更新与敏感信息检查"
```

### Task 6: 实现 Windows PowerShell 安装生命周期

**Files:**
- Create: `tests/test-install-windows.ps1`
- Create: `scripts/install.ps1`
- Create: `scripts/uninstall.ps1`
- Create: `scripts/validate.ps1`
- Create: `scripts/update.ps1`

- [ ] **Step 1: 写 Windows 失败测试**

```powershell
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$FakeHome = Join-Path ([System.IO.Path]::GetTempPath()) ("dev-brain-" + [guid]::NewGuid())
$RollbackHome = Join-Path ([System.IO.Path]::GetTempPath()) ("dev-brain-rollback-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $FakeHome | Out-Null
try {
  $env:DEV_BRAIN_HOME_DIR = $FakeHome
  New-Item -ItemType Directory -Path "$FakeHome/.codex", "$FakeHome/.claude", "$FakeHome/.cursor/rules" -Force | Out-Null
  Set-Content -LiteralPath "$FakeHome/.codex/AGENTS.md" -Value '用户原有 Codex 规则'
  Set-Content -LiteralPath "$FakeHome/.claude/CLAUDE.md" -Value '用户原有 Claude 规则'
  & "$Root/scripts/install.ps1" -DryRun
  if ((Get-Content "$FakeHome/.codex/AGENTS.md" -Raw) -match 'DEV-BRAIN:START') { throw 'DryRun 修改了文件' }
  & "$Root/scripts/install.ps1"
  @(
    "$FakeHome/.dev-brain/repo",
    "$FakeHome/.codex/AGENTS.md",
    "$FakeHome/.cursor/rules/dev-brain.mdc",
    "$FakeHome/.claude/CLAUDE.md"
  ) | ForEach-Object { if (-not (Test-Path $_)) { throw "缺少安装目标: $_" } }
  @('code-review', 'debugging', 'git-delivery', 'project-onboarding', 'extract-project-knowledge', 'targeted-verification', 'cross-platform-contract') |
    ForEach-Object { if (-not (Test-Path "$FakeHome/.agents/skills/$_")) { throw "缺少 Skill: $_" } }
  if ((Get-Content "$FakeHome/.codex/AGENTS.md" -Raw) -notmatch '用户原有 Codex 规则') { throw '覆盖了 Codex 原有规则' }
  if ((Get-Content "$FakeHome/.claude/CLAUDE.md" -Raw) -notmatch '用户原有 Claude 规则') { throw '覆盖了 Claude 原有规则' }
  if (-not (Get-ChildItem "$FakeHome/.dev-brain/backups" -File -Recurse)) { throw '未生成规则备份' }
  & "$Root/scripts/install.ps1"
  $CodexMarkers = (Select-String -Path "$FakeHome/.codex/AGENTS.md" -Pattern '<!-- DEV-BRAIN:START -->').Count
  $ClaudeMarkers = (Select-String -Path "$FakeHome/.claude/CLAUDE.md" -Pattern '<!-- DEV-BRAIN:START -->').Count
  if ($CodexMarkers -ne 1) { throw '重复写入 Codex 受管区块' }
  if ($ClaudeMarkers -ne 1) { throw '重复写入 Claude 受管区块' }
  & "$Root/scripts/uninstall.ps1"
  if ((Get-Content "$FakeHome/.codex/AGENTS.md" -Raw) -notmatch '用户原有 Codex 规则') { throw '卸载删除了 Codex 原有规则' }
  if ((Get-Content "$FakeHome/.codex/AGENTS.md" -Raw) -match 'DEV-BRAIN:START') { throw '卸载未清理 Codex 受管区块' }
  if ((Get-Content "$FakeHome/.claude/CLAUDE.md" -Raw) -notmatch '用户原有 Claude 规则') { throw '卸载删除了 Claude 原有规则' }
  if ((Get-Content "$FakeHome/.claude/CLAUDE.md" -Raw) -match 'DEV-BRAIN:START') { throw '卸载未清理 Claude 受管区块' }

  Set-Content -LiteralPath "$FakeHome/.cursor/rules/dev-brain.mdc" -Value '用户原有 Cursor 规则'
  & "$Root/scripts/install.ps1" 2>$null
  if ($?) { throw '未知 Cursor 冲突未阻止安装' }
  if ((Get-Content "$FakeHome/.cursor/rules/dev-brain.mdc" -Raw) -notmatch '用户原有 Cursor 规则') { throw '冲突文件被覆盖' }

  New-Item -ItemType Directory -Path "$RollbackHome/.codex", "$RollbackHome/.claude" -Force | Out-Null
  Set-Content -LiteralPath "$RollbackHome/.codex/AGENTS.md" -Value '回滚前 Codex 规则'
  Set-Content -LiteralPath "$RollbackHome/.claude/CLAUDE.md" -Value '回滚前 Claude 规则'
  $env:DEV_BRAIN_HOME_DIR = $RollbackHome
  $env:DEV_BRAIN_TEST_FAIL_AFTER = '3'
  & "$Root/scripts/install.ps1" 2>$null
  if ($?) { throw '模拟失败未返回非零' }
  if ((Get-Content "$RollbackHome/.codex/AGENTS.md" -Raw) -notmatch '回滚前 Codex 规则') { throw 'Codex 回滚失败' }
  if ((Get-Content "$RollbackHome/.claude/CLAUDE.md" -Raw) -notmatch '回滚前 Claude 规则') { throw 'Claude 回滚失败' }
  if (Test-Path "$RollbackHome/.dev-brain/repo") { throw '回滚后仍残留仓库链接' }
  Write-Output 'Windows 安装测试通过'
} finally {
  Remove-Item -LiteralPath $FakeHome -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $RollbackHome -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item Env:DEV_BRAIN_TEST_FAIL_AFTER -ErrorAction SilentlyContinue
}
```

- [ ] **Step 2: 在 Windows 或 GitHub Actions 上确认测试失败**

Run: `pwsh -NoProfile -File tests/test-install-windows.ps1`

Expected: `FAIL`，因为 `scripts/install.ps1` 不存在。

- [ ] **Step 3: 实现 Windows 安装与卸载**

PowerShell 安装器使用与 Shell 版相同的七个 Skill 映射、冲突预检和受管区块边界。仓库根入口创建目录 Junction；Cursor 与 Skill 优先创建符号链接，没有权限时复制文件或目录，并在 `$HomeDir/.dev-brain/install-manifest.json` 记录目标、来源、模式和内容哈希。Codex 与 Claude 始终采用备份后原子合并受管区块，不得用 Junction、符号链接或复制覆盖全局文件。

卸载器移除 Codex 与 Claude 的受管区块；对链接和复制项，只删除清单中仍指向预期来源或与记录哈希一致的目标。用户修改过的文件、未知 Cursor 冲突和不完整标记必须保留并报错。测试需要覆盖 dry-run、重复安装、保留原规则、备份存在、未知冲突不改现场和卸载只清理受管内容。

- [ ] **Step 4: 实现 Windows 校验与更新**

`validate.ps1` 与 Shell 校验规则一致；`update.ps1` 在工作区非干净时停止，只允许 `git pull --ff-only`，失败时输出现场，不执行 stash、reset、目录迁移或重新克隆。

- [ ] **Step 5: 在 Windows 上运行测试**

Run: `pwsh -NoProfile -File tests/test-install-windows.ps1; pwsh -NoProfile -File scripts/validate.ps1`

Expected: `Windows 安装测试通过`，校验返回退出码 0。

- [ ] **Step 6: 提交 Windows 支持**

```bash
git add scripts/*.ps1 tests/test-install-windows.ps1
git commit -m "新增Windows安全安装流程"
```

### Task 7: 添加跨平台持续验证和最终说明

**Files:**
- Create: `.github/workflows/validate.yml`
- Modify: `README.md`

- [ ] **Step 1: 创建三平台工作流**

```yaml
name: validate

on:
  push:
  pull_request:

permissions:
  contents: read

jobs:
  linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: sh tests/test-content.sh
      - run: sh tests/test-install-macos.sh
      - run: sh tests/test-validate.sh

  macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - run: sh tests/test-content.sh
      - run: sh tests/test-install-macos.sh
      - run: sh tests/test-validate.sh

  windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - shell: pwsh
        run: ./tests/test-install-windows.ps1
      - shell: pwsh
        run: ./scripts/validate.ps1
```

- [ ] **Step 2: README 补充完整使用顺序**

明确写出：克隆私有仓库 → dry-run → 安装 → 重启工具 → 用 Codex `Summarize the current instructions`、Claude `/memory` 和 Cursor Rules 面板验证加载来源。注明 Cursor 用户规则文件在本机不自动跨设备同步，Git 仓库仍是唯一来源；进入业务项目后先运行 `project-onboarding`，根据真实清单选择 Profile，项目内规则优先于公共 Profile。README 还必须展示 `context/`、`projects/`、`prompts/`、`references/`、`skills/`、`archive/` 的用途和 `inbox/` 到正式知识再到归档的生命周期。

README 必须分别说明 macOS/Linux/WSL 的 Shell 用法与 Windows PowerShell 用法。Windows 支持只有在 Windows CI 通过后才能标记为“已验证”；Ubuntu 作业作为 Linux 与 WSL 的 POSIX 脚本等价验证，不能声称覆盖 Windows 文件系统权限差异。

- [ ] **Step 3: 运行本机完整验证**

Run: `sh tests/test-content.sh && sh tests/test-install-macos.sh && sh tests/test-validate.sh`

Expected: 三项全部通过且退出码为 0。

- [ ] **Step 4: 检查计划需求覆盖和工作区**

Run: `git status --short && git diff --check && git log --oneline --decorate -8`

Expected: 只有本任务预期文件；`git diff --check` 无输出；提交信息均为具体中文概要。

- [ ] **Step 5: 提交 CI 与使用说明**

```bash
git add .github/workflows/validate.yml README.md
git commit -m "完善跨平台验证和使用说明"
```

- [ ] **Step 6: 推送前停下并报告**

报告当前分支、本地未推送提交数量、远程地址和目标分支，等待用户明确回复“推送”后才执行 `git push`。

## 实施记录（2026-09-20）

- 内容层、工具入口、Skills、Playbooks、macOS 安装卸载、敏感信息校验、更新脚本、Windows PowerShell 脚本和三平台 CI 已写入本地提交。
- macOS 本机已验证：内容契约、dry-run、重复安装、受管区块、备份、冲突保护、失败回滚、卸载和安全扫描全部通过。
- Windows 脚本已纳入 POSIX 敏感信息扫描和 GitHub Actions；当前 Mac 未安装 PowerShell，Windows 行为测试仍需 Windows CI 实机结果确认。
- 本次未执行 `git push`；等待用户明确确认后再推送到远程仓库。

## 计划自检

- 设计中的 Context、核心规则、技术栈 Profile、项目卡片、Prompts、参考资料、归档、工具适配、Skills、Playbooks、候选区、模板、macOS/Windows 安装、卸载、更新、敏感信息检查和三平台 CI 均有对应任务。
- 内容层明确区分自动加载的短规则与按需读取的项目、参考、Prompt 和归档资料；没有任何适配器、Profile 或 Skill 自动引用 `archive/`。
- 所有脚本行为先有失败测试；Markdown 与配置文件由内容契约测试先行约束。
- 本计划包含五份近期活跃项目的人工脱敏卡片，但不包含自动扫描全部历史项目、图形界面、团队权限或更多工具适配。
- Windows 行为测试需要在 Windows 或 GitHub Actions 执行；当前 Mac 未安装 PowerShell，因此本地完成声明必须明确区分已验证的 macOS 行为和待 CI 验证的 Windows 行为。Linux CI 只证明 WSL 可复用的 POSIX 路径，不替代实际 WSL 用户目录与权限验证。
