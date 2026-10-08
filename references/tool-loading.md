# Codex 规则与 Skill 加载说明

第一版只支持 Codex。客户端位置或加载行为改变时，更新前先核对 Codex 官方文档。适配器只保留短入口，不复制知识库全文。

## 用户级规则

Codex 从用户级 `~/.codex/AGENTS.md` 读取全局规则，再按项目目录向下合并更近的 `AGENTS.md`。Dev Brain 以固定标记管理注入区块，保留文件中的其他内容。

## Skills

用户级 Skills 位于 `~/.agents/skills/<skill>/SKILL.md`；Dev Brain 以链接方式安装每个自带 Skill，目录名与 Skill 的 `name` 一致。Windows 不支持链接时，安装器使用带哈希清单的副本。

## 会话验证

安装或更新后创建新 Codex 会话，确认来源包含 `~/.codex/AGENTS.md` 中的 Dev Brain 区块，并能读取 `~/.dev-brain/repo/core/task-routing.md` 与匹配 Skills。不要把旧会话已加载的规则当作新版本的验证。
