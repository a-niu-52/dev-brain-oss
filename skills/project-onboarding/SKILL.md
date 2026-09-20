---
name: project-onboarding
description: 读取项目规则、真实配置、知识入口和验证命令并输出接入摘要。用于刚进入项目或尚不了解项目约定时。
---

# Project Onboarding

按以下顺序执行，不先套用技术栈假设：

1. 记录 `git status`、当前分支、远程和未推送提交，不修改现场。
2. 查找最近的 `AGENTS.md`、`AGENTS.override.md`、`CLAUDE.md`、`CODEBUDDY.md`。
3. 检查 `.codegraph/`、知识库索引、OpenSpec、README 和项目架构文档。
4. 从 `package.json`、`pubspec.yaml`、`pom.xml`、Gradle 与 Makefile 读取真实命令。
5. 选择匹配的 Profile；项目规则与 Profile 冲突时项目规则优先。
6. 按需读取匹配的 `projects/` 项目卡片，不读取无关项目或历史资料。
7. 输出入口、技术栈、目标分支、风险、验证命令和仍需确认的问题。

禁止在接入阶段修改文件或执行推送。
