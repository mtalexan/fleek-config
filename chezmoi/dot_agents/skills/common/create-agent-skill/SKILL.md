---
name: create-agent-skill
description: Creates vendor-neutral Agent Skills and asks where each new skill should live. Use whenever the user asks to create, write, add, or author a new SKILL.md or Agent Skill.
compatibility: Requires an agent that can identify the current workspace and git repository roots and can prompt the user for choices.
metadata:
  skill-format: agent-skills
  scope-selection: required
---

# Create a new Agent Skill

Use the vendor-neutral Agent Skills format. Do not choose a destination from
context or product conventions alone. Ask the user for the scope before
creating any files.

## 1. Ask for the scope

Prompt the user with the available interaction mechanism to select exactly one:

- **Project skill** — belongs to one git repository.
- **Workspace skill** — belongs to the current workspace, whether or not that
  workspace is a git repository.
- **Global skill** — belongs to the user and is available across workspaces.

Do not create the skill until this question has been answered.

## 2. Resolve the destination

### Project skill

Identify the git repository that owns the project. Put the skill at:

`<project-repository-root>/.agents/skills/<skill-name>/SKILL.md`

If the current workspace contains more than one git repository and the
intended repository is not unambiguous, prompt the user to select the
repository. If there is no applicable git repository, explain that project
scope is unavailable and ask the user to choose workspace or global scope.

### Workspace skill

Use the current workspace folder itself, not an inferred git root. Put the
skill at:

`<current-workspace-root>/.agents/skills/<skill-name>/SKILL.md`

The workspace root may be:

- The root of a git repository, in which case project and workspace scope
  resolve to the same filesystem location.
- A folder above one or more project repositories.
- A folder containing no git repositories.

Report the absolute workspace root before writing the skill. Do not move a
workspace skill into a nested repository merely because one exists.

### Global skill

Prompt the user to select exactly one category:

- **Work**:
  `~/.agents/skills/work/<skill-name>/SKILL.md`
- **Personal**:
  `~/.agents/skills/personal/<skill-name>/SKILL.md`
- **Common**:
  `~/.agents/skills/common/<skill-name>/SKILL.md`

Do not infer the category and do not write the skill until it is selected.

## 3. Design the skill

Gather or infer:

1. The task and expected outcome.
2. When the skill should be used.
3. Prerequisites, environment constraints, and safety boundaries.
4. Whether supporting scripts, references, or assets are needed.

Ask only for information that cannot be determined from the request or the
available project context.

Choose a concise skill name that:

- Uses only lowercase ASCII letters, digits, and single hyphens.
- Is at most 64 characters.
- Does not begin or end with a hyphen.
- Has no consecutive hyphens.
- Exactly matches the directory containing `SKILL.md`.

Before writing, check all applicable skill roots for an existing skill with
the same name. Never overwrite or merge an existing skill without explicit
user approval.

## 4. Write vendor-neutral frontmatter

Every `SKILL.md` starts with:

```yaml
---
name: skill-name
description: What the skill does and when an agent should use it.
---
```

The description must be nonempty, at most 1024 characters, and include both
the capability and its trigger conditions.

Use only Agent Skills specification fields:

- `name`
- `description`
- `license`
- `compatibility`
- `metadata`
- `allowed-tools` when deliberately using the experimental field

Keep `metadata` a string-to-string map. Do not add product-specific
frontmatter such as `paths`, `globs`, or `disable-model-invocation` unless the
user explicitly requests a product-specific skill.

## 5. Write focused instructions

- Put the essential workflow in `SKILL.md`.
- Make safety checks and confirmation gates explicit.
- Use exact commands where consistency matters.
- Keep `SKILL.md` under 500 lines.
- Put optional detail in files beside it, such as `reference.md`,
  `examples.md`, `scripts/`, or `assets/`.
- Link supporting files directly from `SKILL.md`; avoid deep reference chains.
- Do not place generated files outside the selected skill directory unless the
  workflow explicitly requires runtime state elsewhere.

## 6. Verify and report

Verify:

1. The parent directory name exactly matches `name`.
2. The YAML frontmatter is valid.
3. The description explains what and when.
4. File references resolve.
5. The body is under 500 lines.
6. No existing unrelated skill was overwritten.

Report the skill's absolute path and its selected scope. For global skills,
also report the selected work, personal, or common category.
