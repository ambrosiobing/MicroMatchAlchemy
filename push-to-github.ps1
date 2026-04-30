# push-to-github.ps1
# One-shot recovery + push for MicroMatchAlchemy.
#
# Run from PowerShell in this folder:
#     powershell -ExecutionPolicy Bypass -File .\push-to-github.ps1
#
# Prerequisites (do these FIRST in your browser):
#   1. Sign in to https://github.com as ambrosiobing.
#   2. Create a NEW empty repo named "MicroMatchAlchemy" (no README, no .gitignore,
#      no LICENSE — keep it empty so the push isn't rejected for non-fast-forward).
#   3. Make sure you have either:
#        a) GitHub CLI installed (`gh auth login` already done), or
#        b) Git Credential Manager set up (it'll pop a browser auth window
#           the first time you push), or
#        c) A Personal Access Token ready to paste when git asks for password.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here
Write-Host "Working in: $here" -ForegroundColor Cyan

# 1. Remove stale lock files (they're 0-byte leftovers from the sandbox).
foreach ($lock in '.git\config.lock', '.git\index.lock') {
    if (Test-Path $lock) {
        Write-Host "Removing stale $lock"
        Remove-Item -Force $lock
    }
}

# 2. Sanity-check the config has the GitHub URL.
$cfg = Get-Content '.git\config' -Raw
if ($cfg -notmatch 'github\.com/ambrosiobing/MicroMatchAlchemy') {
    Write-Host "Repairing .git\config (URL was wrong or file was corrupt)" -ForegroundColor Yellow
    @'
[core]
	repositoryformatversion = 0
	filemode = false
	bare = false
	logallrefupdates = true
	symlinks = false
	ignorecase = true
[remote "origin"]
	url = https://github.com/ambrosiobing/MicroMatchAlchemy.git
	fetch = +refs/heads/*:refs/remotes/origin/*
[branch "main"]
	remote = origin
	merge = refs/heads/main
'@ | Set-Content -NoNewline -Encoding ASCII '.git\config'
}

# 3. Show what we're about to push.
Write-Host "`nremote -v:" -ForegroundColor Cyan
git remote -v
Write-Host "`nbranch:" -ForegroundColor Cyan
git branch --show-current
Write-Host "`nlast 5 commits:" -ForegroundColor Cyan
git log --oneline -5

# 4. Push.
Write-Host "`nPushing to origin/main..." -ForegroundColor Cyan
git push -u origin main

Write-Host "`nDone. Visit https://github.com/ambrosiobing/MicroMatchAlchemy" -ForegroundColor Green
