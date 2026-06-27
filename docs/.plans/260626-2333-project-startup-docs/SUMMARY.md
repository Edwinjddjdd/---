# Implementation Plan: 项目启动文档骨架

> Created: 2026-06-26 23:33:49

## Purpose / Big Picture

- 将当前阶段一研究资料整理成项目级入口，使后续建模、仿真和验证可以从稳定文档开始。
- 本计划只新增文档骨架和执行记录，不实现仿真代码，不冻结未经课程 PDF 核验的轴系定义。
- Brainstorm artifact: [Brainstorm artifacts](../../.brainstorms/260626-2333-project-startup/SUMMARY.md)

## Objective

- 新增 `README.md`、`docs/SUMMARY.md`、`docs/stage-2-model-spec-draft.md` 和 `docs/verification-roadmap.md`。
- 文档应把已有研究资料组织成阶段二建模入口、模块边界、待冻结项和验证场景。
- 所有数学表达式必须使用 LaTeX，例如状态方程写作：

$$
\dot{x}=f(x,u,t)
$$

## Context and Orientation

- Relevant docs loaded:
  - `AGENTS.md`
  - `docs/research/modeling-basis.md`
  - `docs/research/literature-map.md`
  - `docs/research/data-sources.md`
  - `docs/research/deep-reading/deep-reading-index.md`
  - `docs/research/paper-notes/wayne-johnson-vrs-model.md`
  - `docs/research/paper-notes/dynamic-inflow-models.md`
- Relevant files/modules:
  - Existing research docs under `docs/research/`
  - New project docs under `docs/`
- Existing patterns to follow:
  - Chinese Markdown documentation.
  - Tables for source maps, module maps and verification scenarios.
  - LaTeX for variables, equations, matrices and subscripts.
- Constraints, dependencies, and compatibility notes:
  - No `docs/SUMMARY.md` currently exists.
  - Current repo content is documentation-only.
  - Existing files are untracked; do not rewrite existing research notes.

## Scope

### In scope

- Add a root project README.
- Add a project summary under `docs/SUMMARY.md`.
- Add a stage-two model specification draft.
- Add a verification roadmap.
- Add this plan's execution report after implementation.
- Generate a source-adjacent plan visualization.

### Out of scope

- MATLAB, Simulink or Python model implementation.
- Final coordinate-system freeze.
- Target aircraft parameter selection.
- External web research.
- Rewriting or normalizing existing research notes.

## Architecture & Approach

- Use documentation layering:
  - Root `README.md` for quick entry and current status.
  - `docs/SUMMARY.md` for agent/project orientation.
  - `docs/stage-2-model-spec-draft.md` for model modules, states and interfaces.
  - `docs/verification-roadmap.md` for validation scenarios and data gaps.
- Treat unverified items as explicit placeholders, not as final assumptions.
- Keep VRS implementation strategy as interface-level guidance:

```text
飞行状态 + 主旋翼状态
  -> VRS_Detection
  -> VRS_Correction
  -> 主旋翼力和力矩
  -> 六自由度动力学
```

## Progress

- [x] Plan approved for execution by current user request.
- [x] Phase 1 complete.
- [x] Phase 2 complete.
- [x] Final verification complete.
- 2026-06-26 23:45:00 - Started Phase 1: creating `README.md` and `docs/SUMMARY.md`.
- 2026-06-26 23:50:00 - Completed Phase 1. Created `README.md` and `docs/SUMMARY.md`. Verification: `rg --files` listed both files; targeted `rg` found stage-two, VRS, coordinate-system, LaTeX and research-link references.
- 2026-06-26 23:51:00 - Started Phase 2: creating `docs/stage-2-model-spec-draft.md` and `docs/verification-roadmap.md`.
- 2026-06-26 23:56:00 - Completed Phase 2. Created `docs/stage-2-model-spec-draft.md` and `docs/verification-roadmap.md`. Verification: targeted `rg` found state/interface notation, VRS detection/correction, validation sections, pending items and LaTeX terms; `rg --files` with code/model globs returned no `.m`, `.slx`, `.py` or `.mlx` files.
- 2026-06-26 23:57:00 - Started final verification across added docs, plan visualization and repository status.
- 2026-06-26 23:59:00 - Final verification complete. Confirmed documentation files, LaTeX/interface markers, visualization CSS/Mermaid references, no leftover `VISUALIZE:` markers, and no code/model files. Created `EXECUTION-REPORT.md`.

## Phases

- [x] **Phase 1 [S]: 项目入口文档** - Create root and docs-level entry points.
- [x] **Phase 2 [S]: 阶段二草案与验证路线** - Create model specification draft and verification roadmap.

## Key Changes

- Add `README.md`
- Add `docs/SUMMARY.md`
- Add `docs/stage-2-model-spec-draft.md`
- Add `docs/verification-roadmap.md`
- Add plan artifacts under `docs/.plans/260626-2333-project-startup-docs/`

## Validation and Acceptance

- Verification commands:
  - `rg --files`
  - `rg -n "TODO|待|VRS|LaTeX|\\$\\$|\\\\dot|\\\\mathbf" README.md docs/SUMMARY.md docs/stage-2-model-spec-draft.md docs/verification-roadmap.md`
  - `git diff -- README.md docs/SUMMARY.md docs/stage-2-model-spec-draft.md docs/verification-roadmap.md`
- Observable acceptance criteria:
  - New project entry docs exist at the expected paths.
  - New docs link to existing research files.
  - Mathematical notation in new docs uses LaTeX syntax.
  - Unverified assumptions are labeled as pending or draft.
  - Existing research notes remain untouched.

## Idempotence and Recovery

- Safe re-run notes:
  - Re-running can overwrite or refine only files added by this plan.
  - Existing research docs must remain unchanged unless a new plan explicitly targets them.
- Rollback/recovery notes:
  - Remove the added `README.md`, new `docs/*.md` entry files, and this plan folder if the scope is rejected.
- Irreversible operations or destructive steps:
  - None.

## Dependencies

- New packages/tools:
  - None.

## Risks & Mitigations

- Risk: Project docs may appear to finalize unverified coordinate conventions -> mitigation: mark coordinate definitions as pending until source PDF review.
- Risk: Stage-two draft may over-specify the future implementation environment -> mitigation: keep MATLAB/Simulink/Python implementation choice open.
- Risk: Existing research notes are untracked -> mitigation: only add files, do not edit existing research notes.

## Surprises & Discoveries

- 2026-06-26 23:55:00 - A planned `rg` check using raw LaTeX snippets failed because `\m` was interpreted as a regex escape. Re-ran verification with fixed strings and simpler patterns; documents passed.

## Decision Log

- 2026-06-26 23:33:49 - Decision: Treat the user's requested Brainstorm -> Write Plan -> Execute Plan sequence as approval to execute this minimal documentation plan in the same session. Rationale: The requested scope is documentation-only, reversible, and low risk.

## Outcomes & Retrospective

- Final result: Completed with follow-ups.
- Added project entry documentation, stage-two model specification draft, verification roadmap, Brainstorm artifact, Write Plan artifact, plan visualization and execution report.
- Verification summary: file inventory, targeted content checks, fixed-string LaTeX checks, visualization checks and code/model glob checks passed.
- Deviations: None from the written plan.
- Follow-ups: freeze coordinate systems from course PDFs, choose implementation environment, and provide/choose target-aircraft parameters before numerical simulation.

## Open Questions

- 是否已有课程 PDF 第 1、4 章原件可用于冻结中俄轴系？
- 最终实现环境优先选择 Simulink、MATLAB 脚本、Python，还是先写环境无关规格？
- 是否已有指定目标机型参数？
