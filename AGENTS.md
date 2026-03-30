# AGENTS.md

This repository is a **Scoop bucket** containing package manifests for the [Scoop](https://scoop.sh) package manager on Windows.

## Repository Structure

```
bucket/           # Package manifest JSON files (one per app)
bin/              # Helper scripts (checkver, checkhashes, test, etc.)
scripts/          # Pre/post install scripts for specific packages
.github/          # Issue templates and CI workflows
```

## Commands

### Testing
```powershell
# Run all Pester tests (validates all manifests)
.\bin\test.ps1

# Run tests with PowerShell
pwsh .\bin\test.ps1
```

### Validation
```powershell
# Check versions against upstream releases
.\bin\checkver.ps1 <app-name>        # Single app
.\bin\checkver.ps1                   # All apps

# Verify download hashes
.\bin\checkhashes.ps1 <app-name>     # Single app
.\bin\checkhashes.ps1                # All apps

# Check URLs are valid
.\bin\checkurls.ps1 <app-name>

# Format JSON files
.\bin\formatjson.ps1
```

### Auto-update PR
```powershell
.\bin\auto-pr.ps1 -App <app-name>
```

## Manifest Format

Each manifest in `bucket/` is a JSON file with this structure:

```json
{
    "version": "1.0.0",
    "description": "Short description",
    "homepage": "https://example.com",
    "license": "MIT",
    "architecture": {
        "64bit": {
            "url": "https://example.com/app-1.0.0-win64.zip",
            "hash": "sha256:abc123..."
        },
        "32bit": { ... }
    },
    "shortcuts": [ ["app.exe", "App Name"] ],
    "bin": "app.exe",
    "persist": ["config"],
    "checkver": {
        "github": "https://github.com/user/repo"
    },
    "autoupdate": {
        "architecture": {
            "64bit": {
                "url": "https://github.com/.../v$version/app-$version-win64.zip"
            }
        }
    }
}
```

## Code Style

### JSON Formatting
- **Indentation**: 4 spaces
- **Line endings**: CRLF (Windows)
- **Charset**: UTF-8
- **Final newline**: Yes
- **Trailing whitespace**: None

### Naming Conventions
- Manifest filename: lowercase, hyphens for spaces (`my-app.json`)
- Use standard SPDX license identifiers (`MIT`, `GPL-3.0-only`, `Apache-2.0`)
- Hash algorithm: SHA256 (default, no prefix needed) or `sha1:`, `md5:`

### Autoupdate URL Patterns
- Use `$version` placeholder: `v$version` or `-$version`
- Match the actual release URL pattern on GitHub/other hosts
- Include filename fragment after `#` if rename needed: `.../file.zip#/app.exe`

### EXE Installers
Some apps distribute only `.exe` installers. Scoop can extract these by appending `#/dl.7z` to the URL:

```json
"architecture": {
    "64bit": {
        "url": "https://example.com/app-setup.exe#/dl.7z",
        "hash": "sha256:..."
    }
}
```

Important: The fragment **must** start with `#/` (not `#`) for Scoop to recognize it.

### Checking File Structure
Before using `extract_dir` or `pre_install` scripts, always check the actual file structure:

- **MSI files**: Use `msiexec /a installer.msi /qn TARGETDIR=output` to extract and inspect the structure
- **ZIP/7z archives**: Use `7z l archive.zip` to list contents or extract to inspect
- **NSIS installers**: Use `7z l installer.exe` to list contents or `innounp` to extract

### extract_dir
Some installers or archives extract contents to a subdirectory. Use `extract_dir` to specify the correct path:

```json
"architecture": {
    "64bit": {
        "url": "https://example.com/app-setup.msi",
        "hash": "sha256:...",
        "extract_dir": "PFiles\\AppName"
    }
}
```

#### Nested NSIS structures
Some NSIS installers (e.g., bilibili) contain a nested `app-64.7z` inside `$PLUGINSDIR`.
Scoop's auto-extraction won't handle these—use `pre_install` to extract manually:

```json
"architecture": {
    "64bit": {
        "url": "https://example.com/app-setup.exe#/dl.7z",
        "hash": "sha256:...",
        "pre_install": [
            "Expand-7zipArchive \"$dir\\`$PLUGINSDIR\\app-64.7z\" \"$dir\"",
            "Remove-Item \"$dir\\`$PLUGINSDIR\", \"$dir\\Uninstall*\" -Recurse"
        ]
    }
}
```

See `bucket/bilibili.json` for a working example.

## Commit Messages

Format: `<app-name>: <action> to version <version>`

Examples:
```
cc-switch: Update to version 3.12.3
hmcl: Update to version 3.6.18
new-app: Add version 1.0.0
old-app: Remove deprecated app
```

## PR Guidelines

- Reference related issue: `Closes #XXXX` or `Relates to #XXXX`
- Single manifest change per PR preferred
- Verify with `.\bin\checkver.ps1` and `.\bin\checkhashes.ps1` before submitting

## Notes for Agents

- Always validate JSON syntax before committing
  - PowerShell: `pwsh -c "Get-Content bucket/app.json | ConvertFrom-Json"`
  - Python: `python -c "import json; json.load(open('bucket/app.json', encoding='utf-8'))"`
- Download and compute hash for new versions using `Get-FileHash -Algorithm SHA256`
- Use GitHub API (`api.github.com/repos/{owner}/{repo}/releases`) to get asset URLs
- If repository was transferred, update `homepage` and `checkver.github` URLs
- Test manifests locally with `.\bin\test.ps1` before committing
