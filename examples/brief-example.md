推理档 high · 预计 120 分钟 · 退出条件:同步客户端按 CONTRACT + AMEND-1 实现 M1–M7 的客户端部分,每条先证红再绿,四道门全过。效率为主,预计只是预计,不是硬限。

> **虚构示例**:「示例笔记 App」同步功能的客户端施工简报(C 组)。与之并行的还有 S 组(服务端)。

先读:`~/work/notes-app/docs/BASELINE-sync.md`(基调与文件归属)、`~/work/notes-app/docs/audits/2030-01-15/COMMON.md`(规矩、跑法、门)、契约 `…/CONTRACT-notes-sync.md` + `…/AMEND-1-notes-sync.md`(冲突处以 AMEND-1 为准)、现状事实 `…/scout-sync.md`。
⛔ 只改你这组点名的文件,撞上别组文件停下回报;⛔ 每做完一条就 commit(先「自检:X 证红」再「X」);不开麦、不碰剪贴板、不合成按键、不安装、不 push、不 merge、不用 git stash。

【worktree】`~/work/notes-app-sync-c`(分支 `sync-c`,基线 `3f2a91c0`)。所有命令用绝对路径。

【文件】
- 只许改:`Sources/Sync/SyncClient.swift`(新)、`Sources/Sync/SyncQueue.swift`(新)、`Sources/Sync/SyncState.swift`(新)、`Sources/Settings/SyncSettingsView.swift`、`Tests/SyncClientTests.swift`(新)。
- 只读:`Sources/Store/NoteStore.swift`(接口见下,S 组不改它,你也不改)。
- ⛔ 不碰:`Server/**`(S 组在改)、`Sources/Editor/**`。

【接口(签名定死,S 组简报里是同一份)】
- 请求:`POST /v1/notes/sync {device_id, epoch, since, op_id, push: [{note_id, title, body, tags, pinned, deleted, base_rev}]}`
- 响应:`200 {pull: [...同上 + rev], cursor, more}`;`409 {reason: "epoch_changed", epoch}`;`413 {reason: "quota", limit}`;`503 {reason: "disabled"}`。
- 本机读写只经 `NoteStore.applyRemote(_:)`(不标脏、不改修改时间)与 `NoteStore.dirtyNotes(since:)`。

【事实】scout 实测:`NoteStore` 现有 1 个写口(`save(_:)`)会无条件更新 `modified_at` 并标脏 —— 所以 M5 必须走 `applyRemote`,不能复用 `save`。

【做】(按顺序;每条先证红再修,各自 commit)
1. M4 账号边界:`SyncState` 按 user id 分键存游标 / 队列 / epoch / device_id;登出或换账号 → 关同步、清队列。自检:A 账号有待传队列时切到 B,B 的第一次 push 为空。
2. M3 epoch:收到 409 → 关同步、清游标与队列、设置页显示指定文案。自检:模拟 409 后零请求。
3. M1 / M5:push 带 `base_rev`;pull 结果一律经 `applyRemote`。自检:拉回 10 条后 `dirtyNotes` 为空。
4. M7:`op_id` 在重试间保持不变;pull 按 `more` 翻页直到 false;413 停传并在设置页说明。自检:同一批重试三次 `op_id` 相同;翻页 3 页不漏行。
5. 迟到回包:每次请求记 (user id, epoch, 请求序号);回包时任一不符丢弃。自检:发出后切账号,回包到达不落库。
6. 关键路径:同步在后台队列跑。自检:服务端永不回包时,连续 200 次 `NoteStore.save` 的 p95 与基线差 < 10%。

【门】(报告里逐条贴证据)
1. 干净重建零 warning(贴 `grep -c 'warning:'`)。
2. 全部测试零失败,且通过数不少于基线(贴计数与最后 5 行;基线就红的,在基线上复跑证明)。
3. 每条:证红原文 → commit「自检:X 证红」→ 修 → commit「X」。
4. 定向变异:对 1–6 各删一行生产代码(真删,不注释),报 N/N 证红。

【回报即停】`NoteStore` 缺上面写的接口;AMEND-1 与接口互相矛盾;要改没点名的文件;撞上并发 / 取消 / 乱序而 AMEND-1 没覆盖;明显偏离预计。

【报告】写到 `~/work/notes-app/docs/audits/2030-01-15/sync-c-report.md`;最终回复三行(做了什么 / 卡在哪 / 下一步)+ commit 表 + 四道门证据 + UNKNOWN 清单 + 实际用时。
