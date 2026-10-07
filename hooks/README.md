# 机器门:两个 PreToolUse 钩子

规矩只写在文档里,迟早有一次会被忘。这两个钩子把两条规矩变成机器拦截:

| 钩子 | 拦什么 | 为什么 |
|---|---|---|
| `check-brief.sh` | 派子 agent 时,简报第一行缺「推理档 / 预计 / 退出条件」;简报里给小兵设用量上限 | 简报是完整施工路线;没有退出条件的活会无限续,没有预计就没法发现「明显偏离」;用量上限会让小兵为省用量少验一步 |
| `guard-mutation.sh` | 某棵树上变异测试在跑(或被中断)时,对这棵树的构建 / 合并 / 切换 | 变异测试在反复改源码再还原;这时构建、合并、切换分支会读到或合进被改过的源码 |

两个都是:不合格 → `exit 2`,stderr 的说明回给模型,模型改好再试;合格 → `exit 0`。依赖 `bash`、`python3`、`git`。

## 安装

```bash
mkdir -p ~/.claude/hooks
cp hooks/check-brief.sh hooks/guard-mutation.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/check-brief.sh ~/.claude/hooks/guard-mutation.sh
```

在 `~/.claude/settings.json`(全局)或项目的 `.claude/settings.json` 里注册:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Agent|Task",
        "hooks": [{ "type": "command", "command": "~/.claude/hooks/check-brief.sh" }]
      },
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "~/.claude/hooks/guard-mutation.sh" }]
      }
    ]
  }
}
```

已有 `hooks` 段时,把两项合并进现有的 `PreToolUse` 数组,不要覆盖别的钩子。新注册的钩子一般在下一次会话生效。

## 变异门的约定

你的变异测试 runner 需要在开跑时写锁、结束时删锁:

```bash
echo $$ > "$(git rev-parse --show-toplevel)/.mutation-running"
trap 'rm -f "$(git rev-parse --show-toplevel)/.mutation-running"' EXIT
```

- 锁在、runner 活着 → 拦。
- 锁在、runner 已死 → **也拦**:变异可能被中断,工作区也许留着没还原的改动。先 `git status` / `git diff` 检查,确认干净再手动删锁。
- 把 `.mutation-running` 加进项目的 `.gitignore`。
- 要拦的命令可以用环境变量 `GUARD_MUTATION_CMDS`(正则)换掉默认值。

## 可调开关

| 变量 | 作用 |
|---|---|
| `BRIEF_GATE_ALLOW_USAGE_TALK=1` | 关掉「简报不谈用量上限」这一条 |
| `BRIEF_GATE_OFF=1` | 临时关掉整个简报门 |
| `GUARD_MUTATION_CMDS` | 变异门要拦的命令正则 |

## 不想配钩子:手动核对清单

钩子只是把下面两条变成机器拦截。不配钩子也行,但每次都要自己核:

**每次派子 agent 之前**
- [ ] 简报第一条非空行写了:推理档 / 预计 / 退出条件,以及「预计只是预计,不是硬限」。
- [ ] 简报里没有给小兵设用量上限。

**每次构建 / 合并 / 切分支 / reset / stash 之前**
- [ ] 这棵树上有没有变异测试在跑?(看 `.mutation-running` 锁,或 `ps` 里有没有变异 runner)
- [ ] 有锁但 runner 已不在?→ 先 `git status` / `git diff` 确认没有残留的变异改动,再删锁。
- [ ] 要构建,就换一个 worktree,别等不及在同一棵树上动。

手动清单的弱点是「忙的时候会忘」—— 规矩里每一次事故几乎都是这么来的。项目一旦有两个以上 agent 并行,建议还是配上钩子。

## 自测

```bash
bash tests/test-hooks.sh     # 每条断言都有反例;退出码 = 失败条数
```

改钩子的判据之前,先在目标 shell 上用同形状的最小输入**证一次红**再合,不拿「语法 OK」当验证。
