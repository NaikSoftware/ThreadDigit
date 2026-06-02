---
name: pr
description: Create a GitHub Pull Request targeting main branch with concise, informative description. Use when the user asks to create a PR, pull request, or merge request.
---

# Pull Request

Create a GitHub Pull Request targeting the `main` branch with a short, informative description.

## Description

This skill creates a GitHub PR from the current branch into `main`. It auto-detects the task number from the branch name, generates a concise title and summary, and skips boilerplate test sections.

Use agent git-repository-manager for all git and GitHub operations.

## Instructions

1. **Check current state:**
   - Get the current branch name and extract any task number (e.g., ENG-12345)
   - Verify there are no uncommitted changes (warn the user if there are)
   - Check if the branch has been pushed to remote; if not, push it with `-u`

2. **Analyze changes:**
   - Run `git log main..HEAD --oneline` to see all commits on this branch
   - Run `git diff main...HEAD --stat` for a summary of changed files
   - Understand the full scope of changes across ALL commits, not just the latest one

3. **Generate PR title:**
   - If a task number exists in the branch name, prefix the title with it (e.g., "ENG-12345 Fix dialog navigation")
   - Keep it under 70 characters, concise and descriptive
   - Use imperative mood (e.g., "Add", "Fix", "Update", not "Added", "Fixed")

4. **Generate PR body:**
   - Write a short summary as a bulleted list (1-4 bullets max)
   - Focus on WHAT changed and WHY, not implementation details
   - Do NOT include a "Test plan" or "Test steps" section unless changes involve something truly unusual that requires specific manual verification steps
   - Do NOT include generic test steps like "run the app", "verify it works", etc.

5. **Create the PR:**
   ```bash
   gh pr create --base main --title "PR title" --body "$(cat <<'EOF'
   ## Summary
   - bullet points here
   EOF
   )"
   ```

6. **Return the PR URL** to the user.

7. **Add reviewers:** invoke the `add-reviewers` skill to assign up to 2 reviewers based on git history of the changed files. Do not pick reviewers yourself — delegate to that skill.

## Important

- Never include boilerplate test sections
- Keep the description minimal but informative — readable in under 10 seconds
- The PR body should only contain a `## Summary` section with bullet points
- Reviewer selection is owned by the `add-reviewers` skill — always hand off, never hardcode reviewers here
