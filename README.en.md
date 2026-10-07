English · [中文](README.md) (the Chinese version is authoritative)

# AI Office Rules · ai-office-rules

> An AI development workflow of lead + build crew + reviewers, packaged as a Claude Code skill.

## What this is

A multi-agent workflow refined again and again in real product development, packaged as a Claude Code skill:

- Before starting, write a **baseline file** (scope, acceptance, budget, red lines) and get a clear "go" before touching anything;
- The **lead** decides the plan, writes contracts and reviews; **builder / scout / curator** build, scout and produce bulk data according to a brief;
- Every change is **proven red first, then fixed**, and each one gets its own commit;
- **Independent review** (read-only, never reads the builder's self-report, runs its own mutations) + **adversarial review by a model from a different vendor**;
- Merge gates, deploys with a rollback point, and three-line status reports;
- An isolation rulebook distilled from real incidents: "test processes must not touch the user's real data".

## Who it is for

- People who use Claude Code to dispatch several subagents at once on the same product;
- People who want the AI to keep moving down the checklist while they are away, without overstepping;
- People who have already been burned by "all tests green but the feature is broken", "a subagent quietly changed the design", or "a test process corrupted real data".

Not a good fit: one-off small scripts or single-file edits — the overhead of this process is not worth it there.

## Installation

```bash
git clone https://github.com/Azureliu-day1/ai-office-rules.git

# 1) The skill itself (pick one)
cp -r ai-office-rules ~/.claude/skills/ai-office-rules              # global
cp -r ai-office-rules <your-project>/.claude/skills/ai-office-rules # one project only

# 2) Roles (optional, recommended)
cp ai-office-rules/agents/*.md ~/.claude/agents/

# 3) Machine gates (optional, recommended): see hooks/README.md
cp ai-office-rules/hooks/*.sh ~/.claude/hooks/ && chmod +x ~/.claude/hooks/*.sh
```

Once installed, say "start work using ai-office-rules" in Claude Code, or describe a multi-agent development task, and the skill will be triggered automatically.

To use the skill body in English: rename `SKILL.en.md` to `SKILL.md`, replacing the Chinese version (the detail files under `references/` and elsewhere are currently Chinese only).

## Layout

```
SKILL.md                         Main body: the ten steps + file map (Chinese, authoritative)
SKILL.en.md                      English translation of the main body
references/
  operating-model.md             The full rules, each with its "why"
  roles-and-models.md            Role split and model / reasoning-level principles
  baseline-template.md           Baseline file template
  brief-template.md              Agent brief template
  contracts-and-amendments.md    Contract -> adversarial review -> AMEND revision flow
  adversarial-review.md          Independent review brief pattern + cross-vendor adversarial review
  review-checklist.md            Six-dimension milestone checklist
  isolation-rules.md             Isolation rules for test / self-check processes
  incident-lessons.md            Incident -> lesson -> machine gate
  glossary.md                    Glossary
agents/                          lead / builder / scout / curator role definitions
hooks/                           Brief gate, mutation-testing gate + registration notes
examples/                        A fictional "notes app sync": brief, contract, AMEND, review verdict
tests/                           Self-tests for the two hooks
```

## About usage

These rules state principles only and give no concrete usage or cost figures: what you lower is the reasoning level, not the model size to save money; do not run too many instances of the same top-tier model at once, and leave headroom in your quota; when nearing a limit, stop dispatching new agents, record a checkpoint, and resume after the reset. Details in sections 2 and 7 of `references/operating-model.md`.

## Provenance

Every rule here comes from a real waste of time or a real incident in an actual project. Incidents keep their dates, and each one keeps only "what happened, and how the rule changed"; personal names, product names, email addresses, file paths, keys, third-party account names, private information and any fragments of user data have been removed.

## Author and license

Others Studio (Azure Liu).

Released under the [MIT License](LICENSE).
