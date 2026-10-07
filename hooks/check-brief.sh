#!/bin/bash
# 派工简报门(PreToolUse,matcher: Agent|Task)
# 规矩:简报第一行(第一条非空行)要写「推理档 · 预计 · 退出条件」;全文不谈用量上限。
# 不合格 → exit 2,stderr 的说明会回给模型,让它改好再派。
#
# 可调:
#   BRIEF_GATE_ALLOW_USAGE_TALK=1   关掉「不谈用量上限」这一条
#   BRIEF_GATE_OFF=1                整个门关掉(临时)

[ "${BRIEF_GATE_OFF:-0}" = "1" ] && exit 0

input=$(cat)
field() { printf '%s' "$input" | python3 -c "import sys,json
d=json.load(sys.stdin)
v=d
for k in sys.argv[1:]:
    v=v.get(k,{}) if isinstance(v,dict) else {}
print(v if isinstance(v,str) else '')" "$@" 2>/dev/null; }

tool=$(field tool_name)
case "$tool" in Agent|Task) ;; *) exit 0 ;; esac

prompt=$(field tool_input prompt)
first=$(printf '%s\n' "$prompt" | awk 'NF{print; exit}')

missing=""
printf '%s' "$first" | grep -qiE '推理档|effort'          || missing="$missing 推理档"
printf '%s' "$first" | grep -qiE '预计|estimate|ETA'      || missing="$missing 预计"
printf '%s' "$first" | grep -qiE '退出条件|exit criteria|done when' || missing="$missing 退出条件"
if [ -n "$missing" ]; then
  echo "⛔ 简报第一行缺:$missing。第一行格式:推理档 <档> · 预计 <分钟> · 退出条件:<一句话>。预计只是预计,不是硬限。" >&2
  exit 2
fi

if [ "${BRIEF_GATE_ALLOW_USAGE_TALK:-0}" != "1" ]; then
  # 只拦「用量 / 上限」意义上的 token;登录凭证意义上的 token(access / refresh token、令牌)是正常工程词
  if printf '%s' "$prompt" | grep -qiE 'token[ ]*(上限|用量|预算|limit|budget|cap)|[0-9]+[ ]*[万kK]?[ ]*tokens?\b|tokens? (spent|used|usage)'; then
    echo "⛔ 简报里出现了用量上限字眼:不给小兵设用量额度,不让它为省用量少验一步。删掉再派(或设 BRIEF_GATE_ALLOW_USAGE_TALK=1)。" >&2
    exit 2
  fi
fi
exit 0
