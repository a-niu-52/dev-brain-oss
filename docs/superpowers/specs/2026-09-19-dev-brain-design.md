# Dev Brain 设计说明

> 范围说明（2026-09-25）：本文记录初始设计。当前第一版实施范围已收窄为 Codex-only（macOS 与 Windows）；下方旧版其他客户端适配描述不属于当前安装、验证或支持范围。

## 1. 目标

建立一个托管在 GitHub 私有仓库中的个人 AI 开发工作台，作为跨电脑、跨项目、跨 AI 编程工具复用的“外置大脑”。它沉淀个人长期上下文、稳定开发习惯、代码规范、命名原则、Git 流程、提示词模板、可执行工作流、技术参考和经过脱敏的项目经验。

第一版需要满足：

- 支持 macOS 和 Windows。
- Codex、Cursor、Claude Code 共用同一份核心知识。
- Codex 能在任务开始前自动加载必要的个人规则。
- 新电脑克隆仓库后，可通过一条安装命令完成配置。
- 更新、安装和卸载都不会破坏已有本机配置。
- 提供可直接复制到不同 AI 工具的提示词模板。
- 首版包含从近期活跃项目提炼的首批脱敏项目知识，而不只是空模板。
- 过期知识可归档且不会被自动加载。
- 所有提交和推送仍由用户审阅和确认。

## 2. 设计原则

1. **单一来源**：通用规则只维护一份，各工具入口只负责适配。
2. **分层加载**：必须始终遵守的规则保持简短，长流程和背景知识按需读取。
3. **个人与项目分离**：个人习惯放在 Dev Brain；项目特有规则留在项目自己的 `AGENTS.md` 等文件中。
4. **先验证再固化**：新经验先进入候选区，经过重复验证后再提升为通用规则。
5. **安全优先**：私有仓库也不得保存密钥、生产数据、客户信息或未经脱敏的业务资料。
6. **可恢复**：安装前备份，失败时回滚，卸载时可恢复原配置。
7. **不擅自推送**：脚本和 AI 都不得绕过用户确认执行远程推送。
8. **描述与规则分离**：`context/` 描述个人长期偏好，`core/` 只保存必须遵守的工程底线。
9. **历史可追溯**：失效知识进入 `archive/`，记录归档时间、原因和替代内容，不直接删除历史依据。

## 3. 仓库结构

```text
dev-brain/
├── README.md
├── context/
│   ├── README.md
│   ├── collaboration-preferences.md
│   └── working-style.md
├── core/
│   ├── development-principles.md
│   ├── coding-style.md
│   ├── naming-conventions.md
│   ├── git-workflow.md
│   ├── testing-rules.md
│   └── security-boundaries.md
├── profiles/
│   ├── vue-typescript.md
│   ├── flutter.md
│   ├── java-spring-maven.md
│   └── multi-platform-bridge.md
├── adapters/
│   ├── codex/AGENTS.md
│   ├── cursor/
│   └── claude/CLAUDE.md
├── skills/
│   ├── code-review/
│   ├── debugging/
│   ├── git-delivery/
│   ├── project-onboarding/
│   ├── extract-project-knowledge/
│   ├── targeted-verification/
│   └── cross-platform-contract/
├── playbooks/
│   ├── start-new-project.md
│   ├── fix-bug.md
│   ├── deliver-feature.md
│   └── extract-project-knowledge.md
├── projects/
│   ├── README.md
│   ├── project-template.md
│   ├── mobile-web.md
│   ├── java-multimodule-backend.md
│   ├── multiplatform-container.md
│   ├── warehouse-flutter.md
│   └── saas-flutter.md
├── prompts/
│   ├── README.md
│   ├── project-onboarding.md
│   ├── feature-development.md
│   ├── bug-diagnosis.md
│   ├── code-review.md
│   ├── knowledge-extraction.md
│   └── git-delivery.md
├── references/
│   ├── README.md
│   ├── project-patterns.md
│   ├── common-configurations.md
│   └── tool-loading.md
├── inbox/
│   └── README.md
├── archive/
│   └── README.md
├── templates/
│   └── project-AGENTS.md
├── security/
│   └── secret-scan-allowlist.txt
├── scripts/
│   ├── install.sh
│   ├── update.sh
│   ├── validate.sh
│   ├── uninstall.sh
│   ├── install.ps1
│   ├── update.ps1
│   ├── validate.ps1
│   └── uninstall.ps1
├── tests/
├── .github/workflows/
└── .gitignore
```

## 4. 内容分层

### 4.1 Context

`context/` 保存跨项目长期有效、但不是工程硬约束的个人信息。第一版包含协作偏好和工作方式，例如默认语言、汇报详略、设计与计划习惯、遇到不确定信息时的处理方式。它不得保存账号、身份材料、聊天原文或项目机密。

