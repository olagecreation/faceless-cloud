# render-cloud.ps1 — send a render job to GitHub Actions, wait, download the MP4.
# Usage:
#   tools\render-cloud.ps1 -Script my-script.json [-Title "My Video"] [-Style inside-out] [-Voice am_michael]
#                          [-Speed 1.0] [-Music bed] [-Fps 30] [-TempHost] [-Project <committed-name>]
# Requires: token.txt next to this script (created during first-time setup).
param(
  [string]$Script,
  [string]$Project,
  [string]$Title,
  [string]$Style = "inside-out",
  [string]$Voice = "am_michael",
  [double]$Speed = 1.0,
  [string]$Music = "bed",
  [int]$Fps = 30,
  [switch]$TempHost
)

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$tokenFile = Join-Path $root "token.txt"
if (-not (Test-Path $tokenFile)) { Write-Error "token.txt not found next to tools\ — run first-time setup."; exit 1 }
$token = (Get-Content $tokenFile -Raw).Trim()
$h = @{ Authorization = "Bearer $token"; Accept = "application/vnd.github+json" }
$repo = "olagecreation/faceless-cloud"

# 1. submit
$body = @{
  ref    = "main"
  inputs = @{
    project     = $Project
    script_json = if ($Script) { Get-Content $Script -Raw } else { "" }
    style       = $Style
    voice       = $Voice
    speed       = "$Speed"
    music       = $Music
    fps         = "$Fps"
    temp_host   = [bool]$TempHost
  }
}
Invoke-RestMethod -Method Post -Uri "https://api.github.com/repos/$repo/actions/workflows/render.yml/dispatches" -Headers $h -ContentType "application/json" -Body ($body | ConvertTo-Json -Depth 5)
Write-Host "Job submitted, waiting for a run to appear..." -ForegroundColor Cyan
Start-Sleep -Seconds 15

# 2. find the run
$run = (Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/actions/runs?per_page=1" -Headers $h).workflow_runs[0]
Write-Host "Run $($run.id): $($run.html_url)"

# 3. wait
while ($true) {
  Start-Sleep -Seconds 30
  $r = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/actions/runs/$($run.id)" -Headers $h
  Write-Host ("  status: {0}" -f $r.status)
  if ($r.status -eq "completed") { break }
}
if ($r.conclusion -ne "success") { Write-Host "Run FAILED ($($r.conclusion)). Open $($run.html_url) for logs." -ForegroundColor Red; exit 1 }
Write-Host "Render succeeded." -ForegroundColor Green

# 4. download artifacts
$outDir = Join-Path $root "renders"
New-Item -ItemType Directory -Force $outDir | Out-Null
$arts = (Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/actions/runs/$($run.id)/artifacts" -Headers $h).artifacts
$name = if ($Title) { ($Title -replace '[^\w\- ]', '' -replace ' +', '-') } else { "video" }
foreach ($a in $arts) {
  $zip = Join-Path $outDir "$($a.name).zip"
  Invoke-WebRequest -Uri "https://api.github.com/repos/$repo/actions/artifacts/$($a.id)/zip" -Headers $h -OutFile $zip
  Expand-Archive $zip -DestinationPath (Join-Path $outDir $a.name) -Force
  Remove-Item $zip
}
$mp4 = Get-ChildItem $outDir -Recurse -Filter *.mp4 | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($mp4) { Rename-Item $mp4.FullName -NewName "$name.mp4" -ErrorAction SilentlyContinue }
Write-Host "Done. Files in $outDir" -ForegroundColor Green
Get-ChildItem $outDir -Recurse -File | Select-Object FullName, Length | Format-Table -AutoSize
