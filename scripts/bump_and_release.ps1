# Automated Version Bump & Release Script for StudySpace
# Usage: powershell -ExecutionPolicy Bypass -File scripts/bump_and_release.ps1 [optional_commit_message]

param(
    [string]$CustomMessage = ""
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting StudySpace Version Bump & Release..." -ForegroundColor Cyan

# 1. Read and parse pubspec.yaml
$pubspecPath = "pubspec.yaml"
$pubspecContent = Get-Content $pubspecPath -Raw

if ($pubspecContent -match "version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)") {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3]
    $build = [int]$matches[4]

    $newPatch = $patch + 1
    $newBuild = $build + 1
    $newVersion = "$major.$minor.$newPatch"
    $newFullVersion = "$newVersion+$newBuild"
    $newTag = "v$newVersion"

    Write-Host "📌 Bumping version from $major.$minor.$patch+$build to $newFullVersion (Tag: $newTag)" -ForegroundColor Green
} else {
    Write-Error "Could not find a valid version in pubspec.yaml"
    exit 1
}

# 2. Update pubspec.yaml
$updatedPubspec = $pubspecContent -replace "version:\s*\d+\.\d+\.\d+\+\d+", "version: $newFullVersion"
Set-Content -Path $pubspecPath -Value $updatedPubspec -NoNewline
Write-Host "✔ Updated pubspec.yaml" -ForegroundColor Green

# 3. Update app_constants.dart
$constantsPath = "lib/core/constants/app_constants.dart"
if (Test-Path $constantsPath) {
    $constantsContent = Get-Content $constantsPath -Raw
    $updatedConstants = $constantsContent -replace "static const String appVersion = '[^']*';", "static const String appVersion = '$newVersion';"
    Set-Content -Path $constantsPath -Value $updatedConstants -NoNewline
    Write-Host "✔ Updated app_constants.dart to $newVersion" -ForegroundColor Green
}

# 4. Commit and Push
$commitMsg = if ($CustomMessage) { "chore(release): bump version to $newTag - $CustomMessage" } else { "chore(release): bump version to $newTag" }

Write-Host "📦 Committing changes..." -ForegroundColor Cyan
git add pubspec.yaml lib/core/constants/app_constants.dart
git commit -m $commitMsg

Write-Host "🏷️ Creating tag $newTag..." -ForegroundColor Cyan
git tag -a $newTag -m "Release $newTag"

Write-Host "🚀 Pushing to GitHub (commits & tags)..." -ForegroundColor Cyan
git push origin main
git push origin $newTag

Write-Host "`n🎉 Success! Version $newTag pushed to GitHub." -ForegroundColor Green
Write-Host "🤖 GitHub Actions will now build and publish StudySpace-release.apk to your releases repository." -ForegroundColor Yellow
