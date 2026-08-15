param(
    [Parameter(Mandatory=$true)]
    [string]$Mode
)

$root = "C:\Projects\eng_loop\fix_loop"
$doneFile = Join-Path $root "task-done.txt"
$startedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Count DONE lines for numbering.
$doneCount = 0
if (Test-Path $doneFile) {
    $doneCount = (Get-Content $doneFile | Where-Object { $_ -match '^DONE-' }).Count
}
$nextDone = $doneCount + 1

# Count SUMMARY files for numbering.
$summaryCount = (Get-ChildItem -Path $root -Filter "SUMMARY*.md" -ErrorAction SilentlyContinue).Count
$nextSummary = $summaryCount + 1

# Branch name per run.
$branch = "fix/run-$nextSummary"
$prFile = "PR-$nextSummary.md"

# Work on a separate branch (isolation).
git checkout -b $branch 2>&1 | Out-Null

# Implementer drafts the fix.
node implementer.js $Mode

# Reviewer grades it (never the implementer).
$reviewOutput = node reviewer.js 2>&1
$reviewText = ($reviewOutput -join "`n")

if ($reviewText -match '(?m)^PASS') {
    $verdict = "PASS"
    git add -A
    git commit -m "fix multiply bug (run $nextSummary)" | Out-Null
    # Simulated PR: a file on the branch describing the PR.
    $prContent = @"
# Pull Request: run $nextSummary

Branch: $branch
Verdict: PASS
Mode: $Mode
"@
    Set-Content -Path $prFile -Value $prContent
    git add $prFile
    git commit -m "open PR for run $nextSummary" | Out-Null
    $action = "opened PR ($prFile)"
} else {
    $verdict = "FAIL"
    $action = "no PR (reviewer said FAIL)"
}

$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# task-done.txt
"DONE-$nextDone at $now" | Add-Content -Path $doneFile

# SUMMARY file
$summaryLines = @(
    "Run: $nextSummary"
    "Started: $startedAt"
    "Finished: $now"
    "Mode: $Mode"
    "Verdict: $verdict"
    "Action: $action"
    "Reviewer output:"
) + ($reviewOutput | ForEach-Object { "  $_" })

Set-Content -Path (Join-Path $root "SUMMARY$nextSummary.md") -Value $summaryLines

# Console
Write-Output "===== Fix Loop ====="
Write-Output "Run: $nextSummary"
Write-Output "Mode: $Mode"
Write-Output "Verdict: $verdict"
Write-Output "Action: $action"
$reviewOutput | ForEach-Object { Write-Output $_ }
Write-Output "Wrote task-done.txt -> DONE-$nextDone"
Write-Output "Wrote SUMMARY$nextSummary.md"
Write-Output "===================="
