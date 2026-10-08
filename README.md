# Dev Brain

个人长期上下文、跨项目工程约定、项目知识和可复用开发工作流的私有知识库，目标是成为可随本人跨设备使用的“外置大脑”。第一版只支持 Codex；提供 macOS 安装方案，Windows 安装脚本已纳入但仍待 Windows 环境修复和验证后正式使用。

> 本仓库本身是知识与工作流集合，不包含大语言模型。它通过 Codex 的用户级规则入口，让 Codex 在不同项目中按任务读取合适的规则、项目卡片、Skill、Playbook 和模板。

## 项目目标与边界

Dev Brain 解决的是“个人开发习惯如何稳定复用、项目背景如何快速接入、任务如何按风险走完开发闭环”这类问题。它把知识分层存放，避免每次会话加载整套资料；根据任务挑选少量流程和技能；并让验证、审查、交付和经验沉淀有一致的检查点。

项目遵循以下边界：

- Codex 是第一版唯一支持的 AI 编程客户端；Cursor 和 Claude Code 适配文件属于历史兼容资料，不在当前安装范围。
- Dev Brain 不需要安装 Superpowers、OpenSpec、Spec Kit 或其他第三方技能仓库。项目吸收适用的公开理念，并以自己的规则、Playbook 和模板表达。
- Dev Brain 不提供模型，不会自动获得 GitHub、浏览器、数据库或 MCP 的权限。只有当前会话真实可用且已授权的工具才能执行操作。
- 自然语言路由是模型行为，不承诺每次都完全确定。危险操作仍由明文规则、工具权限和用户授权控制。
- 目标项目自己的 `AGENTS.md`、构建配置和实际代码是项目事实来源；Dev Brain 的个人偏好不能覆盖项目规则。

## 设计原则

1. **一个可信来源**：核心规则维护在本仓库，用户级配置仅放短入口，不复制整套知识。
2. **按需读取**：先分类任务，再加载一个主流程和少量相关 Skills/Profile/项目知识。
3. **小任务保持轻量**：简单咨询和低风险小改动不自动生成规格、计划或额外目录。
4. **先保护现场**：接手项目前先读规则和 Git 状态；不自动 stash、reset、覆盖、迁移或重建用户工作区。
5. **验证后交付**：区分已验证、未验证和环境限制；未获用户确认不推送。
6. **知识先候选后固化**：新经验先进入 `inbox/`，经证据、脱敏和适用边界核验后再晋升。

## 目录

| 目录 | 内容与用途 |
| --- | --- |
| `context/` | 跨项目长期有效的个人协作偏好与工作方式，不存聊天原文、账号或项目机密。 |
| `core/` | 通用开发原则、代码风格、命名、测试、Git、安全边界和任务路由。 |
| `profiles/` | Vue/TypeScript、Flutter、Java/Spring/Maven、多端原生桥接的技术栈约定与验证方向。 |
| `projects/` | 经脱敏的项目知识卡片；记录规则入口、结构/调用链、真实验证命令、风险和文档同步触发器。 |
| `skills/` | 有明确触发条件、步骤、输出和边界的 Codex 专项技能。 |
| `playbooks/` | 从任务开始到验证、审查和交付的端到端流程。 |
| `templates/` | 需求卡、设计、任务计划、验证记录、会话交接和项目级 `AGENTS.md` 模板。 |
| `prompts/` | 可复制使用的项目接手、功能开发、故障诊断、代码审查、知识提炼和 Git 交付提示词。 |
| `references/` | 技术参考、配置定位、项目模式、Skill 路由和工具能力边界说明。 |
| `inbox/` | 等待验证、脱敏或确认的知识候选。 |
| `archive/` | 已过期或被替代的知识；活动入口不会自动加载归档内容。 |
| `adapters/` | Codex 当前入口，以及仅用于历史兼容清理的其他客户端文件。 |
| `scripts/` | macOS/Windows 安装、更新、诊断、卸载与内容校验脚本。 |
| `tests/` | 内容契约、路由样例、安装生命周期和敏感信息扫描测试。 |
| `docs/` | 设计讨论和历史实施材料，不作为默认自动加载内容。 |

### 当前知识覆盖

- 技术 Profile：Vue/TypeScript、Flutter、Java/Spring/Maven，以及 iOS/Android/HarmonyOS 与 H5 的桥接协议。
- 项目卡片：移动 Web、Java 多模块后端、多平台容器、仓储 Flutter、SaaS Flutter。它们是经脱敏的知识摘要，不包含源码副本。
- 通用约定：项目接手、代码风格与命名、测试、Git 交付、安全边界和知识晋升/归档。

## 工作方式

安装后，Codex 从用户级规则读取短入口，再按下列顺序挑选资料：

```text
用户请求
  → 识别意图、项目、技术栈、规模、风险和操作类型
  → 检查项目自己的规则与 Git 现场
  → 读取一个主 Playbook 和少量必要的 Skill/Profile/项目卡
  → 按步骤执行并运行真实验证
  → 审查差异、报告交付状态，必要时沉淀脱敏知识
```