Context 默认不整份注入每次会话。工具入口只摘录必须长期生效的少量偏好，其他内容由 `project-onboarding` 或用户明确要求时读取。

### 4.2 Core

`core/` 保存跨项目稳定适用的原则。第一版只写入已经明确的习惯，例如：

- Git 提交使用简短、具体的中文概要。
- 未经用户明确确认，不执行 `git push`。
- 远程访问失败时保留原项目和本地修改，报告现场后等待处理。
- 不使用临时目录替代原项目，不做可能导致修改丢失的迁移或重建。
- 代码命名优先表达业务含义，避免没有上下文的模糊名称。
- 修改应聚焦任务范围，并执行与风险相称的验证。

尚未从真实项目验证的语言级规范，不在第一版中臆测。

### 4.3 Profiles

`profiles/` 保存 Vue/TypeScript、Flutter、Java/Spring/Maven 和多端桥接等技术栈的默认验证顺序、分层习惯与风险检查。Profile 只能在识别真实项目清单后按需选择；项目自己的规则、命令和分支策略始终优先。

### 4.4 工具适配入口

`adapters/` 为不同工具提供轻量入口。入口只放必须自动生效的规则和按需读取指引，不复制完整知识库。

- Codex：把简短受管区块合并进用户级 `~/.codex/AGENTS.md`，Skills 安装到用户级 Skills 目录。
- Cursor：生成或链接其支持的个人规则入口。
- Claude Code：把稳定仓库导入语句合并进个人级指令文件。

实现前应依据各工具当前官方文档确认准确位置和文件格式；适配器不得假设所有工具共享相同语法。

### 4.5 Prompts、Skills 与 Playbooks

- Prompt 是可复制到 Codex、Cursor 或 Claude 的跨工具简短入口。
- Skill 用于 Codex 或其他支持 Skill 的工具可主动选择的重复工作流。
- Playbook 用于人和 AI 按需查阅的详细操作手册。
- 每个 Skill 聚焦一个任务，并明确触发条件、输入、步骤、输出和禁止事项。
- Prompt 不复制整个 Skill 或 Playbook，只说明使用场景、需要填写的输入、预期输出和对应的详细入口。

### 4.6 项目知识、参考资料与生命周期

`projects/` 只保存脱敏后的经验总结，不保存源码副本、真实密钥、生产数据或客户资料。

第一版从近期活跃项目提炼五类项目卡片：移动 Web、Java 多模块后端、多平台容器、仓储类 Flutter 应用和 SaaS 类 Flutter 应用。默认使用安全别名；真实仓库名只有确认不敏感时才可记录，本机绝对路径只能放在被 Git 忽略的 `local/project-map.md`。

每个项目卡片必须记录适用范围、技术栈、规则入口、关键调用链、真实验证命令、高风险区域、已验证约定、文档同步触发器、最后核验日期和脱敏状态。

`references/` 保存脱敏技术资料、常见配置和工具加载说明；它不是强制规则，不应被所有会话自动加载。

`inbox/` 保存尚未验证的新习惯。候选规则只有在多个任务中重复有效、适用边界清楚且没有与现有规则冲突时，才可提升到 `core/`。

`archive/` 保存曾经有效但已经过期或被替代的内容。归档文件必须记录归档时间、原适用范围、归档原因和替代文档；适配器、Profile 与 Skill 不得自动引用 `archive/`。

知识生命周期固定为：

```text
项目实践 → inbox/ → 人工核验
                    ├── 个人长期偏好 → context/
                    ├── 工程硬规则   → core/
                    ├── 技术栈规则   → profiles/
                    ├── 项目知识     → projects/
                    ├── 可执行流程   → skills/ + playbooks/
                    ├── 跨工具入口   → prompts/
                    └── 技术资料     → references/
                                           ↓ 失效或被替代
                                        archive/
```

重要规则采用以下字段：

```markdown
## 规则标题

- 适用范围：规则适用的语言、工具或项目类型
- 规则：需要遵守的具体行为
- 原因：为什么采用该规则
- 例外：允许偏离规则的明确条件
```

## 5. 安装与同步

### 5.1 macOS

使用 Shell 脚本安装、更新、校验和卸载。脚本从自身路径计算仓库位置，不写死用户名或克隆目录。

### 5.2 Windows

Windows 原生环境使用 PowerShell 脚本。WSL 直接复用 Shell 脚本。PowerShell 脚本与 Shell 脚本必须遵循相同的行为契约。

### 5.3 链接策略

- 仓库稳定入口、Cursor 规则和 Skills 优先使用符号链接，使仓库更新立即反映到工具配置。
- Codex 和 Claude 的既有全局文件采用带固定开始、结束标记的受管区块合并，不用符号链接整体替换。
- Windows 无法安全创建符号链接时，使用受控复制并记录清单，以便更新和卸载。
- 不覆盖来源不明的现有文件。
- 仓库位置变化后，可重新运行安装脚本修复链接。

