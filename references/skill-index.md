# Codex 任务路由索引

本索引由 Codex 入口直接引用，不依赖另一个按需 Skill 才能发现它。只选择解决当前任务所需的资料；同一条任务通常读取一个主 Playbook 和少数专项 Skill。

| intent | 适用表达 | 主 Playbook | 按需 Skills / Profile | 典型产物与门槛 |
| --- | --- | --- | --- | --- |
| consult | 解释、比较、怎么做 | `playbooks/answer-question.md` | 相关 Reference/Profile；明确要求对需求/方案/设计进行压力测试时使用内置澄清方法 | 直接答复；显式压力测试仍保持只读 |
| onboarding | 接手、熟悉、分析项目 | `playbooks/start-new-project.md` | `project-onboarding`；匹配的项目卡和 Profile | 规则入口、Git 现场、技术栈、验证命令；只读 |
| bug | 报错、回归、异常行为 | `playbooks/fix-bug.md` | `project-onboarding`、`debugging`、`targeted-verification`；匹配 Profile | 复现/根因证据、最小修复、回归验证 |
| feature | 新增、支持、调整行为 | `playbooks/full-development-lifecycle.md` | `project-onboarding`、`targeted-verification`、`code-review`；匹配 Profile；按需使用内置需求压力测试 | 先分析并等待用户确认；确认后才实施 |
| review | 审核、Review、检查差异 | `playbooks/review-change.md` | `code-review`；必要时 `targeted-verification` | 只读，按严重程度列问题与证据 |
| delivery | 提交、推送、合并、发布 | `playbooks/git-delivery.md` | `git-delivery`、必要时 `targeted-verification` | 分支、工作区、提交与远程摘要；推送必须有当前任务授权 |
| knowledge | 总结经验、沉淀规则 | `playbooks/extract-project-knowledge.md` | `extract-project-knowledge` | 脱敏候选，说明适用范围和证据 |

## Skill 元数据

| Skill | 触发条件 | 不适用 | 输入与输出 |
| --- | --- | --- | --- |
| `project-onboarding` | 对项目不熟或任务需确认项目规则 | 简单概念问答 | 规则、Git 状态、入口、真实命令 → 接手摘要 |
| `debugging` | 有异常现象、错误或失败测试 | 纯功能构想 | 环境/复现/日志 → 根因证据和回归验证 |
| `code-review` | 用户要求审查或合并前检查 | 仅要求实施且未要求审查 | diff/基线 → 有位置和影响的问题清单 |
| `targeted-verification` | 功能、修复或完成前验证 | 无改动的简单问答 | 差异/配置 → 最低充分验证矩阵 |
| `git-delivery` | 准备提交、推送或发布 | 普通编码阶段 | 分支/状态/目标 → 交付摘要和授权门槛 |
| `extract-project-knowledge` | 用户要求沉淀可复用经验 | 一次性临时事实 | 证据/反馈 → 脱敏候选 |
| `cross-platform-contract` | 存在多个端实现的共享协议 | 单端独立逻辑 | 调用方和各端实现 → 协议差异矩阵 |

## 辅助资料

- 新建需求记录：`templates/requirement-card.md`
- 大需求单文件记录：`templates/large-task-record.md`（需求、深入分析、方案、任务、验证和审查写在同一份 Markdown 文件中）
- 改动设计章节参考：`templates/change-design.md`（Large 放入单文件记录）
- 可执行任务章节参考：`templates/task-plan.md`（Large 放入单文件记录）
- 真实验证结果章节参考：`templates/verification-report.md`（Large 默认写入单文件记录，不另生成验证文件）
- 跨会话暂停与恢复：`templates/session-handoff.md`（Large 追加到单文件记录，不另生成交接文件）
- 开发闭环：`playbooks/full-development-lifecycle.md`

## 内置需求压力测试

功能需求存在会改变实现、风险或验收的关键未知项，或用户明确要求深入把关时，按 `core/task-routing.md` 的“按需需求压力测试”处理。用户明确要求对需求/方案/设计进行压力测试时，无论原任务意图如何都可启用；保留原任务意图和授权边界。先用当前可用工具核实事实，再一次问一个重要决策并给出推荐默认方案；小而明确的任务默认跳过，但用户明确要求时例外。它是仓库内的工作方法，不是外部 Skill，不调用或安装 `grill-me` / `grilling`。

索引只是选择依据，不替代阅读所选 Skill 的完整正文。Skills 与 Playbooks 随 Dev Brain 一并提供，不下载外部流程框架或技能包。
