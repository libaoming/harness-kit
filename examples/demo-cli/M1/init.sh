#!/bin/bash
# demo-cli · M1 环境自检。新 session 进来先跑，几分钟内知道能不能接着干。
# 约定：✓ 通过 / ⚠ 警告（可继续）/ ✗ 失败（须先修）。退出码非 0 表示有 ✗。
set -u
OK=0; WARN=0; FAIL=0
ok(){ echo "  ✓ $1"; OK=$((OK+1)); }
warn(){ echo "  ⚠ $1"; WARN=$((WARN+1)); }
fail(){ echo "  ✗ $1"; FAIL=$((FAIL+1)); }

echo "[1/4] 运行时"
command -v python3 >/dev/null && ok "python3: $(python3 -V 2>&1)" || fail "缺 python3"

echo "[2/4] 依赖"
python3 -c "import markdown_it" 2>/dev/null && ok "markdown-it-py" || fail "缺 markdown-it-py（pip install markdown-it-py）"
python3 -c "import weasyprint" 2>/dev/null && ok "weasyprint" || warn "缺 weasyprint（仅 F02 需要）"

echo "[3/4] fixture"
[ -f fixtures/sample.md ] && ok "fixtures/sample.md 存在" || fail "缺 fixtures/sample.md（fixture 先于代码）"

echo "[4/4] 冒烟"
if [ -f demo_cli/parser.py ]; then
  python3 -c "import demo_cli.parser" 2>/dev/null && ok "parser 可导入" || fail "parser 导入失败"
else
  warn "demo_cli/parser.py 尚未创建（S1 待写）"
fi

echo
echo "结果：$OK 通过 / $WARN 警告 / $FAIL 失败"
[ "$FAIL" -eq 0 ]
