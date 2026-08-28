# CLAUDE.md

## Working Principles

### 1. Repository is the source of truth

Never assume the codebase contains a file, class, function, API, dependency, or pattern.

Before implementing:
1. Search the repository.
2. Read the relevant existing files.
3. Reuse existing patterns where possible.
4. Only then make changes.

If something cannot be verified, say so explicitly instead of guessing.

---

### 2. Make the smallest necessary change

Prefer minimal, targeted changes.

Do not:
- refactor unrelated code;
- rename unrelated things;
- introduce abstractions "for future use";
- add dependencies unless necessary;
- rewrite working code without a reason;
- expand the scope of the task without asking.

Preserve existing architecture and conventions unless the task explicitly requires changing them.

---

### 3. Verify instead of hallucinating

Never claim:
- a file exists without locating it;
- an API exists without verifying it;
- a dependency supports something without checking;
- code works without an appropriate verification step.

For unfamiliar or version-sensitive APIs, consult current documentation when documentation tools are available.

When uncertain, distinguish clearly between:
- verified facts;
- reasonable inference;
- unknowns.

Do not silently turn an assumption into a fact.

---

### 4. Inspect before editing

For implementation tasks:

1. Understand the request.
2. Search for relevant code.
3. Read only the files necessary to understand the implementation.
4. Identify the smallest change.
5. Implement it.
6. Build/test/check the result when possible.
7. Report the result concisely.

Do not start writing code based only on the prompt when the answer can be found in the repository.

---

## Context and Token Efficiency

Keep context usage intentional.

### Read selectively

Do not read large directories or many files "just in case."

Start with search and inspect only relevant files.

Expand context only when necessary.

### Do not repeatedly reread known information

Use this file and project documentation for stable project knowledge.

Relevant documentation may include:

- `docs/SPEC.md` — product requirements
- `docs/ARCHITECTURE.md` — current architecture
- `docs/DATA_MODEL.md` — data structures
- `docs/DECISIONS.md` — important decisions and their rationale

Read these only when relevant to the current task.

### Keep responses concise

For normal implementation work, avoid long explanations of obvious code.

Do not narrate every tool call or intermediate thought.

After implementation, normally report only:

- what changed;
- files changed;
- verification performed;
- anything that still needs manual testing;
- genuine uncertainties or follow-ups.

Give detailed explanations only when requested or when an architectural decision requires them.

---

## Long-Term Context

Do not rely on conversation history as permanent project memory.

Important durable information should live in the repository.

When a task introduces a meaningful architectural or product decision, update the appropriate project documentation if necessary.

Use `docs/DECISIONS.md` for decisions that future work could otherwise accidentally reverse.

Example:

```md
## YYYY-MM-DD — Storage

Decision: Use SwiftData with local storage for MVP.

Reason:
- no backend required;
- simple deployment;
- cloud sync is outside MVP scope.

Do not introduce a backend unless requirements change.
```

---

## Implementation Quality

Follow existing code style and architecture.

Prefer simple, readable implementations over clever ones.

Before considering a task complete:

- check for obvious compile/type errors;
- build the project when practical;
- run relevant tests if they exist;
- inspect the resulting diff for accidental unrelated changes.

Do not claim a task is complete if verification failed.

If verification cannot be performed, state that explicitly.

---

## Git Safety

Do not:
- discard unrelated user changes;
- reset or overwrite existing work;
- rewrite Git history;
- force push;
- delete files merely because they appear unused;

unless explicitly instructed.

Keep changes scoped to the current task.

---

## Communication

If the task is clear, proceed without unnecessary clarification.

Ask a question when an unresolved ambiguity could materially change the implementation.

Do not ask questions that can be answered by inspecting the repository.

When several approaches are possible but one is clearly simpler and consistent with the existing architecture, choose it.

When the choice has meaningful long-term consequences, present the options briefly before implementing.

---

## Default Task Workflow

Unless instructed otherwise:

1. Read this file.
2. Inspect the relevant existing code.
3. Read relevant project documentation if needed.
4. Implement the smallest correct solution.
5. Verify it.
6. Review the diff.
7. Give a short summary.

Repository evidence beats model memory.
Verification beats assumption.
Simple changes beat unnecessary abstraction.