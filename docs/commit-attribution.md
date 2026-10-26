# Codex commit attribution

This project uses Codex's officially supported project configuration and repository instructions. `.codex/config.toml` supplies `developer_instructions`; `AGENTS.md` records the same policy for agents and integrations that read repository instructions. These are instructions to Codex, not a Git hook that changes every human-authored commit.

The installed CLI was `codex-cli 0.164.0`. Its `codex features list` reports the old `codex_git_commit` flag as removed, and the current official configuration reference/schema no longer contains `commit_attribution`. Do not use those obsolete settings to claim automatic native attribution is enabled.

New Codex-created commits retain the existing user Git identity and end with exactly one trailer:

```text
Co-authored-by: Codex <noreply@openai.com>
```

The existing user name/email, credentials, repository permissions, global configuration, and previous commits are not changed. This policy is scoped to this repository. New Codex sessions load its project configuration because the repository was already marked trusted. The current session also follows the user's explicit attribution instruction.

Verification: the installed CLI accepted the project config with `codex app-server --strict-config --print-startup-config`. `codex debug prompt-input` confirmed both the project instruction and trailer are in its loaded prompt. Policy commit `93d596f` has the unchanged user author/committer and exactly one parsed Codex co-author trailer; its parent is the unchanged original checkpoint `375af90`. No test-only or rewritten commits were needed.

GitHub recognizes co-author trailers on pushed commits. Listing a co-author as an account/contributor requires the trailer email to be associated with an actual GitHub account and eligible commits on the default branch. Using the standard Codex email does not itself create an account, grant repository access, or guarantee a Contributors avatar. The commit message still contains the explicit credit.

Sources:
- [OpenAI: project configuration](https://learn.chatgpt.com/docs/config-file/config-basic)
- [OpenAI: developer_instructions](https://learn.chatgpt.com/docs/config-file/config-reference)
- [OpenAI: AGENTS.md instructions](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- [GitHub: multiple commit authors](https://docs.github.com/en/pull-requests/how-tos/commit-changes/creating-a-commit-with-multiple-authors)
- [GitHub: project contributors](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/viewing-a-projects-contributors)
