# Unowhy Tools BIOS Unlocker
# by STY1001

$version = "5.0"

$versionMap = @{
    "2019"      = @{ Label = "2019";          File = "BIOS_2019_NoPwd.rom";          Tool = "AFUWIN" }
    "2020"      = @{ Label = "2020";          File = "BIOS_2020_NoPwd.rom";          Tool = "AFUWIN" }
    "2021"      = @{ Label = "2021";          File = "BIOS_2021_NoPwd.rom";          Tool = "AFUWIN" }
    "2022_1"    = @{ Label = "2022 (0.1.1)";   File = "Y13_2022_Unlocked_0.1.1.rom";  Tool = "AFUWIN" }
    "2022_2"    = @{ Label = "2022 (0.5.1)";   File = "Y13_2022_Unlocked_0.5.1.rom";  Tool = "AFUWIN" }
    "2023_1"    = @{ Label = "2023 (0.20.15)"; File = "Y13_Software_2023_0.20.15_Unlocked.bin"; Tool = "FPTW"  }
    "2024_1"    = @{ Label = "2024 (0.20.11)"; File = "Y13_Software_2024_0.20.11_Unlocked.bin"; Tool = "FPTW"  }
    "2025_1"    = @{ Label = "2025 (0.20.18)"; File = "Y13_Software_2025_0.20.18_Unlocked.bin"; Tool = "FPTW"  }
}

function Show-Header {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "$scriptName $version" -ForegroundColor Green
    Write-Host "For Unowhy Y13 (2019-2025)" -ForegroundColor Gray
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Information about this PC (save this in case of issues) :" -ForegroundColor Yellow
    Write-Host "- Model (SKU) : $($model.SystemSKUNumber)"
    Write-Host "- BIOS Version : $($biosver.SMBIOSBIOSVersion)"
    Write-Host "- Architecture : $((Get-CimInstance Win32_ComputerSystem).SystemType)"
    Write-Host ""
}

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Select-Drive {
    $drives = Get-WmiObject Win32_LogicalDisk |
              Where-Object { $_.DriveType -in @(2, 3) } |
              Sort-Object DeviceID |
              Select-Object @{Name="Letter"; Expression={$_.DeviceID.TrimEnd(':')}},
                            @{Name="Type"; Expression={
                                switch ($_.DriveType) {
                                    2 { "Removable" }
                                    3 { "Fixed" }
                                    default { "Other" }
                                }
                            }},
                            @{Name="Free Space (GB)"; Expression={[math]::Round($_.FreeSpace / 1GB, 2)}}

    Write-Host "Select the drive to save the current BIOS backup :" -ForegroundColor Cyan
    $drives | Format-Table -AutoSize

    $validLetters = ($drives | ForEach-Object { $_.Letter }).ToCharArray() -join ','
    do {
        $letter = Read-Host "Enter a valid drive letter [$validLetters]"
    } while ($letter -notmatch "^[$validLetters]$")

    return "$letter`:"
}

function Backup-BIOS {
    param (
        [string]$DriveLetter
    )

    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }

    $backupPath = Join-Path -Path $DriveLetter -ChildPath "Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').rom"
    Write-Host "Backing up current BIOS to $backupPath..." -ForegroundColor Yellow

    try {
        if ($pcVersionInfo.Tool -eq "AFUWIN") {
            & "$PSScriptRoot\AFUWINx64.EXE" $backupPath /O | Out-File $logFile -Append -Encoding UTF8
        }
        elseif ($pcVersionInfo.Tool -eq "FPTW") {
            & "$PSScriptRoot\FPTW.exe" -BIOS -D $backupPath | Out-File $logFile -Append -Encoding UTF8
        }

        if (Test-Path $backupPath) {
            Write-Host "Backup successful !" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "Backup failed !" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Error during backup : $_" -ForegroundColor Red
        return $false
    }
}

function Select-VersionManually {
    Write-Host "Select the version of your Unowhy Y13 :" -ForegroundColor Cyan
    $i = 1
    $versionMap.GetEnumerator() | ForEach-Object {
        Write-Host "[$i] $($_.Value.Label)"
        $i++
    }

    do {
        $choice = Read-Host "[1-$($versionMap.Count)]"
    } while ($choice -notmatch "^[1-$($versionMap.Count)]$")

    return $versionMap.Keys[$choice - 1]
}

