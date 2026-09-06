---
name: update
description: Increment the app version by 1, update pubspec.yaml and AppConstants, commit changes, create a git tag, and push to GitHub to trigger automated release.
---

# Update & Release Skill

When the user types `/update` or asks to bump the version and publish a release:

1. Run the automated script:
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/bump_and_release.ps1
   ```
2. Report the new version and tag created, and provide the link to GitHub Actions / Releases.
