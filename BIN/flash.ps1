# Unowhy Tools BIOS Unlocker
# by STY1001

$version = "5.0"

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

$lines = "================================================================="
function Show-Header {
    Clear-Host
    Write-Host $lines
    Write-Host ""
    Write-Host "   Unowhy Tools BIOS Unlocker $version"
    Write-Host "   by STY1001"
    Write-Host "   - for Unowhy Y13 (2019-2025)"
    Write-Host ""
    Write-Host "   Information about this PC (save this in case of issues !) :"
    Write-Host "   - Model (SKU) : $($model.SystemSKUNumber)"
    Write-Host "   - BIOS Version : $($biosver.SMBIOSBIOSVersion)"

    if ($pcVersionInfo) {
        Write-Host ""
        Write-Host "   Selected version : $($pcVersionInfo.Label) (Mode: $selectMode)"
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
        $letter = Read-Host ("Enter a valid drive letter {0}[3;5;39m[$validLetters]{0}[0m" -f [char]27)
    } while ($letter -notmatch "^[$validLetters]$")

    return ($letter.Trim().ToUpper() + ":")
}
    
function Backup-BIOS {
    param (
        [string]$DriveLetter
    )

    $backupDir = Join-Path -Path $DriveLetter -ChildPath "UTBU"
    if (-not (Test-Path -Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
    $backupPath = Join-Path -Path $backupDir -ChildPath ("UTBU_Backup_$((Get-CimInstance -ClassName Win32_BIOS | Select-Object SerialNumber).SerialNumber).$(if ($pcVersionInfo.Tool -eq "AFUWIN") { "rom" } else { "bin" })").Replace(" ", "_")    
    if (Test-Path -Path $backupPath) { Remove-Item -Path $backupPath -Force }
    Write-Host ("{0}[5;33mBacking up current BIOS to $backupPath...{0}[0m" -f [char]27)
    try {
        if ($pcVersionInfo.Tool -eq "AFUWIN") {
            $process = Start-Process -FilePath "$PSScriptRoot\AFUWINx64.EXE" -ArgumentList "$backupPath /O" -Wait -NoNewWindow -PassThru
        }
        elseif ($pcVersionInfo.Tool -eq "FPTW") {
            $process = Start-Process -FilePath "$PSScriptRoot\FPTW.exe" -ArgumentList "-BIOS -D $backupPath" -Wait -NoNewWindow -PassThru
        }

        if ((Test-Path $backupPath) -and ($process.ExitCode -eq 0)) {
            Write-Host ("{0}[5;32mBackup successful !{0}[0m" -f [char]27)
            return $true
        }
        else {
            Write-Host ("{0}[5;31mBackup failed !{0}[0m" -f [char]27)
            return $false
        }
    }
    catch {
        Write-Host ("{0}[5;31mError during backup : $_{0}[0m" -f [char]27)
        return $false
    }
}

function Select-VersionManually {
    Show-Header
    Write-Host "Select the version of your Unowhy Y13 :"
    $i = 1
    $keys = @()
    foreach ($entry in $versionMap.GetEnumerator()) {
        Write-Host "[$i] $($entry.Value.Label)"
        $keys += $entry.Key
        $i++
    }

    do {
        $choice = Read-Host ("{0}[3;5;39m[1-$($versionMap.Count)]{0}[0m" -f [char]27)
    } while (-not ($choice -as [int]) -or $choice -lt 1 -or $choice -gt $versionMap.Count)

    return $keys[$choice - 1]
}


function Update-BIOS {
    param (
        [string]$VersionKey,
        [string]$BinPath
    )

    Write-Host ("{0}[5;31mFlashing $($versionMap[$VersionKey].Label) using $($versionMap[$VersionKey].Tool)...{0}[0m" -f [char]27)
    try {
        if ($versionMap[$VersionKey].Tool -eq "AFUWIN") {
            $process = Start-Process -FilePath "$PSScriptRoot\AFUWINx64.EXE" -ArgumentList "$BinPath /P /N /R" -Wait -NoNewWindow -PassThru
        }
        elseif ($versionMap[$VersionKey].Tool -eq "FPTW") {
            $process = Start-Process -FilePath "$PSScriptRoot\FPTW.exe" -ArgumentList "-BIOS -F $BinPath" -Wait -NoNewWindow -PassThru
        }

        if ($process.ExitCode -eq 0) {
            Show-Header
            Write-Host ("{0}[5;32mFlash successful !{0}[0m" -f [char]27)
            return $true
        }
        else {
            Show-Header
            Write-Host ("{0}[5;31mFlash failed! (Exit Code : $($process.ExitCode)){0}[0m" -f [char]27)
            return $false
        }
    }
    catch {
        Show-Header
        Write-Host ("{0}[5;31mError during flash : $_{0}[0m" -f [char]27)
        return $false
    }
}

$model = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object SystemSKUNumber
$biosver = Get-CimInstance -ClassName Win32_BIOS | Select-Object SMBIOSBIOSVersion

switch -Regex ($model.SystemSKUNumber) {
    "Y13G002S4EI" { $pcVersion = "2019" }
    "Y13G010S4EI" { $pcVersion = "2020" }
    "Y13G011S4EI" { $pcVersion = "2021" }
    "Y13G012S4EI" {
        switch -Regex ($biosver.SMBIOSBIOSVersion) {
            "0\.1\.1" { $pcVersion = "2022_1" }
            "0\.5\.1" { $pcVersion = "2022_2" }
            default { $pcVersion = "2022_1" }
        }
    }
    "Y13G113S4EI" { $pcVersion = "2023_1" }
    "Y13G201S4EI" { $pcVersion = "2024_1" }
    "Y13G202S4EI" { $pcVersion = "2025_1" }
    default { $pcVersion = $null }
}

$requiredTools = @("AFUWINx64.EXE", "FPTW.exe")
foreach ($tool in $requiredTools) {
    if (-not (Test-Path "$PSScriptRoot\$tool")) {
        Write-Host ("{0}[5;31mError: $tool not found in $PSScriptRoot !{0}[0m" -f [char]27)
        exit 1
    }
}

Show-Header

if (-not (Test-Admin)) {
    Write-Host ("{0}[5;31mThis script must be run as Administrator !{0}[0m" -f [char]27)
    exit 1
}

Show-Header

if ($null -eq $pcVersion) {
    Write-Host ("{0}[5;33mThis PC is not recognized as a Unowhy Y13 !{0}[0m" -f [char]27)
    $confirm = Read-Host "Are you sure this PC is a Unowhy Y13 ? $("{0}[3;5;39m[Y]/[N]{0}[0m" -f [char]27)"
    if ($confirm -ne 'Y') { 
        Show-Header
        Write-Host ("{0}[5;31mAborting.{0}[0m" -f [char]27)
        exit 0
    }
    Show-Header
    $pcVersion = Select-VersionManually
    $selectMode = "Manual"
}
else {
    Write-Host ("Detected model : {0}[5;39m$($versionMap[$pcVersion].Label){0}[0m" -f [char]27)
    $confirm = Read-Host "Do you confirm this model ? $("{0}[3;5;39m[Y]/[N]{0}[0m" -f [char]27)"
    if ($confirm -eq 'N') { 
        Show-Header
        $pcVersion = Select-VersionManually 
        $selectMode = "Manual"
    } 
    else { $selectMode = "Auto" }
}

Show-Header

if ($null -eq $pcVersion) {
    Write-Host ("{0}[5;31mNo valid version selected. Aborting.{0}[0m" -f [char]27)
    exit 0
}

$pcVersionInfo = $versionMap[$pcVersion]

Show-Header

$confirm = Read-Host ("Do you want to backup the current BIOS before flashing ? $("{0}[3;5;39m[Y]/[N]{0}[0m" -f [char]27)")
if ($confirm -eq 'Y') {
    Show-Header
    $driveLetter = Select-BackupDrive
    Show-Header
    if (-not (Backup-BIOS -DriveLetter $driveLetter)) {
        Write-Host ("{0}[5;31mAborting : Backup failed{0}[0m" -f [char]27)
        exit 1
    }
    Write-Host ""
    cmd /c pause # Pause to let user see the message
}

Show-Header

Write-Host ("{0}[33mYou are about to flash the BIOS with version {0}[5m$($pcVersionInfo.Label){0}[0m" -f [char]27)
Write-Host ("{0}[4;31mWARNING! :{0}[0m" -f [char]27)
Write-Host ("{0}[5;31m- Plug in the charger.{0}[0m" -f [char]27)
Write-Host ("{0}[5;31m- Close all programs.{0}[0m" -f [char]27)
Write-Host ("{0}[5;31m- Do NOT close this window or turn off your PC during the flash !{0}[0m" -f [char]27)
$confirm = Read-Host "Do you confirm the flash? $("{0}[3;5;39m[Y]/[N]{0}[0m" -f [char]27)"
if ($confirm -eq 'Y') {
    $rootDir = Split-Path -Path $PSScriptRoot -Parent
    $romDir = Join-Path -Path $rootDir -ChildPath "ROM"
    $binPath = Join-Path -Path $romDir -ChildPath $pcVersionInfo.File
    if (Test-Path -Path $binPath) {
        Show-Header
        if (Update-BIOS -VersionKey $pcVersion -BinPath $binPath) {
            Write-Host ("{0}[5;32mOperation completed successfully !{0}[0m" -f [char]27)

            if ($pcVersionInfo.Tool -eq "AFUWIN") {
                Write-Host ("{0}[5;33mA reboot is required.{0}[0m" -f [char]27)
                Pause
                Restart-Computer -Force -Confirm:$false
            }
            elseif ($pcVersionInfo.Tool -eq "FPTW") {
                Write-Host ("{0}[5;33mME reset required.{0}[0m" -f [char]27)
                Pause
                Start-Process -FilePath "$PSScriptRoot\FPTW.exe" -ArgumentList "-GRESET" -Wait -NoNewWindow
            }
        }
        else {
            Write-Host ("{0}[5;31mFlash failed.{0}[0m" -f [char]27)
        }
    }
    else {
        Show-Header
        Write-Host ("{0}[5;31mBIOS file not found: $binPath{0}[0m" -f [char]27)
    }
}
else {
    Show-Header
    Write-Host ("{0}[5;33mFlash cancelled.{0}[0m" -f [char]27)
}

exit 0