function Flash-BIOS {
    param (
        [string]$VersionKey,
        [string]$BinPath
    )

    Write-Host "Preparing to flash $($versionMap[$VersionKey].Label)..." -ForegroundColor Yellow

    try {
        if ($versionMap[$VersionKey].Tool -eq "AFUWIN") {
            Write-Host "Using AFUWIN to flash..." -ForegroundColor Cyan
            $process = Start-Process -FilePath "$PSScriptRoot\AFUWINx64.EXE" -ArgumentList "$BinPath /P /N /R" -Wait -NoNewWindow -PassThru
        }
        elseif ($versionMap[$VersionKey].Tool -eq "FPTW") {
            Write-Host "Using FPTW to flash..." -ForegroundColor Cyan
            $process = Start-Process -FilePath "$PSScriptRoot\FPTW.exe" -ArgumentList "-BIOS -F $BinPath" -Wait -NoNewWindow -PassThru
            if ($process.ExitCode -eq 0) {
                Write-Host "ME reset required. Press Enter to continue..." -ForegroundColor Yellow
                Read-Host
                Start-Process -FilePath "$PSScriptRoot\FPTW.exe" -ArgumentList "-GRESET" -Wait -NoNewWindow
            }
        }

        if ($process.ExitCode -eq 0) {
            Write-Host "Flash successful !" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "Flash failed! (Exit Code : $($process.ExitCode))" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Error during flash : $_" -ForegroundColor Red
        return $false
    }
}

$model = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object SystemSKUNumber
$biosver = Get-CimInstance -ClassName Win32_BIOS | Select-Object SMBIOSBIOSVersion

switch -Regex ($model.SystemSKUNumber) {
    "Y13G002S4EI" { $pcVersion = "2019"      }
    "Y13G010S4EI" { $pcVersion = "2020"      }
    "Y13G011S4EI" { $pcVersion = "2021"      }
    "Y13G012S4EI" {
        switch -Regex ($biosver.SMBIOSBIOSVersion) {
            "0\.1\.1" { $pcVersion = "2022_1" }
            "0\.5\.1" { $pcVersion = "2022_2" }
            default   { $pcVersion = "2022_1" }
        }
    }
    "Y13G113S4EI" { $pcVersion = "2023_1" }
    "Y13G201S4EI" { $pcVersion = "2024_1" }
    "Y13G202S4EI" { $pcVersion = "2025_1" }
    default       { $pcVersion = $null     }
}

$requiredTools = @("AFUWINx64.EXE", "FPTW.exe")
foreach ($tool in $requiredTools) {
    if (-not (Test-Path "$PSScriptRoot\$tool")) {
        Write-Host "Error: $tool not found in $PSScriptRoot !" -ForegroundColor Red
        exit 1
    }
}

Show-Header

if (-not (Test-Admin)) {
    Write-Host "This script must be run as Administrator !" -ForegroundColor Red
    exit 1
}

if ($null -eq $pcVersion) {
    Write-Host "This PC is not recognized as a Unowhy Y13." -ForegroundColor Yellow
    $confirm = Read-Host "Are you sure this PC is a Unowhy Y13 ? [Y]/[N]"
    if ($confirm -ne 'Y') { exit 0 }
    $pcVersion = Select-VersionManually
}
else {
    Write-Host "Detected model : $($versionMap[$pcVersion].Label)"
    $confirm = Read-Host "Do you confirm this model ? [Y]/[N]"
    if ($confirm -eq 'N') { $pcVersion = Select-VersionManually }
}

if ($null -eq $pcVersion) {
    Write-Host "No valid version selected. Aborting." -ForegroundColor Red
    exit 0
}

$pcVersionInfo = $versionMap[$pcVersion]

$driveLetter = Select-Drive

if (-not (Backup-BIOS -DriveLetter $driveLetter)) {
    Write-Host "Aborting : Backup failed." -ForegroundColor Red
    exit 1
}

Write-Host "You are about to flash the BIOS with version $($pcVersionInfo.Label)." -ForegroundColor Yellow
Write-Host "WARNING :" -ForegroundColor Red
Write-Host "- Plug in the charger."
Write-Host "- Close all programs."
Write-Host "- Do NOT close this window or turn off your PC during the flash !"
$confirm = Read-Host "Do you confirm the flash? [Y]/[N]"

if ($confirm -eq 'Y') {
    $binPath = Join-Path -Path $romDir -ChildPath $pcVersionInfo.File
    if (Test-Path $binPath) {
        if (Flash-BIOS -VersionKey $pcVersion -BinPath $binPath) {
            Write-Host "Operation completed successfully !" -ForegroundColor Green
        }
        else {
            Write-Host "Flash failed. Check $logFile for details." -ForegroundColor Red
        }
    }
    else {
        Write-Host "BIOS file not found: $binPath" -ForegroundColor Red
    }
}
else {
    Write-Host "Flash cancelled." -ForegroundColor Yellow
}

exit 0
