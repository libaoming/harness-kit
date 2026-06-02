# STATUS — demo-cli

> 每次新 session 第一个读，收尾必更新。

## 一句话状态

2026-06-02 **S1 进行中**：Markdown 解析（F01）已 `passing`，PDF 渲染（F02）渲染器接好、分页规则待核对真实样本。`md → PDF` 主链路差最后一步即可端到端跑通。

## 下次入口

1. 读本文件 → `M1/PROGRESS.md`
2. 跑 `bash M1/init.sh` 确认环境全绿（依赖 / fixture / 冒烟）
3. 继续 F02：用 `fixtures/sample.md` 核对 PDF 分页，页数对得上基准就把 `features.json` 里 F02 改 `passing`
4. 改解析逻辑改 `demo_cli/parser.py`；改排版改 `demo_cli/renderer.py`

## 关键事实

- 栈：Python 3.11+ / `markdown-it-py`（解析）/ `weasyprint`（渲染）
- 入口：`python -m demo_cli input.md -o out.pdf`
- fixture：`fixtures/sample.md`（含标题/列表/代码块/链接，一份养 F01+F02 两条 verify）

## 踩坑清单

- weasyprint 中文字体要显式指定，否则 CJK 丢字
- 代码块超长不换行会溢出页面 —— 排版规则需处理
