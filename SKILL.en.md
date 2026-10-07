---
name: ai-office-rules
description: >-
  A software development workflow of "a lead decides the plan + several AI agents build +
  independent and adversarial review". Use it when you dispatch Claude Code subagents to
  build a feature or slice in parallel, write agent briefs, define interface contracts,
  organize code review / adversarial review, merge several worktrees, deploy with a
  rollback point, or write a pre-work baseline file (scope, acceptance, budget, red lines).
  Use for multi-agent software work: planning a slice, writing agent briefs,
  contracts and amendments, independent / cross-vendor adversarial review,
  merge gates, safe deploys, and keeping test processes away from the user's real data.
---

# AI Office Rules (ai-office-rules): lead + build crew + reviewers

> This is an English translation of [SKILL.md](SKILL.md); the Chinese version is authoritative. To use it as the skill body, rename it to `SKILL.md`. The files under `references/`, `agents/`, `hooks/` and `examples/` are currently Chinese only.

This skill breaks "one person leading a group of AI agents to build a product" into ten steps. Every step has a "why"; the details are in `references/`.
There is only one core word: **efficiency** — time is spent only on things that end up in the user's hands.

> Naming: **user** = the owner of this project (the person who makes the call); **lead** = you, the main session;
> **builder / scout / curator** = the subagents you dispatch (see `agents/`).

## First decide how heavy this is

Not everything needs all ten steps. Before starting, pick a tier from the table below; when unsure, lean toward the heavier tier.

| Tier | Criterion (one sentence) | Steps to follow |
|---|---|---|
| **Light** | One agent, done within half an hour, does not touch user data | 3, 5, 10 |
| **Medium** | Several agents on one feature, but no data, billing, permissions or release | 1–6, 8, 10 |
| **Heavy** | Several lines in parallel, or touches any of data / billing / permissions / release | All ten steps |

The `[Light·Medium·Heavy]` tag after each step heading below says which tiers it belongs to. Terms (prove red, sentinel, light gate, report-and-stop…) link to the glossary `references/glossary.md` the first time they appear.

---

## 1. Before starting: write the baseline file and get a "go" `[Medium·Heavy]`

- Use `references/baseline-template.md` to write a [baseline](references/glossary.md) at `docs/BASELINE-<line-name>.md` in the project: goal (one sentence, user-facing) / in and out of scope / user-visible acceptance / milestones (each one a demoable slice, with a [first demo](references/glossary.md) date) / budget (model tier, parallelism, estimated duration) / target environment / red lines / autonomy boundary / OPEN QUESTIONS.
- Once the user says "go", it is the **only work list**. Everything you do must map to one of its lines; anything that does not goes into the "backlog" at the end of the file and is not done. List finished = stop and report; do not invent work.
- **Why**: the user may be away for a long time. Without a baseline, the lead keeps busy everywhere and actually delivers nothing.

## 2. Separate the people who set strategy from the people who build `[Medium·Heavy]`

- The lead does only three things: **decide the plan** (baseline, [contracts](references/glossary.md), principles), **execute the plan** (dispatch, merge, accept), and **review** (review finished work, take apart genuinely hard bugs). It does not write large amounts of code itself or run bulk jobs.
- The principle for splitting work across models is "does this step need **judgment**, or only **hands**": judgment gets a top-tier model; building gets a strong model; bulk jobs that only produce data get a cheap, fast model at low reasoning. What you lower is the reasoning level, not the model size to save money. See `references/roles-and-models.md`.
- If you do not understand what the user means, **ask**; if you do not know a technical fact, **look it up yourself**. Decide inferable technical matters yourself and report your reasoning; for the user's intent, preferences, product direction and business judgment, only lay out options and give a recommendation, and let the user decide — assist, do not override.

## 3. A brief = a fully designed construction route `[Light·Medium·Heavy]`

