#!/bin/bash
# release.sh — harness-kit 模板一键发布:源仓库 → marketplace → GitHub
#
# 焊掉四层分发链里的两条人肉 seam:
#   ~/harness-kit(源,唯一手改点) --①rsync--> claude-plugins 本地 clone
#   --②bump patch + 双仓库 commit+push--> GitHub --③用户 /plugin update--> cache(运行时)
#   本脚本自动化 ①②;③是交互命令,收尾打印指令 + installPath 终审探针。
#
# 用法:
#   scripts/release.sh --check          # 只报 drift + 清单表守卫,不改任何东西
#   scripts/release.sh "一句发布说明"     # 完整发布
#
# 前提约定(2026-07-08 回灌对齐后生效):
#   - 源仓库 templates/ 是唯一 canonical;不要再直接改 marketplace 那份
#   - 新增模板文件必须先登进 marketplace SKILL.md 复制清单表(守卫会拦)
#
# 自证输出:RELEASE-OK <版本> / NOTHING-TO-RELEASE / DRIFT-... / ABORT-...(exit≠0)
set -euo pipefail

SRC_REPO="$HOME/harness-kit"
SRC="$SRC_REPO/templates"
MP_REPO="$HOME/.claude/plugins/marketplaces/libaoming"
MP="$MP_REPO/plugins/harness-kit/skills/harness-init/templates"
PLUGIN_JSON="$MP_REPO/plugins/harness-kit/.claude-plugin/plugin.json"
SKILL_MD="$MP_REPO/plugins/harness-kit/skills/harness-init/SKILL.md"

abort() { echo "ABORT-$1" >&2; exit 1; }

[ -d "$SRC" ] || abort "no-source-templates:$SRC"
[ -d "$MP" ] || abort "no-marketplace-templates:$MP"
[ -f "$PLUGIN_JSON" ] || abort "no-plugin-json"
command -v python3 >/dev/null || abort "need-python3"

# ── 守卫:templates/ 下每个文件都必须在 SKILL.md 清单/正文里被提到 ────────────
# (2026-07-07 教训:DEFINITION_OF_DONE.md 放进 templates 但没登清单 = 孤岛,
#  harness-init 永远不会产出它)
manifest_guard() {
  local missing=0 f base
  while IFS= read -r f; do
    base=$(basename "$f")
    if ! grep -q "$base" "$SKILL_MD"; then
      echo "  ✗ 未登记: templates/${f#$SRC/} —— 先写进 SKILL.md 复制清单表,否则是孤岛" >&2
      missing=1
    fi
  done < <(find "$SRC" -type f ! -name '.DS_Store')
  return $missing
}

drift_report() {
  if diff -rq "$SRC" "$MP" >/dev/null 2>&1; then
    echo "drift: 无(两侧 IDENTICAL)"
    return 0
  else
    echo "drift:"
    diff -rq "$SRC" "$MP" | sed 's/^/  /'
    return 1
  fi
}

# ── --check:只读体检 ──────────────────────────────────────────────────────────
if [ "${1:-}" = "--check" ]; then
  echo "■ release 体检(只读)"
  drift_report || true
  echo "清单表守卫:"
  if manifest_guard; then echo "  ✓ templates/ 全部已登记"; fi
  echo "版本: $(python3 -c "import json;print(json.load(open('$PLUGIN_JSON'))['version'])")"
  echo "源仓库脏文件: $(cd "$SRC_REPO" && git status --porcelain | wc -l | tr -d ' ')"
  echo "市场仓库脏文件: $(cd "$MP_REPO" && git status --porcelain | wc -l | tr -d ' ')"
  exit 0
fi

MSG="${1:-}"
[ -n "$MSG" ] || abort "need-message:用法 scripts/release.sh \"发布说明\"(或 --check)"

# ── 前置守卫 ──────────────────────────────────────────────────────────────────
# 市场仓库必须干净:发布 commit 只含本次同步,不夹带手改
[ -z "$(cd "$MP_REPO" && git status --porcelain)" ] || \
  abort "marketplace-dirty:先处理 $MP_REPO 的未提交改动(不该直接改市场副本)"

manifest_guard || abort "manifest:新模板未登记进清单表"

# 无 drift 且 templates/ 无脏改动 → 没东西可发(其它目录的脏文件与发布无关)
if diff -rq "$SRC" "$MP" >/dev/null 2>&1 && [ -z "$(cd "$SRC_REPO" && git status --porcelain -- templates/)" ]; then
  echo "NOTHING-TO-RELEASE(templates 两侧一致且无未提交改动)"
  exit 0
fi

# ── ① 源仓库 commit(只收 templates/;其它脏文件警告不带走)────────────────────
cd "$SRC_REPO"
OTHER_DIRTY=$(git status --porcelain | grep -v ' templates/' || true)
if [ -n "$(git status --porcelain -- templates/)" ]; then
  git add templates/
  git commit -m "$MSG" -m "Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" >/dev/null
  echo "✓ 源仓库 commit: $(git log --oneline -1)"
fi
SRC_SHA=$(git rev-parse --short HEAD)
[ -z "$OTHER_DIRTY" ] || printf '⚠ 源仓库 templates/ 之外的脏文件未带入本次发布:\n%s\n' "$OTHER_DIRTY"

# ── ② 同步 → bump → 市场 commit ──────────────────────────────────────────────
# 不用 --delete:市场侧若真要删模板,应删源仓库后手动处理,防误删
rsync -a --exclude '.DS_Store' "$SRC/" "$MP/"
diff -rq "$SRC" "$MP" >/dev/null 2>&1 || { drift_report; abort "sync-failed"; }

NEW_VER=$(python3 - "$PLUGIN_JSON" <<'PY'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
a, b, c = d["version"].split(".")
d["version"] = f"{a}.{b}.{int(c)+1}"
open(p, "w").write(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
print(d["version"])
PY
)

cd "$MP_REPO"
git add plugins/harness-kit/
git commit -m "harness-kit $NEW_VER: $MSG" \
  -m "同步自 harness-kit@$SRC_SHA(scripts/release.sh)" \
  -m "Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" >/dev/null
echo "✓ 市场仓库 commit: $(git log --oneline -1)"

# ── push 双仓库 ───────────────────────────────────────────────────────────────
(cd "$SRC_REPO" && git push -q) && echo "✓ push harness-kit"
(cd "$MP_REPO" && git push -q) && echo "✓ push claude-plugins"

echo
echo "RELEASE-OK $NEW_VER"
echo
echo "最后一步(交互,脚本代跑不了):在 Claude Code 里 /plugin 更新 harness-kit 到 $NEW_VER,然后终审:"
echo "  python3 -c \"import json;h=json.load(open('$HOME/.claude/plugins/installed_plugins.json'))['plugins']['harness-kit@libaoming'][0];print('ACTIVE-'+h['version'] if h['version']=='$NEW_VER' else 'STILL-'+h['version'])\""