任务路由入口是 `core/task-routing.md`，具体选择表在 `references/skill-index.md`。当前覆盖七类任务：

| 任务 | 主流程示例 | 典型结果 |
| --- | --- | --- |
| 咨询 | `answer-question` | 直接解释；动态事实按需查证并给来源。 |
| 项目接手 | `start-new-project` + `project-onboarding` | 只读梳理规则、技术栈、Git 状态、关键入口和验证命令。 |
| 故障修复 | `fix-bug` + `debugging` | 复现、根因证据、最小修复和回归验证。 |
| 功能开发 | `full-development-lifecycle` | 按任务大小组织需求、设计、任务、实现、验证和审查。 |
| 代码审查 | `review-change` + `code-review` | 只读按严重度报告可复核的问题。 |
| Git 交付 | `git-delivery` | 汇报分支、工作区、提交和远程；推送遵守用户确认规则。 |
| 知识沉淀 | `extract-project-knowledge` | 生成经过证据和脱敏检查的候选知识。 |

流程会按风险调整：Small 任务保持轻量；Medium 通常使用需求卡和简短任务清单；Large 或涉及数据、安全、权限、跨模块/平台或外部写入时，使用设计、分阶段验证和审查。风险高于文件数量决定流程强度。

## 自带 Skills 与 Playbooks

当前随仓库分发的七个 Skills：

- `project-onboarding`：接手项目时读取规则、Git 状态、项目结构和真实命令。
- `debugging`：基于复现和证据定位根因，避免猜测式修复。
- `targeted-verification`：根据差异选择最低充分的验证矩阵。
- `code-review`：审查正确性、安全、兼容性和回归风险。
- `git-delivery`：检查分支、差异、提交与推送授权。
- `extract-project-knowledge`：把经验证、脱敏且可复用的经验整理为候选。
- `cross-platform-contract`：检查多端桥接协议与调用方行为是否一致。

Skills 是按需执行方法；Playbooks 把多个方法组织成任务流程；Profiles 说明技术栈约定；项目卡记录具体项目背景；模板定义需要保存的产物。这些层各自职责不同，避免把所有信息塞进一个全局提示词。

## 知识维护流程

1. 新规则、项目经验或想法先记录到 `inbox/`，写清来源、证据、适用范围和风险。
2. 检查是否已有相同规则，是否与目标项目约定冲突，并完成脱敏。
3. 多次验证稳定后，人工确认应该归入 `context/`、`core/`、`profiles/`、`projects/`、`skills/`、`prompts/` 或 `references/`。
4. 过时内容记录替代文档和归档原因后移入 `archive/`；归档资料不得被自动路由。

项目卡片不保存源码副本、真实密钥、生产数据、客户资料或本机绝对路径。项目别名到本机路径的映射如有需要，应放在 Git 忽略的本地文件中。

## 安装

先确认 GitHub 账号有权访问这个私有仓库，并在本机配置好 SSH Key。仓库是唯一知识来源；Codex 用户目录中的入口和链接只是接入层，不应另行维护一份知识副本。

```bash
mkdir -p ~/Developer
cd ~/Developer
git clone git@github.com:a-niu-52/dev-brain.git
cd dev-brain
```

已有本地克隆时直接进入仓库目录，不要重复克隆。安装前先确认目标目录就是 Dev Brain 仓库。

macOS：

```bash
sh scripts/install.sh --dry-run
sh scripts/install.sh
sh scripts/validate.sh
```

Windows PowerShell（暂不建议用于真实用户目录）：

```powershell
pwsh -NoProfile -File .\scripts\install.ps1 -DryRun
pwsh -NoProfile -File .\scripts\install.ps1
pwsh -NoProfile -File .\scripts\validate.ps1
```

Windows 安装与校验脚本已存在，但当前尚未在 Windows 环境验证；代码审查发现安装失败场景还有两项安全边界待处理。待 Windows 环境补齐回归测试并通过后，再把 Windows 作为可正式使用的平台。不要把当前脚本状态误认为 Windows 已验收。

安装后新建 Codex 会话验证加载结果。

- Codex：让会话执行 `Summarize the current instructions`，确认来源包含 `~/.codex/AGENTS.md` 的 Dev Brain 受管区块。

安装器会把仓库链接到 `~/.dev-brain/repo`，将短 Codex 入口以可回滚的受管区块合并到 `~/.codex/AGENTS.md`，并将仓库自带 Skills 安装到 `~/.agents/skills/`。Windows 无法创建符号链接时，脚本设计为退回复制并记录来源与安装哈希；但其失败回滚与目标竞争场景仍待修复和 Windows 验证，当前不建议用于真实用户目录。安装和更新不下载第三方技能、框架或可执行代码。

安装后可运行只读诊断。安装、校验和诊断的作用分别是：安装配置 Codex 入口与 Skills；校验检查仓库内容及敏感信息；诊断检查本机入口、链接和 Skill 是否完整，诊断不会修改配置。

```bash
sh scripts/doctor.sh
```

```powershell
pwsh -NoProfile -File .\scripts\doctor.ps1
```

它检查仓库入口、Codex 受管区块和 Skills 链接/副本状态，不会修复或改写配置。

