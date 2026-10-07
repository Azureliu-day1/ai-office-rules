#!/bin/bash
# 两个钩子的自测:每条断言都有反例(该拦的拦、该放的放)。
# 用法:bash tests/test-hooks.sh     退出码 = 失败条数
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
BRIEF="$HERE/hooks/check-brief.sh"
GUARD="$HERE/hooks/guard-mutation.sh"
pass=0; fail=0

json() { python3 -c 'import sys,json; print(json.dumps(json.loads(sys.argv[1])))' "$1"; }
expect() { # $1 名称  $2 期望退出码  $3 钩子  $4 JSON 输入
  printf '%s' "$4" | bash "$3" >/dev/null 2>&1; local rc=$?
  if [ "$rc" = "$2" ]; then pass=$((pass+1)); echo "✅ $1"; else fail=$((fail+1)); echo "❌ $1(期望 $2,实际 $rc)"; fi
}
agent() { python3 -c 'import sys,json; print(json.dumps({"tool_name":sys.argv[1],"tool_input":{"prompt":sys.argv[2]}}))' "$1" "$2"; }
bashcmd() { python3 -c 'import sys,json; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]},"cwd":sys.argv[2]}))' "$1" "$2"; }

# ---------- check-brief ----------
GOOD=$'推理档 high · 预计 60 分钟 · 退出条件:测试全绿。预计只是预计,不是硬限。\n做 X。'
expect "简报:合格放行"                 0 "$BRIEF" "$(agent Agent "$GOOD")"
expect "简报:旧工具名 Task 也检查"      2 "$BRIEF" "$(agent Task $'做 X')"
expect "简报:非派工工具不管"            0 "$BRIEF" "$(agent Read $'随便')"
expect "简报:缺推理档拦"                2 "$BRIEF" "$(agent Agent $'预计 60 分钟 · 退出条件:绿。')"
expect "简报:缺预计拦"                  2 "$BRIEF" "$(agent Agent $'推理档 high · 退出条件:绿。')"
expect "简报:缺退出条件拦"              2 "$BRIEF" "$(agent Agent $'推理档 high · 预计 60 分钟')"
expect "简报:要素不在第一行拦"          2 "$BRIEF" "$(agent Agent $'做 X。\n推理档 high · 预计 60 分钟 · 退出条件:绿')"
expect "简报:前导空行不算第一行"        0 "$BRIEF" "$(agent Agent $'\n\n'"$GOOD")"
expect "简报:英文第一行也认"            0 "$BRIEF" "$(agent Agent $'effort high · estimate 30 min · exit criteria: tests green')"
expect "简报:用量上限拦"                2 "$BRIEF" "$(agent Agent "$GOOD"$'\n最多用 50k tokens')"
expect "简报:token 上限拦"              2 "$BRIEF" "$(agent Agent "$GOOD"$'\ntoken 上限 10 万')"
expect "简报:登录令牌意义的 token 放行" 0 "$BRIEF" "$(agent Agent "$GOOD"$'\n刷新 access token 的逻辑放到拦截器里')"
BRIEF_GATE_ALLOW_USAGE_TALK=1 expect "简报:开关打开后用量字眼放行" 0 "$BRIEF" "$(agent Agent "$GOOD"$'\n最多用 50k tokens')"

# ---------- guard-mutation ----------
T=$(mktemp -d); R="$T/repo"; O="$T/other"
git init -q "$R" && git init -q "$O"
expect "变异门:无锁放行构建"            0 "$GUARD" "$(bashcmd 'swift build' "$R")"
sleep 300 & LIVE=$!
echo "$LIVE" > "$R/.mutation-running"
expect "变异门:锁 + 活进程拦构建"       2 "$GUARD" "$(bashcmd 'swift build' "$R")"
expect "变异门:锁 + 活进程拦 git merge" 2 "$GUARD" "$(bashcmd 'git merge feature' "$R")"
expect "变异门:锁 + 活进程拦 make"      2 "$GUARD" "$(bashcmd 'make test' "$R")"
expect "变异门:只读命令放行"            0 "$GUARD" "$(bashcmd 'git log --oneline' "$R")"
expect "变异门:别的树放行"              0 "$GUARD" "$(bashcmd 'swift build' "$O")"
expect "变异门:从别处用 -C 指进来也拦"  2 "$GUARD" "$(bashcmd "git -C $R checkout main" "$O")"
expect "变异门:从别处 cd 进来也拦"      2 "$GUARD" "$(bashcmd "cd $R && xcodebuild test" "$O")"
expect "变异门:非 Bash 工具不管"        0 "$GUARD" "$(json '{"tool_name":"Read","tool_input":{"file_path":"x"}}')"
kill "$LIVE" 2>/dev/null; wait "$LIVE" 2>/dev/null
expect "变异门:锁在但进程已死也拦"      2 "$GUARD" "$(bashcmd 'git reset --hard' "$R")"
rm -f "$R/.mutation-running"
expect "变异门:删锁后放行"              0 "$GUARD" "$(bashcmd 'git reset --hard' "$R")"
rm -rf "$T"

echo "PASS $pass / FAIL $fail"
exit "$fail"
