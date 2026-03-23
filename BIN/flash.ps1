# Unowhy Tools BIOS Unlocker
# by STY1001

$version = "5.1"
$ESC = [char]27

$versionMap = [ordered]@{
    "2019"   = @{ Label = "2019"; File = "BIOS_2019_NoPwd.rom"; Tool = "AFUWIN" }
    "2020"   = @{ Label = "2020"; File = "BIOS_2020_NoPwd.rom"; Tool = "AFUWIN" }
    "2021"   = @{ Label = "2021"; File = "BIOS_2021_NoPwd.rom"; Tool = "AFUWIN" }
    "2022_1" = @{ Label = "2022 (0.1.1)"; File = "Y13_2022_Unlocked_0.1.1.rom"; Tool = "AFUWIN" }
    "2022_2" = @{ Label = "2022 (0.5.1)"; File = "Y13_2022_Unlocked_0.5.1.rom"; Tool = "AFUWIN" }
    "2023_1" = @{ Label = "2023 (0.20.15)"; File = "Y13_Software_2023_0.20.15_Unlocked.bin"; Tool = "FPTW" }
    "2024_1" = @{ Label = "2024 (0.20.11)"; File = "Y13_Software_2024_0.20.11_Unlocked.bin"; Tool = "FPTW" }
    "2025_1" = @{ Label = "2025 (0.20.18)"; File = "Y13_Software_2025_0.20.18_Unlocked.bin"; Tool = "FPTW" }
}

$expectedHashes = @{
    "BIOS_2019_NoPwd.rom"                          = ""
    "BIOS_2020_NoPwd.rom"                          = ""
    "BIOS_2021_NoPwd.rom"                          = ""
    "Y13_2022_Unlocked_0.1.1.rom"                  = ""
    "Y13_2022_Unlocked_0.5.1.rom"                  = ""
    "Y13_Software_2023_0.20.15_Unlocked.bin"       = ""
    "Y13_Software_2024_0.20.11_Unlocked.bin"       = ""
    "Y13_Software_2025_0.20.18_Unlocked.bin"       = ""
}

$logFile = Join-Path $PSScriptRoot "UTBU_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp | $Message"
}

function Write-Color {
    param(
        [string]$Message,
        [ValidateSet("Red", "Green", "Yellow", "Cyan", "BlinkRed", "BlinkGreen", "BlinkYellow", "BlinkCyan")]
        [string]$Color = "Red"
    )
    $codes = @{
        Red          = "31"
        Green        = "32"
        Yellow       = "33"
        Cyan         = "36"
        BlinkRed     = "5;31"
        BlinkGreen   = "5;32"
        BlinkYellow  = "5;33"
        BlinkCyan    = "5;36"
    }
    Write-Host "$ESC[$($codes[$Color])m$Message$ESC[0m"
}

function Pause-Script {
    Write-Host "Press any key to continue..." -NoNewline
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host ""
}

function Confirm-Choice {
    param([string]$Prompt)
    $response = Read-Host "$Prompt $ESC[3;5;39m[Y]/[N]$ESC[0m"
    return ($response.Trim().ToUpper() -eq 'Y')
}

$lines = "================================================================="

function Show-Header {
    param(
        [hashtable]$VersionInfo = $null,
        [string]$Mode = ""
    )
    Clear-Host
    Write-Host $lines
    Write-Host ""
    Write-Host "   Unowhy Tools BIOS Unlocker $version"
    Write-Host "   by STY1001"
    Write-Host "   - for Unowhy Y13 (2019-2025)"
    Write-Host ""
    Write-Host "   Information about this PC (save this in case of issues!) :"
    Write-Host "   - Model (SKU) : $($model.SystemSKUNumber)"
    Write-Host "   - BIOS Version : $($biosver.SMBIOSBIOSVersion)"
    if ($VersionInfo) {
        Write-Host ""
        Write-Host "   Selected version : $($VersionInfo.Label) (Mode: $Mode)"
    }
    Write-Host ""
    Write-Host $lines
    Write-Host ""
}

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-ACPower {
    $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) {
        try {
            $status = Get-CimInstance -ClassName BatteryStatus -Namespace root\wmi -ErrorAction SilentlyContinue
            if ($status -and -not $status.PowerOnline) {
                return $false
            }
        }
        catch {
            Write-Log "Could not check AC power: $_"
        }
    }
    return $true
}

