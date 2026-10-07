---
name: ai-office-rules
description: >-
  一套「领导者定方案 + 多个 AI agent 施工 + 独立与对抗审核」的软件开发工作流。
  当你要用 Claude Code 派子 agent(subagent)并行做一个功能或切片、写派工简报、
  定接口契约、组织代码审核 / 对抗审核、合并多条 worktree、做带回滚点的部署、
  或者写开工前的基调文件(范围、验收、预算、红线)时使用。
  Use for multi-agent software work: planning a slice, writing agent briefs,
  contracts and amendments, independent / cross-vendor adversarial review,
  merge gates, safe deploys, and keeping test processes away from the user's real data.
---

# AI 办公规矩(ai-office-rules):领导者 + 施工队 + 审核官

> English translation: [SKILL.en.md](SKILL.en.md). 中文版为准。

这套技能把「一个人带着一群 AI agent 做产品」拆成十步。每一步都有一条「为什么」,细节在 `references/`。
核心只有一个词:**效率** —— 时间只花在最终能落到用户手里的东西上。

> 称呼约定:**用户** = 这个项目的主人(拍板的人);**领导者** = 你这个主会话;
> **builder / scout / curator** = 你派出去的子 agent(见 `agents/`)。

## 先判断用多重

不是每件事都要走满十步。开工前先按下表定档,拿不准就往重的那一档靠。

| 档 | 判断标准(一句话) | 走哪几步 |
|---|---|---|
| **轻** | 一个 agent、半小时内能做完、不碰用户数据 | 3、5、10 |
| **中** | 几个 agent 合做一个功能,但不碰数据、计费、权限、上线 | 1–6、8、10 |
| **重** | 多条线并行,或碰到数据 / 计费 / 权限 / 上线任何一样 | 全部十步 |

下面每一步标题后的 `[轻·中·重]` 标的是它属于哪几档。术语(证红、哨兵、轻门、回报即停……)第一次出现时链接到词汇表 `references/glossary.md`。

---

## 1. 开工前:写基调文件,拿到一声「行」 `[中·重]`

- 用 `references/baseline-template.md` 在项目 `docs/BASELINE-<线名>.md` 写一份[基调](references/glossary.md):目标(一句话、面向用户)/ 做与不做 / 用户可见的验收 / 里程碑(每个都是能演示的切片,带 [first demo](references/glossary.md) 日期)/ 预算(模型档、并行数、预计时长)/ 目标环境 / 红线 / 自主边界 / OPEN QUESTIONS。
- 用户说「行」之后,它就是**唯一的工作清单**。每件事都要对得上其中一行;对不上的写进文末「候补」,不做。清单做完 = 停下汇报,不自己造活。
- **为什么**:用户可能长时间不在。没有基调,领导者会四处忙、实际什么都没交付。

## 2. 定战略的人和施工的人分开 `[中·重]`

- 领导者只做三件事:**定方案**(基调、[契约](references/glossary.md)、原则)、**执行方案**(派工、合并、验收)、**审核**(审成品、拆真难的 bug)。不亲手写大段代码、不跑批量。
- 模型分工的原则是「这一步需要**判断**,还是只需要**动手**」:判断用顶级模型;施工用强模型;只产数据的批量活用便宜快速的模型、低推理。降的是推理档,不是拿小模型省钱。详见 `references/roles-and-models.md`。
- 听不懂用户的意思就**问**;技术事实不知道就**自己查**。可推断的技术事自己定、汇报理由;用户的意思、偏好、产品方向、商业判断只摆选项给建议,由用户定 —— 辅佐,不覆盖。

## 3. 简报 = 一整套设计好的施工路线 `[轻·中·重]`

- 按 `references/brief-template.md` 写。**第一行固定**:`推理档 <档> · 预计 <分钟> · 退出条件:<一句话>。预计只是预计,不是硬限。`
- [简报](references/glossary.md)必须写清:做什么、改哪些文件(只许改这些)、接口与契约、先后顺序、每道门怎么验、遇到什么情形**[回报即停](references/glossary.md)**、报告格式、证据落在哪个持久目录。
- 简报落到持久目录(不要只放在 agent 上下文或会被重启清空的临时目录)。
- `hooks/check-brief.sh` 在每次派工前机器检查第一行,不合格直接拒。
- **为什么**:子 agent 很强,但路线要由领导者设计;让它自己摸,它会悄悄重设计。

