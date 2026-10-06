---
name: concise-comments-and-docs
description: Sets the writing style for code comments and documentation. Comments and docs are concise, avoid semicolons and em dashes, describe the current state of the code, and put what the audience needs most first. Use whenever writing or editing code comments, docstrings, READMEs, or other documentation.
---

# Concise comments and docs

Apply these rules to every code comment, docstring, README, and other
documentation you write or edit.

## Style

- Be concise and to the point. Cut words that don't add information.
- Don't use semicolons in prose. Split the sentence or use a comma.
- Don't use em dashes (—). Use a period, comma, colon, or parentheses.
- These rules apply to prose only. Code syntax that requires semicolons is
  fine.

## Describe the current state

- Describe what the code or system does now, after your changes.
- Don't narrate history, such as "changed X to Y", "previously", "now uses",
  or "fixed by". That belongs in commit messages and merge requests.
- Mention a prior or alternative approach only if it's a trap someone would
  fall into. State what fails and why, so the reader doesn't try it.

Good:

```python
# Read the config before forking. Reading it in the child races with
# the reload signal handler.
```

Bad:

```python
# Moved config read here; it used to be in the child — that caused a race.
```

## Comments

- Comment only what the code can't show: constraints, invariants, non-obvious
  reasons, and traps.
- Don't restate what the next line does.

## Documentation structure

- Identify the target audience before writing.
- Lead with what that audience needs first, such as what the thing is, how to
  use it, or the answer to the question they came with.
- Put details, background, edge cases, and reference material after that.
- Use headings so readers can stop once they have what they need.