function Test-ROMIntegrity {
    param(
        [string]$FilePath,
        [string]$FileName
    )

    if (-not $expectedHashes.ContainsKey($FileName)) {
        Write-Color "No hash registered for '$FileName'. Skipping integrity check." -Color Yellow
        Write-Log "No hash for $FileName"
        return $true
    }

    $expected = $expectedHashes[$FileName]
    if ([string]::IsNullOrWhiteSpace($expected)) {
        Write-Color "Hash for '$FileName' is empty. Skipping integrity check." -Color Yellow
        Write-Log "Empty hash for $FileName"
        return $true
    }

    Write-Host "Verifying ROM integrity..."
    $fileHash = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
    Write-Log "ROM hash check: expected=$expected got=$fileHash"

    if ($fileHash -ne $expected) {
        Write-Color "ROM integrity check FAILED!" -Color BlinkRed
        Write-Color "Expected : $expected" -Color Red
        Write-Color "Got      : $fileHash" -Color Red
        return $false
    }

    Write-Color "ROM integrity verified." -Color Green
    Write-Log "ROM integrity OK"
    return $true
}

function Select-BackupDrive {
    $drives = Get-CimInstance -ClassName Win32_LogicalDisk |
        Where-Object { $_.DriveType -in @(2, 3) } |
        Sort-Object DeviceID |
        Select-Object @{Name = "Letter"; Expression = { '[{0}]' -f $_.DeviceID.TrimEnd(':') } },
        @{Name = "Volume Name"; Expression = { $_.VolumeName } },
        @{Name = "Device Type"; Expression = {
                switch ($_.DriveType) {
                    2 { "Removable" }
                    3 { "Fixed" }
                    default { "Other" }
                }
            }
        },
        @{Name = "Free Space (GB)"; Expression = { [math]::Round($_.FreeSpace / 1GB, 2) } },
        @{Name = "Total Size (GB)"; Expression = { [math]::Round($_.Size / 1GB, 2) } }

    Write-Host "Select the drive to save the current BIOS backup :"
    $drives | Format-Table -AutoSize | Out-Host

    $validLetters = ($drives | ForEach-Object { $_.Letter.Trim('[', ']') }) -join ','
    do {
        $letter = Read-Host "Enter a valid drive letter $ESC[3;5;39m[$validLetters]$ESC[0m"
    } while ($letter.Trim().ToUpper() -notmatch "^[$validLetters]$")

    return ($letter.Trim().ToUpper() + ":")
}

