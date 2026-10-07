#!/bin/bash
# 变异测试门(PreToolUse,matcher: Bash)
# 变异测试会反复改源码再还原。它在某棵树上跑着时,对这棵树的构建 / 合并 / 切换会读到被改过的源码,
# 或者把还原前的状态合进去。这个门拦掉这类命令。
#
# 约定:变异 runner 开跑时在仓库根写 .mutation-running(内容 = runner 的 pid),正常结束时删掉。
#   锁在、pid 活着   → 拦(变异在跑)
#   锁在、pid 已死   → 也拦(变异被中断,工作区可能留着没还原的变异;先检查再手动删锁)
#
# 可调:
#   GUARD_MUTATION_CMDS   要拦的命令正则(默认见下)

input=$(cat)
field() { printf '%s' "$input" | python3 -c "import sys,json
d=json.load(sys.stdin)
v=d
for k in sys.argv[1:]:
    v=v.get(k,{}) if isinstance(v,dict) else {}
print(v if isinstance(v,str) else '')" "$@" 2>/dev/null; }

[ "$(field tool_name)" = "Bash" ] || exit 0
cmd=$(field tool_input command)
cwd=$(field cwd)

CMDS="${GUARD_MUTATION_CMDS:-xcodebuild|swift build|cargo build|go build|npm run build|pnpm build|yarn build|gradle|(^|[;&| ])make( |$)|git( +-[Cc] +[^ ]+)* +(merge|checkout|switch|reset|rebase|stash|pull|cherry-pick)}"
printf '%s' "$cmd" | grep -qE "$CMDS" || exit 0

# 候选树:cwd 所在的仓库 + 命令里出现的每个路径所在的仓库(cd <dir> / git -C <dir> / 绝对路径)
trees=""
add_tree() {
  local p="$1"
  p="${p/#\~/$HOME}"
  [ -e "$p" ] || return 0
  [ -d "$p" ] || p=$(dirname "$p")
  local top; top=$(git -C "$p" rev-parse --show-toplevel 2>/dev/null) || return 0
  case " $trees " in *" $top "*) ;; *) trees="$trees $top" ;; esac
}
[ -n "$cwd" ] && add_tree "$cwd"
for tok in $(printf '%s' "$cmd" | grep -oE "(~|/)[^[:space:];&|'\"]+"); do add_tree "$tok"; done

for t in $trees; do
  lock="$t/.mutation-running"
  [ -f "$lock" ] || continue
  pid=$(tr -dc '0-9' < "$lock")
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    echo "⛔ 变异测试正在 $t 上跑(pid $pid),这条命令会碰这棵树(构建 / 合并 / 切换)。等它跑完,或换一个 worktree。" >&2
  else
    echo "⛔ $t 有变异锁但 runner(pid ${pid:-?})已不在:变异可能被中断,工作区也许留着没还原的改动。先 git status / git diff 检查,确认干净后再手动删掉 $lock。" >&2
  fi
  exit 2
done
exit 0
