# ============================================================
# Flutter Clean Architecture Template - lib/ Exporter
# Usage: .\export_flutter_template.ps1
# Output: flutter_template_export.txt (in the same directory)
# ============================================================

$OutputFile = "flutter_template.txt"
$RootPath   = Get-Location
$LibPath    = Join-Path $RootPath "lib"

if (-not (Test-Path $LibPath)) {
    Write-Host "❌  'lib' folder not found in: $RootPath" -ForegroundColor Red
    exit 1
}

$Separator    = "=" * 80
$SubSeparator = "-" * 80

$Lines = [System.Collections.Generic.List[string]]::new()

# ── Header ────────────────────────────────────────────────────────────────────
$Lines.Add($Separator)
$Lines.Add("  FLUTTER CLEAN ARCHITECTURE TEMPLATE - lib/ EXPORT")
$Lines.Add("  Generated : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$Lines.Add("  Root Path : $RootPath")
$Lines.Add($Separator)
$Lines.Add("")

# ── 1. Folder Tree (lib/ only) ────────────────────────────────────────────────
$Lines.Add("SECTION 1 — FOLDER STRUCTURE (lib/)")
$Lines.Add($Separator)
$Lines.Add("📁 lib/")

function Get-Tree {
    param (
        [string]$Path,
        [string]$Prefix = ""
    )

    $items = Get-ChildItem -Path $Path -Force |
             Sort-Object { $_.PSIsContainer } -Descending |
             Sort-Object Name

    for ($i = 0; $i -lt $items.Count; $i++) {
        $item      = $items[$i]
        $isLast    = ($i -eq $items.Count - 1)
        $connector = if ($isLast) { "└── " } else { "├── " }
        $childPfx  = if ($isLast) { "    " } else { "│   " }

        if ($item.PSIsContainer) {
            $script:Lines.Add("$Prefix$connector📁 $($item.Name)/")
            Get-Tree -Path $item.FullName -Prefix "$Prefix$childPfx"
        } else {
            $script:Lines.Add("$Prefix$connector📄 $($item.Name)")
        }
    }
}

Get-Tree -Path $LibPath
$Lines.Add("")

# ── 2. File Contents (lib/ only) ─────────────────────────────────────────────
$Lines.Add("SECTION 2 — FILE CONTENTS (lib/)")
$Lines.Add($Separator)
$Lines.Add("")

$AllFiles = Get-ChildItem -Path $LibPath -Recurse -File -Force |
            Where-Object { $_.Extension.ToLower() -eq ".dart" } |
            Sort-Object FullName

$TotalFiles = $AllFiles.Count
$Counter    = 0

foreach ($File in $AllFiles) {
    $Counter++
    $RelativePath = "lib\" + $File.FullName.Substring($LibPath.Length).TrimStart('\').TrimStart('/')

    $Lines.Add($SubSeparator)
    $Lines.Add("FILE [$Counter / $TotalFiles] : $RelativePath")
    $Lines.Add($SubSeparator)

    try {
        $Content = Get-Content -Path $File.FullName -Raw -Encoding UTF8 -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($Content)) {
            $Lines.Add("  << EMPTY FILE >>")
        } else {
            $Content.Replace("`r`n", "`n").Split("`n") | ForEach-Object {
                $Lines.Add($_)
            }
        }
    } catch {
        $Lines.Add("  << COULD NOT READ FILE: $($_.Exception.Message) >>")
    }

    $Lines.Add("")
}

# ── Footer ────────────────────────────────────────────────────────────────────
$Lines.Add($Separator)
$Lines.Add("  END OF EXPORT  |  Total .dart files captured: $TotalFiles")
$Lines.Add($Separator)

# ── Write Output ──────────────────────────────────────────────────────────────
$Lines | Out-File -FilePath $OutputFile -Encoding UTF8
Write-Host ""
Write-Host "✅  Export complete!" -ForegroundColor Green
Write-Host "📄  Output file   : $((Resolve-Path $OutputFile).Path)" -ForegroundColor Cyan
Write-Host "📦  Files captured: $TotalFiles .dart files" -ForegroundColor Cyan
Write-Host ""