## 4. 并行与文件归属 `[中·重]`

- 并行的瓶颈不是 agent 数,是**共享文件、共享模拟器、共享安装路径**。基调里按文件 / 模块切活:同一文件同一时段只归一个 agent;撞车的串行。
- 每个 builder 一个 git [worktree](references/glossary.md)、一个专用构建目录 / 模拟器。跨 agent 的接口**派工前签名定死**,写进两份简报;集成(统一连线)由领导者在一个明确步骤里做,不让两个 agent 各接一半。
- 同一顶级模型不要同时开太多个(留额度余量);撞满时在跑的 agent 会死在半路。
- **会话重启会杀掉所有在跑的子 agent**:简报落盘、每条做完就 commit;重启后按各 worktree 的 `git log`(已完成)+ `git status`(做到一半)写续做简报。
- **多个 agent 共用一个临时目录会互相覆盖同名脚本**:每个 agent 的临时目录带随机后缀(`mktemp -d`)。
- 详见 `references/operating-model.md` 的「多 agent 同一仓库」。

## 5. 每条先证红、再修、再 commit `[轻·中·重]`

- 每个条目先写一条自检 / 测试,在**未改的代码上跑出红**(即[证红](references/glossary.md),贴原文),commit「自检:X 证红」;再改代码跑绿,commit「X」。
- 每做完一条就 commit —— 未提交的改动是接手成本的大头。
- ⛔ 不许靠改断言让测试变绿;契约真变了,写明旧预期为什么失效。
- 提交信息里的数字必须**先看见再抄**:验证和提交不要串在同一条命令里。
- **生产接线要有一条不经过[夹具](references/glossary.md)的断言**:夹具常常替产品把线接好了 —— 自检全绿,产品没修好。至少一条测试从生产入口走、不做测试注入。
- **测试不读真实系统状态**:锁屏、安全输入、共享设置、别人的模拟器数据都会让测试时红时绿。测试需要的状态在现场注入,不读真状态。
- 施工期只过**[轻门](references/glossary.md)**:编译零 warning + 自己那一节的定向测试 + 一条冒烟。
- 测试 / 自检进程不许碰用户的真数据、屏幕、剪贴板、麦克风、钥匙串:`references/isolation-rules.md`。

## 6. 独立审核 `[中·重]`

- 审核者**只读**、**不读 builder 的[自证报告](references/glossary.md)**,只拿:验收 ID + 产物(commit、构建指纹、环境)+ 契约。
- 审核者**自己做[变异](references/glossary.md)**:把关键断言对应的代码删掉 / 改掉,确认测试会红;[恒真断言](references/glossary.md)是最常见的假绿。
- 结论逐条 PASS / FAIL / UNKNOWN + 证据 + 严重度;只有破坏验收、数据、隐私 / 权限、计费、发布条件的才是**[阻断项](references/glossary.md)**。最后一句:能不能合。
- 单问一句「**对用户是不是真的零影响**」:开关不露出 ≠ 没改用户的数据(迁移、后台任务、写库可能照样发生)。
- **同一处连续两轮审出新问题,就回头改设计,不再补洞**:第三轮修复常常只是补洞。换一个让这类 bug 结构上不可能的形状。
- 范式与模板:`references/adversarial-review.md`,样例:`examples/review-example.md`;这几条的细节见 `references/incident-lessons.md` 第四部分。

## 7. 对抗审核:换一家模型 `[重]`

- 大的决定(换依赖、架构取舍、数据契约、隐私边界)和切片成品,拿给**另一家厂商的顶级模型**挑刺:它没看过你的推理,是最硬的独立视角。设计中途就拉它,不只在收尾。
- 只给它相关文件的目录 + 行号范围,不让它整仓漫游;它的结论先对照代码事实,再转给用户。
- **退路:没有第二家厂商的模型时**,用同一家模型开一个**新会话 / 新 agent** 当对抗审核:不看施工过程、不读自证报告,只拿契约、目标 commit 和「反驳我、给替代、标推断」的提示词。效果打折在两处:①同一家模型的训练盲点是共享的,它和你容易在同一个地方一起看漏;②它倾向认同同一家的写法和推理套路。补法:要求它对每条结论先给反例再给判断,并把「拿不准就判不成立」写进提示词。
- 结论落成契约修订:`CONTRACT → 对抗 → AMEND-N`([契约 / AMEND](references/glossary.md)),冲突处以 AMEND 为准。流程见 `references/contracts-and-amendments.md`,样例见 `examples/contract-example.md` 与 `examples/amend-example.md`。

