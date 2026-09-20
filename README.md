# Dev Brain

个人长期上下文、项目知识、工作流程、提示词和 AI 编程工具知识库。

## 目录

- `context/`：个人协作偏好和工作方式。
- `core/`：所有项目共享的工程底线。
- `profiles/`：Vue/TypeScript、Flutter、Java 和跨端桥接的验证约定。
- `projects/`：经过脱敏的项目知识卡片。
- `playbooks/`：完整处理流程。
- `prompts/`：可复制到 Codex、Cursor 或 Claude 的提示词。
- `references/`：技术资料、常见配置和工具加载说明。
- `skills/`：可重复执行的 Codex 工作流。
- `inbox/`：尚未验证的候选知识。
- `archive/`：过期或被替代的历史知识。

## 安装

macOS、Linux 或 WSL：

```bash
sh scripts/install.sh --dry-run
sh scripts/install.sh
sh scripts/validate.sh
```

Windows PowerShell：

```powershell
pwsh -NoProfile -File .\scripts\install.ps1 -DryRun
pwsh -NoProfile -File .\scripts\install.ps1
pwsh -NoProfile -File .\scripts\validate.ps1
```

安装后重启 Codex、Cursor 和 Claude，或新建会话验证加载结果。

## 更新

更新脚本只在仓库工作区干净时执行 `git pull --ff-only`。任何推送都必须由用户明确确认。

```bash
sh scripts/update.sh
```

```powershell
pwsh -NoProfile -File .\scripts\update.ps1
```

## 知识生命周期

新经验先进入 `inbox/`，人工核验后进入 `context/`、`core/`、`profiles/`、`projects/`、`skills/`、`prompts/` 或 `references/`；失效或被替代后进入 `archive/`，归档内容不自动加载。

## 安全

私有仓库也禁止保存密码、Token、Cookie、证书、私钥、生产数据和客户资料。项目知识必须脱敏，真实本机路径写入被 Git 忽略的 `local/project-map.md`。
