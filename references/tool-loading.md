# 工具加载说明

## Codex

Codex 从用户级 `~/.codex/AGENTS.md` 读取全局规则，再按项目目录向下合并更近的 `AGENTS.md`。Skill 用户入口位于 `~/.agents/skills/`。

## Cursor

Cursor 通过用户规则入口读取 `adapters/cursor/dev-brain.mdc` 的内容。规则文件变化后重启或重新加载规则面板。

## Claude Code

Claude 通过个人指令文件中的 `@` 导入稳定仓库入口。导入路径由安装器创建的 `~/.dev-brain/repo` 提供。

## 验证

安装或更新后新建会话，要求工具列出当前加载来源；如果规则未变化，先确认会话是否已经重启。
