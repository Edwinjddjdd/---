# 阶段三：入口同步与验证

## 目标

- 让新目录成为阶段一唯一入口，并保证仓库内链接完整。

## 任务

1. 更新 `README.md`、`docs/SUMMARY.md`、路线图和规格草案中的旧路径。
2. 检查所有 Markdown 相对链接。
3. 检查新增文档的中文编号、LaTeX 公式和来源表。

## 验收标准

- 仓库中不再引用 `docs/research/`。
- 本地 Markdown 链接检查通过。
- `git diff --check` 通过。

## 验证

- `rg -n "docs/research|research/" -g "*.md" .`
- 本地 Markdown 链接解析脚本。
- `git diff --check`

## 退出条件

- 入口、交叉链接和格式检查全部通过。