function Backup-BIOS {
    param([string]$DriveLetter)

    $backupDir = Join-Path -Path $DriveLetter -ChildPath "UTBU"
    if (-not (Test-Path -Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }

    $serial = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber
    $ext = if ($pcVersionInfo.Tool -eq "AFUWIN") { "rom" } else { "bin" }
    $backupPath = Join-Path -Path $backupDir -ChildPath ("UTBU_Backup_{0}.{1}" -f ($serial -replace '\s', '_'), $ext)

    if (Test-Path -Path $backupPath) {
        Remove-Item -Path $backupPath -Force
    }

    Write-Color "Backing up current BIOS to '$backupPath'..." -Color BlinkYellow
    Write-Log "Backup started: $backupPath (Tool: $($pcVersionInfo.Tool))"

    try {
        if ($pcVersionInfo.Tool -eq "AFUWIN") {
            $process = Start-Process -FilePath "$PSScriptRoot\AFUWINx64.EXE" -ArgumentList "$backupPath /O" -Wait -NoNewWindow -PassThru
        }
        else {
            $process = Start-Process -FilePath "$PSScriptRoot\FPTW.exe" -ArgumentList "-D $backupPath" -Wait -NoNewWindow -PassThru
        }

        if ($process.ExitCode -eq 0) {
            Write-Color "Backup completed successfully!" -Color Green
            Write-Log "Backup OK: $backupPath"
            return $true
        }
        else {
            Write-Color "Backup failed! (Exit code: $($process.ExitCode))" -Color BlinkRed
            Write-Log "Backup FAILED: exit code $($process.ExitCode)"
            return $false
        }
    }
    catch {
        Write-Color "Backup error: $_" -Color BlinkRed
        Write-Log "Backup ERROR: $_"
        return $false
    }
}

function Update-BIOS {
    param(
        [string]$VersionKey,
        [string]$BinPath
    )

    $info = $versionMap[$VersionKey]
    Write-Color "Flashing BIOS with $($info.Label)..." -Color BlinkYellow
    Write-Log "Flash started: $BinPath (Tool: $($info.Tool))"

    try {
        if ($info.Tool -eq "AFUWIN") {
            $process = Start-Process -FilePath "$PSScriptRoot\AFUWINx64.EXE" -ArgumentList "$BinPath /P /B /N /R /X /CLRCFG" -Wait -NoNewWindow -PassThru
        }
        else {
            $process = Start-Process -FilePath "$PSScriptRoot\FPTW.exe" -ArgumentList "-F $BinPath -BIOS" -Wait -NoNewWindow -PassThru
        }

        if ($process.ExitCode -eq 0) {
            Write-Log "Flash OK"
            return $true
        }
        else {
            Write-Color "Flash process returned exit code: $($process.ExitCode)" -Color BlinkRed
            Write-Log "Flash FAILED: exit code $($process.ExitCode)"
            return $false
        }
    }
    catch {
        Write-Color "Flash error: $_" -Color BlinkRed
        Write-Log "Flash ERROR: $_"
        return $false
    }
}

function Select-VersionManually {
    Write-Host "Select your Y13 version :"
    Write-Host ""

    $keys = @($versionMap.Keys)
    for ($i = 0; $i -lt $keys.Count; $i++) {
        Write-Host "  [$($i + 1)] $($versionMap[$keys[$i]].Label)"
    }
    Write-Host ""

    do {
        $choice = Read-Host "Enter a number $ESC[3;5;39m[1-$($keys.Count)]$ESC[0m"
    } while ($choice -notmatch '^\d+$' -or [int]$choice -lt 1 -or [int]$choice -gt $keys.Count)

    return $keys[[int]$choice - 1]
}

$model = Get-CimInstance -ClassName Win32_ComputerSystem
$biosver = Get-CimInstance -ClassName Win32_BIOS

Write-Log "=========================================="
Write-Log "UTBU $version started"
Write-Log "Model (SKU): $($model.SystemSKUNumber)"
Write-Log "BIOS Version: $($biosver.SMBIOSBIOSVersion)"
Write-Log "Serial: $($biosver.SerialNumber)"
Write-Log "=========================================="

$pcVersion = $null
$selectMode = "Auto"
$pcVersionInfo = $null

switch ($model.SystemSKUNumber) {
    "Y13G010S4EI" { $pcVersion = "2019" }
    "Y13G010S4EI2" { $pcVersion = "2020" }
    "Y13G011S4EI" { $pcVersion = "2021" }
    "Y13G012S4EI" {
        switch -Regex ($biosver.SMBIOSBIOSVersion) {
            "0\.1\.1" { $pcVersion = "2022_1" }
            "0\.5\.1" { $pcVersion = "2022_2" }
            default {
                Write-Log "Unknown BIOS version for 2022 model: $($biosver.SMBIOSBIOSVersion)"
                $pcVersion = $null
            }
        }
    }
    "Y13G113S4EI" { $pcVersion = "2023_1" }
    "Y13G201S4EI" { $pcVersion = "2024_1" }
    "Y13G202S4EI" { $pcVersion = "2025_1" }
    default { $pcVersion = $null }
}

Write-Log "Auto-detected version: $(if ($pcVersion) { $pcVersion } else { 'NONE' })"

$requiredTools = @("AFUWINx64.EXE", "FPTW.exe")
foreach ($tool in $requiredTools) {
    if (-not (Test-Path "$PSScriptRoot\$tool")) {
        Write-Color "Error: $tool not found in $PSScriptRoot !" -Color BlinkRed
        Write-Log "FATAL: Missing tool $tool"
        exit 1
    }
}

Show-Header

if (-not (Test-Admin)) {
    Write-Color "This script must be run as Administrator!" -Color BlinkRed
    Write-Log "FATAL: Not running as admin"
    exit 1
}

Show-Header

if (-not (Test-ACPower)) {
    Write-Color "Charger not detected! Please plug in before continuing." -Color BlinkRed
    Write-Log "AC power not detected"
    if (-not (Confirm-Choice "Continue anyway? (NOT RECOMMENDED)")) {
        exit 1
    }
    Write-Log "User chose to continue without AC power"
}

Show-Header

if ($null -eq $pcVersion) {
    Write-Color "This PC is not recognized as a Unowhy Y13!" -Color BlinkYellow
    Write-Log "PC not recognized"

    if (-not (Confirm-Choice "Are you sure this PC is a Unowhy Y13?")) {
        Show-Header
        Write-Color "Aborting." -Color BlinkRed
        Write-Log "User aborted"
        exit 0
    }

    Show-Header
    $pcVersion = Select-VersionManually
    $selectMode = "Manual"
    Write-Log "Manual selection: $pcVersion"
}
else {
    Write-Host "Detected model : $ESC[5;39m$($versionMap[$pcVersion].Label)$ESC[0m"

    if (-not (Confirm-Choice "Do you confirm this model?")) {
        Show-Header
        $pcVersion = Select-VersionManually
        $selectMode = "Manual"
        Write-Log "User overrode auto-detection: $pcVersion"
    }
}

if ($null -eq $pcVersion) {
    Show-Header
    Write-Color "No valid version selected. Aborting." -Color BlinkRed
    Write-Log "No version selected"
    exit 0
}

$pcVersionInfo = $versionMap[$pcVersion]
Write-Log "Final selection: $pcVersion ($($pcVersionInfo.Label)) Mode=$selectMode"

Show-Header -VersionInfo $pcVersionInfo -Mode $selectMode

if (Confirm-Choice "Do you want to backup the current BIOS before flashing?") {
    Show-Header -VersionInfo $pcVersionInfo -Mode $selectMode
    $driveLetter = Select-BackupDrive

    Show-Header -VersionInfo $pcVersionInfo -Mode $selectMode
    if (-not (Backup-BIOS -DriveLetter $driveLetter)) {
        Write-Color "Aborting: Backup failed" -Color BlinkRed
        Write-Log "Backup failed, aborting"
        exit 1
    }
    Write-Host ""
    Pause-Script
}

Show-Header -VersionInfo $pcVersionInfo -Mode $selectMode

Write-Color "You are about to flash the BIOS with version $($pcVersionInfo.Label)" -Color Yellow
Write-Host ""
Write-Color "WARNING!" -Color Red
Write-Color "- Plug in the charger." -Color BlinkRed
Write-Color "- Close all programs." -Color BlinkRed
Write-Color "- Do NOT close this window or turn off your PC during the flash!" -Color BlinkRed
Write-Host ""

if (Confirm-Choice "Do you confirm the flash?") {
    $rootDir = Split-Path -Path $PSScriptRoot -Parent
    $romDir = Join-Path -Path $rootDir -ChildPath "ROM"
    $binPath = Join-Path -Path $romDir -ChildPath $pcVersionInfo.File

    if (-not (Test-Path -Path $binPath)) {
        Show-Header -VersionInfo $pcVersionInfo -Mode $selectMode
        Write-Color "BIOS file not found: $binPath" -Color BlinkRed
        Write-Log "ROM file not found: $binPath"
        exit 1
    }

    Show-Header -VersionInfo $pcVersionInfo -Mode $selectMode
    if (-not (Test-ROMIntegrity -FilePath $binPath -FileName $pcVersionInfo.File)) {
        Write-Color "Aborting: ROM integrity check failed!" -Color BlinkRed
        Write-Log "ROM integrity check failed"
        exit 1
    }

    Write-Host ""

    if (Update-BIOS -VersionKey $pcVersion -BinPath $binPath) {
        Write-Host ""
        Write-Color "Operation completed successfully!" -Color BlinkGreen
        Write-Log "Flash completed successfully"

        if ($pcVersionInfo.Tool -eq "AFUWIN") {
            Write-Color "A reboot is required." -Color BlinkYellow
            Pause-Script
            Restart-Computer -Force -Confirm:$false
        }
        elseif ($pcVersionInfo.Tool -eq "FPTW") {
            Write-Color "ME reset required." -Color BlinkYellow
            Pause-Script
            Start-Process -FilePath "$PSScriptRoot\FPTW.exe" -ArgumentList "-GRESET" -Wait -NoNewWindow
        }
    }
    else {
        Write-Host ""
        Write-Color "Flash failed!" -Color BlinkRed
        Write-Log "Flash FAILED"
    }
}
else {
    Show-Header -VersionInfo $pcVersionInfo -Mode $selectMode
    Write-Color "Flash cancelled." -Color BlinkYellow
    Write-Log "Flash cancelled by user"
}

Write-Log "UTBU finished"
exit 0
