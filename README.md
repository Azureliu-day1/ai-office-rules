[English](README.en.md) · 中文(为准)

# AI 办公规矩 · ai-office-rules

> 领导者 + 施工队 + 审核官的 AI 开发工作流,打包成 Claude Code 技能。

## 这是什么

一套在真实产品开发里反复打磨出来的多 agent 工作流,打包成 Claude Code 技能:

- 开工前写**基调文件**(范围、验收、预算、红线),拿到一声「行」再动手;
- **领导者**定方案、写契约、审核;**builder / scout / curator** 按简报施工、侦察、批量产数据;
- 每条改动**先证红再修**、每条单独 commit;
- **独立审核**(只读、不读自证、自己做变异)+ **换一家厂商的模型做对抗审核**;
- 合并门、带回滚点的部署、三行汇报;
- 一份从真实事故里提炼的「测试进程别碰用户真数据」隔离规则。

## 适合谁

- 用 Claude Code 同时派多个子 agent 做同一个产品的人;
- 希望 AI 在你不在场时也能沿清单推进、并且不越界的人;
- 已经被「测试全绿但功能是坏的」「子 agent 悄悄改了设计」「测试进程写坏了真数据」坑过的人。

不适合:一次性的小脚本、单文件修改 —— 这套流程的开销在那种场景下不值得。

## 怎么装

```bash
git clone https://github.com/Azureliu-day1/ai-office-rules.git

# 1) 技能本体(二选一)
cp -r ai-office-rules ~/.claude/skills/ai-office-rules            # 全局
cp -r ai-office-rules <你的项目>/.claude/skills/ai-office-rules    # 只在某个项目里

# 2) 角色(可选,推荐)
cp ai-office-rules/agents/*.md ~/.claude/agents/

# 3) 机器门(可选,推荐):见 hooks/README.md
cp ai-office-rules/hooks/*.sh ~/.claude/hooks/ && chmod +x ~/.claude/hooks/*.sh
```

装好后,在 Claude Code 里说「按 ai-office-rules 开工」或描述一个多 agent 的开发任务,技能会自动被触发。

想让技能主干用英文:把 `SKILL.en.md` 改名为 `SKILL.md` 覆盖中文版即可(`references/` 等细节文件目前只有中文)。

## 目录

```
SKILL.md                         主干:十步流程 + 文件地图(中文,为准)
SKILL.en.md                      主干的英文翻译
references/
  operating-model.md             规矩全文,每条带「为什么」
  roles-and-models.md            角色分工与模型 / 推理档原则
  baseline-template.md           基调文件模板
  brief-template.md              派工简报模板
  contracts-and-amendments.md    契约 → 对抗 → AMEND 修订流程
  adversarial-review.md          独立审核简报范式 + 换厂模型对抗
  review-checklist.md            里程碑六维检查单
  isolation-rules.md             测试 / 自检进程的隔离规则
  incident-lessons.md            事故 → 教训 → 机器门
  glossary.md                    词汇表
agents/                          lead / builder / scout / curator 角色定义
hooks/                           派工简报门、变异测试门 + 注册说明
examples/                        虚构的「笔记 App 同步」:简报、契约、AMEND、审核结论
tests/                           两个钩子的自测脚本
```

## 关于用量

这套规矩只谈原则,不给任何具体的用量或费用数字:降的是推理档,不是拿小模型省钱;同一个顶级模型不要同时开太多个,给额度留余量;接近限额时停派新 agent、落断点、等重置后续做。细节见 `references/operating-model.md` 第二、七节。

## 来源说明

这里的每条规矩都来自真实项目里的一次浪费或事故。事故保留了日期,每条只留「发生了什么、规矩怎么改」;人名、产品名、邮箱、文件路径、密钥、第三方账号、私人信息与任何用户数据片段都已去掉。

## 作者与许可证

Others Studio(Azure Liu)。

以 [MIT 许可证](LICENSE) 发布。
