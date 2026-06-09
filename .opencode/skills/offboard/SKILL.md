---
name: offboard
description: "Walk through the Designer/Developer wrap-up checklist for offboarding a client engagement — conversationally, one item at a time"
license: MIT
compatibility: opencode
---

## Behavior

Walk through each wrap-up item below as a conversation. Go one item at a time. For each item:
1. Explain what needs to happen and why.
2. If you can assist directly (scan code, check branches, grep for secrets), do it right then.
3. Ask whether the item applies, whether it's done, or whether they need help.
4. Move on when they confirm.

Skip items that clearly don't apply based on what you've already learned. If you're unsure, ask.

## Checklist

### 1. Transfer codebase ownership to the client
Check who owns the repo. Ask whether the client has admin access and whether any transfer is needed.

### 2. Upload files to client-accessible storage
Ask whether all project files (documents, assets, exports) have been uploaded to the client's file storage.

### 3. Figma file transfer
If the engagement involved design work: have Figma files been transferred to the client's organization or exported? Has your team kept a copy? Have client members been removed as editors from your Figma team?

### 4. Archive Slack or other chat rooms
Ask which shared channels or chat rooms exist and whether they should be archived.

### 5. Clean up project management tools
Ask about Trello, Switchboard, or other PM tools. Should boards be archived or closed?

### 6. Transfer password manager entries
Ask whether any credentials are stored in your team's password manager that need to be transferred.

### 7. Delete sensitive user data from machines
Scan the local project directory for potential sensitive data: API keys, tokens, passwords, `.env` files, credential files, database dumps, SSH keys. Report what you find. Ask whether there's anything else that needs cleanup.

### 8. Remove remote RSA keys on machines
Ask whether they added any SSH keys to client servers or services that should be removed.

### 9. Return client equipment
Ask whether they have any client equipment (laptops, hardware) to return.

### 10. Archive the retrospective
Ask whether the project retrospective has been documented and stored somewhere the team can reference it.

### 11. Archive design artifacts
Ask whether screenshots and other design artifacts have been saved somewhere accessible.

### 12. Remind client to rotate credentials
Any credentials or API keys the client shared should be rotated after offboarding.

### 13. Tidy up Google Docs
Ask whether project-related Google Docs have been organized into a folder and made accessible at the organization level.

### 14. Book knowledge transfer session
Ask whether a KT session has been scheduled. If the codebase is in the working directory, offer to help prepare — check the README, look at open branches, scan for TODOs, and identify areas that might need a walkthrough.

## Tone
Calm, professional, thorough. You're a colleague helping them make sure nothing falls through the cracks. Don't rush — each item matters.
