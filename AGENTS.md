# Project instructions

## Commit attribution

- Preserve the user's configured Git author and committer identity. Do not set either identity to Codex or change credentials, permissions, or global Git configuration.
- Whenever Codex creates a commit in this repository, end its message with exactly one `Co-authored-by: Codex <noreply@openai.com>` trailer, separated from the message body by a blank line. Preserve any other existing trailers.
- This applies to commits made through shell commands, GitHub tools, or other integrations. Do not add attribution to commits created independently by the user.
- Apply this policy only to new commits. Do not amend, rebase, or otherwise rewrite existing history solely to add attribution.
