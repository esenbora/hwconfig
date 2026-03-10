# Permissions

## Auto-Approve
- Read(*), Glob(*), Grep(*)
- Bash(ls|cat|head|tail|wc|echo|pwd *)
- Bash(npm test|npm run test|npm run lint|npx tsc --noEmit|npx vitest|npx playwright *)
- Bash(git status|git diff|git log|git branch|git fetch|git stash list|git show|git blame *)
- Write(src/*|app/*|components/*|lib/*), Edit(src/*|app/*|components/*|lib/*)

## Require Confirmation
- Bash(npm install|pnpm add|yarn add *)
- Bash(npx prisma migrate|npx drizzle-kit *)
- Bash(git commit|git push|git merge|git rebase|git checkout|git switch|git branch -d|git cherry-pick|git tag *)
- Bash(sudo|rm *), Edit(*.config.*|.env*), Write(*.config.*|.env*)

## Always Block
- Bash(rm -rf /|rm -rf ~|rm -rf .git)
- Bash(git push --force *main*|git push -f *main*|git push --force *master*|git push -f *master*)
- Bash(git reset --hard|git clean -fd|git branch -D *)
- Bash(*DROP DATABASE*|*DROP TABLE*)

## Git Commits
- Conventional format (feat:, fix:, docs:), under 72 chars, reference issues, don't amend pushed commits