### 5.4 日常更新

1. 修改知识内容。
2. 运行平台对应的校验脚本。
3. 审阅差异。
4. 使用中文提交信息创建本地提交。
5. 用户明确确认后才推送 GitHub。

更新脚本发现工作区存在未提交修改时必须停止，不得自动暂存、丢弃、覆盖或迁移修改。Git 远程操作失败时必须保留现场，并报告当前分支、工作区状态、未推送提交和远程地址。

## 6. 安全边界

- `.gitignore` 排除 `local/`、环境文件、证书、密钥和本机备份目录。
- 提交前检查常见 Token、私钥、密码和敏感配置模式。
- 安全检查命中后默认阻止提交，由用户核实，不自动忽略。
- 项目经验必须先脱敏，使用抽象角色和占位符代替客户、域名、账号和内部地址。
- 安全例外只能同时匹配经过审核的精确相对路径和文件 SHA-256，不允许目录通配。
- GitHub 仓库设为私有，但不能把“私有”当作存储秘密的授权。

## 7. 安装失败、备份与恢复

- 安装脚本支持 `--dry-run`，展示计划创建、链接、复制和备份的路径。
- 修改现有配置前，备份到带时间戳且不进入 Git 的目录。
- 安装过程记录操作清单；中途失败时按清单逆序回滚。
- 遇到来源不明的同名文件或不支持的环境时停止，并给出人工处理建议。
- 卸载只移除本仓库创建的文件或链接，不删除用户后来添加的内容。
- 用户选择恢复时，将安装前备份放回原位置。

## 8. 校验与测试

### 8.1 内容校验

- 必需文件存在。
- Markdown 内部链接有效。
- Skill 元数据包含有效的名称和触发描述。
- 适配器引用的核心文件存在。
- Prompt 包含使用场景、输入占位、预期输出以及对应 Skill 或 Playbook。
- 项目卡片包含最后核验日期、脱敏状态和文档同步触发器。
- 归档内容不被适配器、Profile 或 Skill 自动引用。
- 不存在空规则、占位符或相互冲突的硬性要求。

### 8.2 安全校验

- 检查常见凭据格式、私钥头、环境文件和高风险字段。
- 检查本机绝对路径、真实用户名和不应共享的内部地址。
- 检查项目知识是否包含明显的未脱敏标识。

### 8.3 跨平台测试

GitHub Actions 在 macOS、Windows 和 Ubuntu 运行隔离测试；Ubuntu 只代表 Linux 与 WSL 可复用的 POSIX 脚本路径，不替代真实 WSL 权限验证：

- Shell 与 PowerShell 脚本语法检查。
- 在临时用户目录执行 dry-run、安装、重复安装、更新和卸载。
- 验证安装不会访问真实用户目录。
- 验证已有文件冲突时安全停止。
- 验证安装失败后的回滚结果。

## 9. 第一版验收标准

第一版完成时必须满足：

1. 在全新 macOS 或 Windows 环境克隆私有仓库后，可通过对应的一条安装命令完成配置。
2. Codex 启动新任务时能加载个人通用规则。
3. Cursor 和 Claude Code 能通过各自入口读取同一份核心知识。
4. 更新仓库后，无需在多个入口重复维护规则。
5. 已有配置在安装前得到备份，安装失败不会导致配置丢失。
6. 校验能阻止明显的敏感信息和结构错误进入提交。
7. 所有远程推送都需要用户明确确认。
8. 能从 `context/` 读取个人协作偏好，但默认自动加载内容保持简短。
9. 至少五份首批项目卡片通过脱敏和内容校验。
10. Prompt 可复制到 Codex、Cursor 或 Claude，并指向同一份详细工作流。
11. 知识能从 `inbox/` 提升到正式目录，并在失效后进入 `archive/`，且归档内容不会自动生效。

## 10. 首版之外

以下内容不纳入第一版：

- 自动从所有历史项目批量提炼规则；第一版只人工提炼近期活跃项目的首批卡片。
- 保存完整聊天记录或项目源码副本。
- 自动修改项目级规范并推送。
- 图形化管理界面。
- 团队权限和多人审批流程。
- 除 Codex、Cursor、Claude Code 之外的更多工具适配。

## 11. 依据

- [OpenAI：使用 AGENTS.md 自定义指令](https://developers.openai.com/docs/agent-configuration/agents-md)
- [OpenAI：Codex 自定义机制概览](https://developers.openai.com/docs/customization/overview)
- [OpenAI：创建和加载 Skills](https://developers.openai.com/docs/build-skills)
