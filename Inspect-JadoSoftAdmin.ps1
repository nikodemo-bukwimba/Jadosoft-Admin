# Inspect-JadoSoftAdmin.ps1

$ProjectRoot = "D:\Projects\Barick Phamacy\jadosoft-admin"
$Sep = "=" * 60

function Pass  { param($msg) Write-Host "  [PASS] $msg" -ForegroundColor Green }
function Fail  { param($msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red }
function Warn  { param($msg) Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Title { param($msg) Write-Host "`n$Sep`n  $msg`n$Sep" -ForegroundColor Cyan }

Title "1. Project Root"
if (Test-Path $ProjectRoot) { Pass "Project root exists: $ProjectRoot" }
else { Fail "Project root NOT found: $ProjectRoot" }

Title "2. Main Executable (AdminPanel.exe)"
$ExePath = "$ProjectRoot\build\windows\x64\runner\Debug\AdminPanel.exe"
if (Test-Path $ExePath) {
    $exe = Get-Item $ExePath
    Pass "Executable found: $ExePath"
    Write-Host "       Size: $([math]::Round($exe.Length/1KB,1)) KB"
    Write-Host "       Ver : $($exe.VersionInfo.FileVersion)"
}
else {
    Fail "Executable NOT found: $ExePath"
    Warn "Fix: run 'flutter build windows' then re-run this script."
}

Title "3. Build Output Folder"
$BuildDir = "$ProjectRoot\build\windows\x64\runner\Debug"
if (Test-Path $BuildDir) {
    $files = Get-ChildItem $BuildDir -Recurse -File
    Pass "Build folder exists: $BuildDir"
    Write-Host "       Files: $($files.Count)  |  Size: $([math]::Round(($files | Measure-Object Length -Sum).Sum/1MB,2)) MB"
}
else {
    Fail "Build folder NOT found: $BuildDir"
    Warn "Fix: run 'flutter build windows' first."
}

Title "4. Setup Icon"
$IconPath = "$ProjectRoot\windows\runner\resources\app_icon.ico"
if (Test-Path $IconPath) { Pass "Icon found: $IconPath" }
else { Fail "Icon NOT found: $IconPath" }

Title "5. ISS Script File"
$IssFile = "$ProjectRoot\jadosoft-admin.iss"
if (Test-Path $IssFile) { Pass "ISS file found: $IssFile" }
else { Fail "ISS file NOT found: $IssFile" }

Title "6. Installer Output Directory"
$OutputDir = "$ProjectRoot\installer"
if (Test-Path $OutputDir) { Pass "Output dir exists: $OutputDir" }
else { Warn "Output dir missing - Inno Setup will create it automatically." }

Title "7. Inno Setup Compiler"
$IsccPaths = @(
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe",
    "C:\Program Files (x86)\Inno Setup 5\ISCC.exe"
)
$IsccExe = $null
foreach ($p in $IsccPaths) {
    if (Test-Path $p) {
        $IsccExe = $p
        Pass "ISCC.exe found: $p"
        break
    }
}
if ($IsccExe -eq $null) {
    Fail "Inno Setup not found."
    Warn "Download from: https://jrsoftware.org/isdl.php"
}

Title "8. Existing User Data (Documents\JadoSoftAdmin)"
$DataPath = [Environment]::GetFolderPath("MyDocuments") + "\JadoSoftAdmin"
if (Test-Path $DataPath) { Warn "Existing data folder found - installer will preserve it: $DataPath" }
else { Pass "No prior data folder - fresh install path is clean." }

Title "9. Previous Installation (Registry)"
$AppId = "A3F7B2E1-5C90-4D8A-B1E3-6F2D55C3ACED"
$RegKey1 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{" + $AppId + "}_is1"
$RegKey2 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{" + $AppId + "}_is1"
if ((Test-Path $RegKey1) -or (Test-Path $RegKey2)) {
    Warn "JadoSoft Admin is already installed - uninstall first if needed."
}
else {
    Pass "No previous installation found - clean install."
}

Title "10. Firewall Rule"
try {
    $rules = Get-NetFirewallRule -DisplayName "JadoSoft Admin" -ErrorAction SilentlyContinue
    if ($rules) { Warn "Firewall rule already exists - installer will replace it." }
    else { Pass "No existing firewall rule - installer will create it fresh." }
}
catch {
    Warn "Could not query firewall (run as Administrator for full check)."
}

Title "SUMMARY"
if ($IsccExe -and (Test-Path $IssFile)) {
    Write-Host "  Ready to compile! Run:" -ForegroundColor Green
    Write-Host "  & `"$IsccExe`" `"$IssFile`"" -ForegroundColor Green
}
else {
    Write-Host "  Fix the [FAIL] items above first, then re-run." -ForegroundColor Yellow
}
Write-Host ""