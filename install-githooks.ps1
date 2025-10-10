# PowerShell script to install Git hooks from .githooks directory

$HooksDir = ".githooks"
$GitHooksDir = ".git\hooks"

Write-Host "Installing Git hooks..." -ForegroundColor Cyan

# Check if .githooks directory exists
if (-not (Test-Path $HooksDir)) {
    Write-Host "Error: $HooksDir directory not found" -ForegroundColor Red
    exit 1
}

# Check if .git directory exists
if (-not (Test-Path ".git")) {
    Write-Host "Error: Not a git repository" -ForegroundColor Red
    exit 1
}

# Create hooks directory if it doesn't exist
if (-not (Test-Path $GitHooksDir)) {
    New-Item -ItemType Directory -Path $GitHooksDir | Out-Null
}

# Copy all hook files from .githooks to .git/hooks
Get-ChildItem -Path $HooksDir -File | ForEach-Object {
    $hookName = $_.Name
    $target = Join-Path $GitHooksDir $hookName
    
    Copy-Item $_.FullName $target -Force
    
    Write-Host "Installed: $hookName" -ForegroundColor Green
}

Write-Host ""
Write-Host "Git hooks installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Note: Run this script whenever hooks in $HooksDir are updated." -ForegroundColor Yellow