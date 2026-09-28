<#
.SYNOPSIS
    Installs (or uninstalls) the arabic-bidi-engineering skill for Antigravity.
.DESCRIPTION
    - Installs the skill via the skills CLI into Antigravity's global skill directory.
    - Mirrors from ~/.agents/skills if installed there by skills CLI 1.7.0+.
    - Idempotently upserts a rule block in %USERPROFILE%\.gemini\GEMINI.md so the
      skill is always-on for Antigravity and Gemini CLI.
.PARAMETER Uninstall
    Remove the Antigravity skill directory and the GEMINI.md rule block.
.EXAMPLE
    & ([scriptblock]::Create((irm https://raw.githubusercontent.com/MosaabGalmod/arabic-bidi-engineering/main/install/antigravity.ps1)))
    & ([scriptblock]::Create((irm https://raw.githubusercontent.com/MosaabGalmod/arabic-bidi-engineering/main/install/antigravity.ps1))) -Uninstall
#>
param(
    [switch]$Uninstall
)

function Invoke-ArabicBidiInstall {
    [CmdletBinding()]
    param(
        [switch]$Uninstall
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell 5.1 or later is required. Current version: $($PSVersionTable.PSVersion)"
    }

    # ---------------------------------------------------------------------------
    # Constants
    # ---------------------------------------------------------------------------
    $SKILL_NAME            = 'arabic-bidi-engineering'
    $SKILL_REPO            = "MosaabGalmod/$SKILL_NAME"
    $MARKER_START          = "<!-- arabic-bidi-engineering:start -->"
    $MARKER_END            = "<!-- arabic-bidi-engineering:end -->"
    $baseDir          = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
    $GEMINI_DIR       = [System.IO.Path]::Combine($baseDir, '.gemini')
    $GEMINI_FILE      = [System.IO.Path]::Combine($GEMINI_DIR, 'GEMINI.md')
    $AGENTS_SKILL_DIR = [System.IO.Path]::Combine($baseDir, '.agents', 'skills', $SKILL_NAME)
    $CONFIG_SKILL_DIR = [System.IO.Path]::Combine($GEMINI_DIR, 'config', 'skills', $SKILL_NAME)
    $LEGACY_SKILL_DIR = [System.IO.Path]::Combine($GEMINI_DIR, 'antigravity', 'skills', $SKILL_NAME)
    $UTF8_NO_BOM      = New-Object System.Text.UTF8Encoding($false)

    # ---------------------------------------------------------------------------
    # Block content (same text as the bash script)
    # ---------------------------------------------------------------------------
    $BLOCK_CONTENT = @"
<!-- arabic-bidi-engineering:start -->
## Arabic output (arabic-bidi-engineering)

- Before writing ANY Arabic text (chat replies, Markdown, documents, UI strings, generated files), load the ``arabic-bidi-engineering`` skill and follow it; for chat replies apply its Section 0 fully.
- In the Antigravity app chat panel, apply Section 0 rule 9: wrap every Arabic chat reply in ``<div dir="rtl">`` with a blank line after the opening tag and before ``</div>``; keep fenced code blocks outside the div.
- In terminal agents that do not render HTML (e.g. Gemini CLI), do not add the div wrapper.
- For Word/Excel/PDF/HTML deliverables, follow the skill's references and run its checker (``scripts/check_arabic_text.py``) before delivery.
<!-- arabic-bidi-engineering:end -->
"@

    # ---------------------------------------------------------------------------
    # Helper: read file as UTF-8 without BOM (returns "" if missing)
    # ---------------------------------------------------------------------------
    function Read-Utf8 {
        param([string]$Path)
        if (Test-Path -LiteralPath $Path) {
            return [System.IO.File]::ReadAllText($Path, $UTF8_NO_BOM)
        }
        return ""
    }

    # ---------------------------------------------------------------------------
    # Helper: write UTF-8 without BOM, LF line endings
    # ---------------------------------------------------------------------------
    function Write-Utf8 {
        param([string]$Path, [string]$Content)
        $bytes = $UTF8_NO_BOM.GetBytes($Content)
        [System.IO.File]::WriteAllBytes($Path, $bytes)
    }

    # ---------------------------------------------------------------------------
    # Helper: safely remove directory or junction/symlink without traversing
    # ---------------------------------------------------------------------------
    function Remove-DirSafely {
        param([string]$Path)
        if ([System.IO.Directory]::Exists($Path) -or [System.IO.File]::Exists($Path) -or (Test-Path -LiteralPath $Path)) {
            $item = Get-Item -LiteralPath $Path -Force
            if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                $item.Delete()
            } else {
                Remove-Item -LiteralPath $Path -Recurse -Force
            }
        }
    }

    # ---------------------------------------------------------------------------
    # Helper: validate markers in GEMINI.md
    # Returns 'none', 'valid', or throws on corrupted
    # ---------------------------------------------------------------------------
    function Get-MarkerState {
        param([string]$Content)
        $startMatches = [regex]::Matches($Content, [regex]::Escape($MARKER_START))
        $endMatches   = [regex]::Matches($Content, [regex]::Escape($MARKER_END))
        $startCount   = $startMatches.Count
        $endCount     = $endMatches.Count

        if ($startCount -eq 0 -and $endCount -eq 0) {
            return 'none'
        }

        if ($startCount -eq 1 -and $endCount -eq 1) {
            if ($startMatches[0].Index -lt $endMatches[0].Index) {
                return 'valid'
            }
        }

        throw "ERROR: Corrupted or unbalanced markers found in $GEMINI_FILE (start: $startCount, end: $endCount). Please fix GEMINI.md manually."
    }

    # ---------------------------------------------------------------------------
    # UNINSTALL path
    # ---------------------------------------------------------------------------
    if ($Uninstall) {
        Write-Host "Removing GEMINI.md rule block for $SKILL_NAME ..."
        if (Test-Path -LiteralPath $GEMINI_FILE) {
            $content = Read-Utf8 $GEMINI_FILE
            $state = Get-MarkerState -Content $content
            if ($state -eq 'valid') {
                $pattern = "(?s)(\r?\n)?$([regex]::Escape($MARKER_START)).+?$([regex]::Escape($MARKER_END))"
                $evaluator = [System.Text.RegularExpressions.MatchEvaluator]{ param($m) "" }
                $newContent = [regex]::Replace($content, $pattern, $evaluator)
                Write-Utf8 $GEMINI_FILE $newContent
                Write-Host "  Removed rule block from $GEMINI_FILE."
            } else {
                Write-Host "  Marker not found in $GEMINI_FILE - nothing to remove."
            }
        } else {
            Write-Host "  $GEMINI_FILE does not exist - nothing to remove."
        }

        Write-Host "Removing Antigravity skill directories ..."
        Remove-DirSafely $CONFIG_SKILL_DIR
        Remove-DirSafely $LEGACY_SKILL_DIR
        Write-Host "  Removed Antigravity skill directories."

        Write-Host ""
        Write-Host "Done. To also remove the installed skill run:"
        Write-Host "  npx skills remove $SKILL_NAME -g -a antigravity"
        return
    }

    # ---------------------------------------------------------------------------
    # INSTALL path
    # ---------------------------------------------------------------------------

    # 1. Check for npx
    Write-Host "Checking for npx ..."
    if (-not (Get-Command 'npx' -ErrorAction SilentlyContinue)) {
        throw "ERROR: 'npx' not found. Please install Node.js (https://nodejs.org) and ensure it is on PATH."
    }
    Write-Host "  npx found: $(Get-Command npx | Select-Object -ExpandProperty Source)"

    # 2. Run skills CLI
    Write-Host ""
    Write-Host "Installing skill via skills CLI ..."
    $npxArgs = @('-y', 'skills', 'add', $SKILL_REPO, '-g', '-a', 'antigravity', '--copy', '-y')
    $global:LASTEXITCODE = 0
    & npx @npxArgs
    if ($LASTEXITCODE -ne 0) {
        throw "ERROR: 'npx skills add' exited with code $LASTEXITCODE."
    }

    # 3. Locate installed source directory
    Write-Host ""
    Write-Host "Locating installed skill ..."
    $agentsSkillFile = [System.IO.Path]::Combine($AGENTS_SKILL_DIR, 'SKILL.md')
    $configSkillFile = [System.IO.Path]::Combine($CONFIG_SKILL_DIR, 'SKILL.md')
    $legacySkillFile = [System.IO.Path]::Combine($LEGACY_SKILL_DIR, 'SKILL.md')

    $sourceDir = $null
    if (Test-Path -LiteralPath $agentsSkillFile) {
        $sourceDir = $AGENTS_SKILL_DIR
    } elseif (Test-Path -LiteralPath $configSkillFile) {
        $sourceDir = $CONFIG_SKILL_DIR
    } elseif (Test-Path -LiteralPath $legacySkillFile) {
        $sourceDir = $LEGACY_SKILL_DIR
    } else {
        throw "ERROR: Expected SKILL.md not found in $AGENTS_SKILL_DIR, $CONFIG_SKILL_DIR, or $LEGACY_SKILL_DIR."
    }
    Write-Host "  Found source skill at: $sourceDir"

    # 4. Mirror to Antigravity directories
    function Mirror-SkillTo {
        param([string]$Source, [string]$Destination)
        if ($Source -ne $Destination) {
            Remove-DirSafely $Destination
            $targetParent = Split-Path -Parent $Destination
            if (-not (Test-Path -LiteralPath $targetParent)) {
                New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
            }
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
            Copy-Item -Path (Join-Path $Source '*') -Destination $Destination -Recurse -Force
        }
    }

    Write-Host "  Mirroring skill to Antigravity directories ..."
    Mirror-SkillTo -Source $sourceDir -Destination $CONFIG_SKILL_DIR
    Mirror-SkillTo -Source $sourceDir -Destination $LEGACY_SKILL_DIR

    if (-not (Test-Path -LiteralPath $configSkillFile)) {
        throw "ERROR: Expected file not found after mirror: $configSkillFile"
    }
    Write-Host "  Verified: $configSkillFile"

    # 5. Upsert GEMINI.md block
    Write-Host ""
    Write-Host "Updating $GEMINI_FILE ..."
    if (-not (Test-Path -LiteralPath $GEMINI_DIR)) {
        New-Item -ItemType Directory -Path $GEMINI_DIR | Out-Null
        Write-Host "  Created directory: $GEMINI_DIR"
    }

    $content = Read-Utf8 $GEMINI_FILE
    $state = Get-MarkerState -Content $content

    if ($state -eq 'valid') {
        # Replace existing block content
        $pattern = "(?s)$([regex]::Escape($MARKER_START)).+?$([regex]::Escape($MARKER_END))"
        $evaluator = [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $BLOCK_CONTENT }
        $newContent = [regex]::Replace($content, $pattern, $evaluator)
        Write-Utf8 $GEMINI_FILE $newContent
        Write-Host "  Updated existing rule block in $GEMINI_FILE."
    } else {
        # State is 'none': append block with a preceding blank line
        $separator = if ($content.Length -gt 0 -and -not $content.EndsWith("`n")) { "`n" } else { "" }
        $newContent = $content + $separator + "`n" + $BLOCK_CONTENT + "`n"
        Write-Utf8 $GEMINI_FILE $newContent
        Write-Host "  Appended rule block to $GEMINI_FILE."
    }

    # 6. Done
    Write-Host ""
    Write-Host "Installation complete."
    Write-Host "  Skill  : $configSkillFile"
    Write-Host "  Rule   : $GEMINI_FILE"
    Write-Host ""
    Write-Host "Restart Antigravity to pick up the new skill and rule."
    Write-Host "Note: to update the skill later, re-run this installer."
}

Invoke-ArabicBidiInstall -Uninstall:$Uninstall