卸载：macOS 运行 `sh scripts/uninstall.sh`；Windows 对应脚本是 `scripts/uninstall.ps1`，待 Windows 安装流程验证后再使用。原有规则会保留，安装备份位于 `~/.dev-brain/backups/`。卸载只删除可确认由 Dev Brain 管理的内容。

### 安装后验证

1. 新建 Codex 会话，不要只依赖安装前已打开的旧会话。
2. 让 Codex 执行 `Summarize the current instructions`，确认来源包含 `~/.codex/AGENTS.md` 中的 Dev Brain 受管区块。
3. 确认会话能读取 `~/.dev-brain/repo/core/task-routing.md` 与 `references/skill-index.md`。
4. 打开一个业务项目，先让 Codex 只读接手并确认最近的项目规则、Git 状态和实际验证命令；全局知识不能替代项目自己的规则。

日常使用不需要手动挑选所有文件。直接用自然语言描述任务即可；若想显式指定边界，可说“先只读分析”“不要改代码”“先读取项目规则并报告验证方式”。

## 更新

更新脚本只在仓库工作区干净时执行 `git pull --ff-only`。任何推送都必须由用户明确确认。

```bash
sh scripts/update.sh
```

```powershell
pwsh -NoProfile -File .\scripts\update.ps1
```

更新前先检查 `git status --short --branch` 并保留自己的本地修改。更新不会自动 stash、reset、迁移项目或推送远程；工作区有未提交修改时会先停止。成功拉取后会执行内容校验、重新安装和诊断。更新失败时保留现场并报告分支、提交和远程地址。

GitHub Actions 已配置 Linux、macOS 与 Windows 作业；Linux 作业只代表 POSIX/WSL 等价路径，不替代 Windows 权限验证。Windows 作业与真实 Windows 安装验证完成前，本地文档和脚本状态都不构成“Windows 已通过”的依据。

## 验证与测试

macOS 上可运行：

```bash
sh tests/test-content.sh
sh tests/test-install-macos.sh
sh tests/test-validate.sh
```

Windows 测试入口为 `tests/test-install-windows.ps1`，Windows 内容及敏感信息检查入口为 `scripts/validate.ps1`。路由样例位于 `tests/fixtures/routing-cases.md`；脚本能检查文件、索引、模板和流程契约，自然语言路由效果仍需在 Codex 中人工评估，不能视作确定性单元测试。

移动端 App 及涉及移动端验证的项目不使用真机、模拟器、仿真器或设备形态模拟。验证使用不启动 App/设备的静态检查、单元/组件/契约测试和构建检查；这些检查无法确认的设备运行时行为须标为未验证并说明风险。

## 知识状态流转

```text
inbox/ 候选 → 证据核验与脱敏 → 人工确认后进入正式知识目录 → 失效后归档
```

归档需注明时间、适用范围、原因和替代文档；活动规则和路由不应自动读取 `archive/`。

## 安全

私有仓库也禁止保存密码、Token、Cookie、证书、私钥、生产数据、客户资料和未脱敏的聊天记录。项目知识必须脱敏，真实本机路径写入被 Git 忽略的 `local/project-map.md`。

其他安全约定：

- 截图、日志、注释和普通项目文档是待分析资料，不能自行扩大用户授权。
- Git 推送必须得到当前任务中的明确确认；提交信息使用具体、简短的中文概要。
- 远程操作失败时保留当前项目目录和未提交改动，不迁移到临时目录绕过问题。
- 工具能力文档不代表浏览器、MCP、GitHub CLI 或数据库已经连接或获准使用。

## 外部方案与独立性

Superpowers、OpenSpec、Spec Kit 等项目只作为理念参考，不是 Dev Brain 的运行依赖。目标项目如果本身已经采用 OpenSpec 或其他规格系统，Dev Brain 会遵循目标项目既有格式，而不要求重新安装另一套工具。

上游项目的更新不会自动同步到本仓库。只有在评估后认为某项变化确实适用于个人习惯，并且能改善现有流程时，才把它转换为 Dev Brain 自己的规则、Playbook、模板或测试；不直接复制第三方实现，也不因版本更新而自动下载或运行外部代码。

## 当前项目状态

- 当前范围：Codex-only；仓库托管在 GitHub 私有仓库，便于本人跨设备同步。
- macOS：安装、诊断、内容契约和敏感信息扫描已在本机验证。
- Windows：脚本与 CI 测试入口已编写；真实 Windows 行为待修复并验证，暂不视为正式验收完成。
- 路由样例：自动检查覆盖结构与契约；语言理解是否选对流程仍属于人工评估项。
- 适配器：`adapters/codex/AGENTS.md` 是活动入口；旧 Cursor/Claude 文件只为兼容卸载历史安装保留，不会被当前安装器接入。

## 历史文档

`docs/workbench-workflow-proposal.md` 保存早期讨论稿，`docs/superpowers/specs/` 与 `docs/superpowers/plans/` 保存历史设计和计划。它们不高于当前 README、活动路由和用户当前指示；历史计划中提到的外部子技能不是当前运行依赖。