- Write it from `references/brief-template.md`. **The first line is fixed**: `Reasoning <level> · Estimate <minutes> · Exit condition: <one sentence>. The estimate is only an estimate, not a hard limit.`
- The [brief](references/glossary.md) must spell out: what to do, which files to change (only these), interfaces and contracts, ordering, how each gate is verified, which situations mean **[report-and-stop](references/glossary.md)**, the report format, and which persistent directory the evidence goes into.
- Put briefs in a persistent directory (not only in the agent's context or in a temp directory that a restart wipes).
- `hooks/check-brief.sh` machine-checks the first line before every dispatch and rejects a brief that fails.
- **Why**: subagents are strong, but the route must be designed by the lead; left to find its own way, a subagent will quietly redesign.

## 4. Parallelism and file ownership `[Medium·Heavy]`

- The bottleneck of parallelism is not the number of agents; it is **shared files, shared simulators, shared install paths**. Split work by file / module in the baseline: one file belongs to one agent at a time; colliding work goes serial.
- Each builder gets one git [worktree](references/glossary.md) and one dedicated build directory / simulator. Interfaces between agents are **signed and frozen before dispatch** and written into both briefs; integration (the final wiring) is done by the lead in one explicit step, never half by each of two agents.
- Do not run too many instances of the same top-tier model at once (leave quota headroom); when the quota is hit, the running agents die halfway.
- **A session restart kills every running subagent**: keep briefs on disk and commit after each item; after a restart, write continuation briefs from each worktree's `git log` (done) + `git status` (half done).
- **Several agents sharing one temp directory overwrite each other's same-named scripts**: give each agent a temp directory with a random suffix (`mktemp -d`).
- See "multiple agents, one repository" in `references/operating-model.md`.

## 5. Every item: prove red, then fix, then commit `[Light·Medium·Heavy]`

- For each item, first write a self-check / test and run it **red on the unchanged code** (that is, [prove red](references/glossary.md); paste the raw output), commit "self-check: X proven red"; then change the code, run it green, commit "X".
- Commit as soon as each item is done — uncommitted changes are the bulk of handover cost.
- ⛔ Never make a test green by changing its assertion; if the contract really changed, write down why the old expectation no longer holds.
- Numbers in commit messages must be **seen first, then copied**: do not chain verification and commit into one command.
- **Production wiring needs one assertion that does not go through a [fixture](references/glossary.md)**: fixtures often wire things up on the product's behalf — self-checks all green, product not fixed. At least one test enters through the production entry point with no test injection.
- **Tests do not read real system state**: screen lock, secure input, shared settings, and another agent's simulator data all make tests flip between red and green. Inject the state a test needs on the spot; do not read the real state.
- During construction, only pass the **[light gate](references/glossary.md)**: zero compiler warnings + your own section's targeted tests + one smoke test.
- Test / self-check processes must not touch the user's real data, screen, clipboard, microphone or keychain: `references/isolation-rules.md`.

## 6. Independent review `[Medium·Heavy]`

- The reviewer is **read-only** and **does not read the builder's [self-report](references/glossary.md)**; it gets only: acceptance IDs + artifacts (commit, build fingerprint, environment) + the contract.
- The reviewer **runs its own [mutations](references/glossary.md)**: delete / alter the code behind key assertions and confirm the tests go red; an [always-true assertion](references/glossary.md) is the most common false green.
- Findings go item by item as PASS / FAIL / UNKNOWN + evidence + severity; only what breaks acceptance, data, privacy / permissions, billing or release conditions is a **[blocker](references/glossary.md)**. Last sentence: can it merge or not.
- Ask one question on its own: "**is the impact on the user really zero**": a flag not being exposed ≠ the user's data not being changed (migrations, background tasks and database writes may happen anyway).
- **If the same spot yields new problems in two review rounds in a row, go back and change the design instead of patching again**: a third-round fix is usually just another patch. Switch to a shape in which this class of bug is structurally impossible.
- Pattern and template: `references/adversarial-review.md`; sample: `examples/review-example.md`; details of these points in part four of `references/incident-lessons.md`.

## 7. Adversarial review: switch to another vendor's model `[Heavy]`

- Take big decisions (changing a dependency, architectural trade-offs, data contracts, privacy boundaries) and finished slices to **a top-tier model from a different vendor** to pick holes: it has not seen your reasoning, which makes it the hardest independent viewpoint. Bring it in mid-design, not only at the end.
- Give it only the directories + line ranges of the relevant files; do not let it roam the whole repository. Check its conclusions against the facts in the code first, then pass them on to the user.
- **Fallback: when no second vendor's model is available**, open a **new session / new agent** of the same model as the adversarial reviewer: it does not see the construction process or read self-reports, and gets only the contract, the target commit, and a prompt saying "refute me, give alternatives, mark inferences". Its value is discounted in two places: ① the same model's training blind spots are shared, so it and you tend to miss the same thing together; ② it tends to agree with its own vendor's style and reasoning patterns. To compensate: require it to give a counterexample before each verdict, and write "when unsure, judge it as not holding" into the prompt.
- Conclusions become contract revisions: `CONTRACT → adversarial → AMEND-N` ([contract / AMEND](references/glossary.md)); where they conflict, AMEND wins. Flow in `references/contracts-and-amendments.md`; samples in `examples/contract-example.md` and `examples/amend-example.md`.

## 8. Merge gate `[Medium·Heavy]`

- Merge as soon as the same baseline is green. **At every merge step, compile first, then run the self-checks** — never in the reverse order: the most dangerous files are not the conflicts but the ones that "merged automatically without conflict".
- Resolve every merge conflict by "keeping both sides" first and judging afterwards, never by picking one. A [sentinel](references/glossary.md) going red after a merge because a string moved house is doing its job: re-aim it and prove red again; ⛔ do not loosen it.
- After merging, run on the **merged artifact**: the acceptance tests of every completed slice ([acceptance as regression](references/glossary.md)). On failure, pause further merges.
- Only high-impact logic (state machines, accounting, permissions, data migrations, upload paths) gets a separate review before merging ([REQUIRES_REVIEW](references/glossary.md)).

## 9. Deploy: rollback point first, red before green, report-and-stop `[Heavy]`

1. [Rollback point](references/glossary.md): record the current live version and its commit, back up what will be replaced, and tag locally.
2. Run the sentinels by hand once before deploying; dry-run migrations first, read the output, then commit.
3. The live [probe](references/glossary.md) goes **red first** (proving before the deploy that it can catch the missing piece), deploy, then the probe goes **green**.
4. Probes clean up the data they create; write a deploy log (version, migration, probe, rollback point, one line each).
5. **Report-and-stop**: the dry-run does not match expectations, a probe is red and you cannot quickly tell whether the script or the service is at fault, error alerts appear in production, or getting to green would require changing already-reviewed logic — roll back to the rollback point from step 1, then report.

## 10. Three-line reports `[Light·Medium·Heavy]`

- Report only at three moments: a slice's first demo is due, a milestone is done, or you are stuck and need the user's decision; in addition, say a word when a task clearly drifts from its estimate.
- Always three lines: **what was done / where it is stuck / what is next**, with numbers in a table. Do not silently omit anything from material you relay; mark inferences as [INFERENCE](references/glossary.md); report gaps and contradictions proactively.
- Milestone reports include one cost line (waiting time, how long until the user first saw a usable artifact, rework time), with data from the [dispatch ledger](references/glossary.md) in the baseline.

---

## Four rules that run throughout

- **Falsify first, then act**: for work built on system behavior, private APIs or third-party platforms, do the cheapest falsification first (check the symbol table, the official docs, run a probe). Could not find out = [UNKNOWN](references/glossary.md), which does not mean it is fine to proceed.
- **Let the system speak for itself**: when debugging, first think about how to make the program write the facts out; one hypothesis, one script; for "did I break this", compare against a baseline worktree instead of guessing from the code.
- **Machines block, not memory**: after every incident, ask "can this become a machine gate". `hooks/` holds two examples.
- **Incidents are append-only**: when breaking a rule causes waste, write the incident into the "why" of the corresponding rule the same day. `references/incident-lessons.md` is a starting point.

## File map

| File | When to read |
|---|---|
| `references/glossary.md` | When you meet an unfamiliar term (prove red, sentinel, light gate, fixture…) |
| `references/operating-model.md` | First time using this process; when in doubt about a rule |
| `references/roles-and-models.md` | Deciding whom to dispatch and which model and reasoning level to use |
| `references/baseline-template.md` | Writing the baseline before starting |
| `references/brief-template.md` | Before every dispatch |
| `references/contracts-and-amendments.md` | Cross-agent interfaces, data contracts, revisions after adversarial review |
| `references/adversarial-review.md` | Before dispatching an independent review / cross-vendor adversarial review |
| `references/review-checklist.md` | The six-dimension milestone review |
| `references/isolation-rules.md` | Any job that runs project binaries, self-checks, screenshots or probes |
| `references/incident-lessons.md` | Before writing tests, writing sentinels or designing gates |
| `agents/` | Four role definitions; copy them to `~/.claude/agents/` |
| `hooks/` | Two machine gates + how to register them |
| `examples/` | One brief, one contract + AMEND, one independent review verdict (fictional project) |