## 8. 合并门 `[中·重]`

- 同一基线绿了就合。**每合一步先编译、再跑自检**,顺序不能反:最危险的不是冲突,是「自动合并成功」的文件。
- 合并冲突一律「两边都保」再判,不二选一。合并后[哨兵](references/glossary.md)因为字符串搬家变红,是在尽职:重新对准并证红,⛔ 不放宽。
- 合并后在**合并后的产物**上跑:全部已完成切片的验收测试([验收即回归](references/glossary.md))。失败就暂停后续合并。
- 只对高影响逻辑(状态机、账务、权限、数据迁移、上传路径)在合并前单独过审([REQUIRES_REVIEW](references/glossary.md))。

## 9. 部署:先留回滚点、先红后绿、回报即停 `[重]`

1. [回滚点](references/glossary.md):记下线上当前版本与对应提交,备份将被替换的东西,打本地 tag。
2. 部署前手动跑一遍哨兵;迁移先 dry-run、看输出、再提交。
3. 线上[探针](references/glossary.md)**先红**(部署前证明它能抓到缺失),部署,探针**再绿**。
4. 探针自己造的数据自己清;写部署日志(版本、迁移、探针、回滚点各一行)。
5. **回报即停**:dry-run 与预期不符、探针红且短时间定不了是脚本还是服务、线上出现错误告警、需要改已审过的逻辑才能绿 —— 回滚到第 1 步的回滚点,再回报。

## 10. 汇报三行 `[轻·中·重]`

- 只在三种时候汇报:切片 first demo 到期、里程碑完成、卡住需要用户决定;另外任务明显偏离预计时说一句。
- 固定三行:**做了什么 / 卡在哪 / 下一步**,数字进表。转述的材料不静默省略;推断标 [INFERENCE](references/glossary.md);缺口和矛盾主动报。
- 里程碑汇报附成本一行(等待时间、多久让用户第一次看到可用产物、返工时间),数据来自基调里的[派工账](references/glossary.md)。

---

## 贯穿始终的四条

- **先证伪,再动手**:建在系统行为、私有 API、第三方平台上的工作,先做最便宜的证伪(查符号表、官方文档、跑一个探针)。查不出 = [UNKNOWN](references/glossary.md),不等于可以做。
- **让系统自己说话**:排查先想怎么让程序把事实写出来;一个假设一个脚本;「是不是我弄坏的」拿基线 worktree 对照,不读代码猜。
- **机器拦,不靠记得**:每出一次事故,问「能不能变成一道机器门」。`hooks/` 里是两个例子。
- **事故只追加**:违反规矩造成浪费,当天把事故写进对应条目的「为什么」。`references/incident-lessons.md` 是一份起点。

## 文件地图

| 文件 | 何时读 |
|---|---|
| `references/glossary.md` | 碰到不认识的词(证红、哨兵、轻门、夹具……) |
| `references/operating-model.md` | 第一次用这套流程;规矩有疑问时 |
| `references/roles-and-models.md` | 决定派谁、用什么模型和推理档 |
| `references/baseline-template.md` | 开工前写基调 |
| `references/brief-template.md` | 每次派工前 |
| `references/contracts-and-amendments.md` | 跨 agent 接口、数据契约、对抗后的修订 |
| `references/adversarial-review.md` | 派独立审核 / 换厂模型对抗前 |
| `references/review-checklist.md` | 里程碑的六维 review |
| `references/isolation-rules.md` | 任何会跑项目二进制、自检、截图、探针的活 |
| `references/incident-lessons.md` | 写测试、写哨兵、设计门之前 |
| `agents/` | 四个角色定义,拷到 `~/.claude/agents/` |
| `hooks/` | 两道机器门 + 注册方法 |
| `examples/` | 一份简报、一份契约 + AMEND、一份独立审核结论(虚构项目) |
