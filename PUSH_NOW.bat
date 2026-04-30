@echo off
REM Double-click this file to commit any pending edits and push to GitHub.
REM Pauses at the end so you can read the output before the window closes.

cd /d "%~dp0"

echo.
echo === Removing stuck sandbox lock files ===
if exist .git\config.lock del /f .git\config.lock
if exist .git\index.lock  del /f .git\index.lock

echo.
echo === Current status ===
git status

echo.
echo === Staging all changes ===
git add -A

echo.
echo === Committing ^(if anything pending^) ===
git commit -m "docs(tutorial): screenshots, mermaid diagrams, pseudocode, cleaned brief"

echo.
echo === Pushing to origin/main ===
git push -u origin main

echo.
echo === Done. Latest commits on origin: ===
git log --oneline -5

echo.
echo If push asked for a password, paste a Personal Access Token from
echo https://github.com/settings/tokens (NOT your GitHub login password).
echo.
pause
