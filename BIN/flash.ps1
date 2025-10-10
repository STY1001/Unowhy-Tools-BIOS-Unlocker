# Unowhy Tools BIOS Unlocker
# by STY1001

$version = "4.0"

[string]$model = Get-CimInstance -Classname Win32_ComputerSystem | Select-Object SystemSKUNumber
[string]$biosver = Get-CimInstance -Classname Win32_BIOS | Select-Object SMBIOSBIOSVersion

function header {
    Write-Host "Unowhy Tools BIOS Unlocker $($version)"
    Write-Host "for Unowhy Y13"
    Write-Host "by STY1001"
    Write-Host ""
    Write-Host "This PC: (Save this info in case of problem)"
    Write-Host "- SKU: $($model)"
    Write-Host "- BIOS Version: $($biosver)"
    Write-Host ""
}

function listselectvolume {
    Clear-Host
    header

    Write-Host "Select the drive letter where do you want to save the BIOS backup"

    # List available volumes
    Get-WmiObject Win32_LogicalDisk | Sort-Object DeviceID | Select-Object @{Name = 'Drive letter'; Expression = { '[{0}]' -f $_.DeviceID.TrimEnd(':') } },
    @{Name = 'Type'; Expression = {
            switch ($_.DriveType) {
                2 { 'Removable' }
                3 { 'Fixed' }
                4 { 'Network' }
                5 { 'CD/DVD' }
                default { 'Other' }
            }
        }
    },
    @{Name = 'Name'; Expression = { $_.VolumeName } },
    @{Name = 'File system'; Expression = { $_.FileSystem } },
    @{Name = 'Free space'; Expression = { '{0} GB' -f [math]::Round($_.FreeSpace / 1GB, 2) } },
    @{Name = 'Total size'; Expression = { '{0} GB' -f [math]::Round($_.Size / 1GB, 2) } } | Format-Table -AutoSize

    # Get available letters
    $availableLetters = Get-WmiObject Win32_LogicalDisk | Sort-Object DeviceID
    $letterrange = "[{0}-{1}]" -f ($availableLetters[0].DeviceID.TrimEnd(':')), ($availableLetters[-1].DeviceID.TrimEnd(':'))

    # Select a volume
    $letter = Read-Host "$letterrange"

    if ($letter -notmatch "^[A-Z]$" -or ($availableLetters.DeviceID -notcontains "$letter`:")) {
        return $null
    }

    return $letter
}

# Manual version selection
function confver {
    Clear-Host
    header

    Write-Host "Select the version of this Unowhy Y13"
    Write-Host "[1] 2019"
    Write-Host "[2] 2020"
    Write-Host "[3] 2021"
    Write-Host "[4] 2022 (0.1.1)"
    Write-Host "[5] 2022 (0.5.1)"
    Write-Host "[6] 2023 (0.20.15)"
    Write-Host "[7] 2024 (0.20.11)"
    Write-Host "[8] 2025 (0.20.18)"
    $confver = Read-Host "[1-8]:"
    switch ($confver) {
        '1' { $pcversion = "2019" }
        '2' { $pcversion = "2020" }
        '3' { $pcversion = "2021" }
        '4' { $pcversion = "2022_1" }
        '5' { $pcversion = "2022_2" }
        '6' { $pcversion = "2023_1" }
        '7' { $pcversion = "2024_1" }
        '8' { $pcversion = "2025_1" }
        default { 
            $pcversion = $null
        }
    }

    return $pcversion
}

# Function to convert model to label
function model2label ([string]$model) {
    $modellabel = ""
    switch -Regex ($model) {
        "2019" { $modellabel = "2019" }
        "2020" { $modellabel = "2020" }
        "2021" { $modellabel = "2021" }
        "2022_1" { $modellabel = "2022 (0.1.1)" }
        "2022_2" { $modellabel = "2022 (0.5.1)" }
        "2023_1" { $modellabel = "2023 (0.20.15)" }
        "2024_1" { $modellabel = "2024 (0.20.11)" }
        "2025_1" { $modellabel = "2025 (0.20.18)" }
        default { $modellabel = "" }
    }
    return $modellabel
}

# Function to select the right binary
function binselect ([string]$pcversion) {
    $binreturn = ""
    $bin2019 = "BIOS_2019_NoPwd.rom"
    $bin2020 = "BIOS_2020_NoPwd.rom"
    $bin2021 = "BIOS_2021_NoPwd.rom"
    $bin2022_1 = "Y13_2022_Unlocked_0.1.1.rom"
    $bin2022_2 = "Y13_2022_Unlocked_0.5.1.rom"
    $bin2023_1 = "Y13_Software_2023_0.20.15_Unlocked.bin"
    $bin2024_1 = "Y13_Software_2024_0.20.11_Unlocked.bin"
    $bin2025_1 = "Y13_Software_2025_0.20.18_Unlocked.bin"
    switch -Regex ($pcversion) {
        "2019" { $binreturn = $bin2019 }
        "2020" { $binreturn = $bin2020 }
        "2021" { $binreturn = $bin2021 }
        "2022_1" { $binreturn = $bin2022_1 }
        "2022_2" { $binreturn = $bin2022_2 }
        "2023_1" { $binreturn = $bin2023_1 }
        "2024_1" { $binreturn = $bin2024_1 }
        "2025_1" { $binreturn = $bin2025_1 }
        default { $binreturn = "" }
    }
    return $binreturn
}

# Flash
function flash ([string]$pcversion, [string]$binpathfinal) {
    if ($pcversion.Contains("2023") -or $pcversion.Contains("2024") -or $pcversion.Contains("2025")) {
        # For 2023 and later, use FPTW (for Jasper Lake)
        .\FPTW.exe -BIOS -F $
        Write-Host "Flash completed. The PC need a ME reset now, press ENTER to proceed."
        pause
        # For this platform, a ME reset is needed after flash to reinitialize the PC
        .\FPTW.exe -GRESET
    }
    else {
        # Else, use AFUWIN
        .\AFUWINx64.EXE $binpathfinal /P /N /R
    }
}

# Entry point (Start here)

$pcversion = $null
$isY13 = $false
$flashproceed = $false

# Detect model
switch -Regex ($model) {
    "Y13G002S4EI" { $pcversion = "2019" }
    "Y13G010S4EI" { $pcversion = "2020" }
    "Y13G011S4EI" { $pcversion = "2021" }

    "Y13G012S4EI" {
        switch -Regex ($biosver) {
            "0\.1\.1" { $pcversion = "2022_1"; break }
            "0\.5\.1" { $pcversion = "2022_2"; break }
            default { $pcversion = "2022_1" }
        }
    }

    "Y13G113S4EI" { $pcversion = "2023_1" }
    "Y13G201S4EI" { $pcversion = "2024_1" }
    "Y13G202S4EI" { $pcversion = "2025_1" }
}

Clear-Host
header

# Confirm if is Y13 (and ask witch version)
if ($null -eq $pcversion) {
    Write-Host "Are you sure that PC is an Unowhy Y13 ?"
    $confY13 = Read-Host "[Y]/[N]:"
    Write-Host ""
    if ($confY13 -eq 'y') {
        $isY13 = $true
        $pcversion = confver
    }
}
# Confirm the detected version
else {
    Write-Host "Are you sure that Unowhy Y13 is a $(model2label($pcversion)) ?"
    $confpcver = Read-Host "[Y]/[N]:"
    Write-Host ""
    if ($confpcver -eq 'n') {
        $pcversion = confver
        if ($null -eq $pcversion) {
            $isY13 = $false
        }
        else {
            $isY13 = $true
        }
    }
    elseif ($confpcver -eq 'y') {
        $isY13 = $true
    }
}

# If nothing selected, exit
if ($null -eq $pcversion) {
    $isY13 = "false"
}

Clear-Host
header

# Backup BIOS
if ($isY13 -eq $true) {
    Write-Host "Do you want to backup your current BIOS before flashing ?"
    $confbackup = Read-Host "[Y]/[N]:"
    Write-Host ""
    if ($confbackup -eq 'y') {
        $letter = listselectvolume
        if ($null -ne $letter) {
            [string]$serial = Get-CimInstance -Classname Win32_BIOS | Select-Object SerialNumber
            $extension = ""
            if ($pcversion.Contains("2023") -or $pcversion.Contains("2024") -or $pcversion.Contains("2025")) {
                $extension = "bin"
            }
            else {
                $extension = "rom"
            }
            $backupfile = "UTBU_Backup_$($serial).$($extension)"
            $backuppath = "$($letter):\$($backupfile)"
            $backuppathfinal = """$backuppath"""

            Write-Host "Backuping BIOS..." -ForegroundColor Green
            Write-Host "File will be saved at: $($backuppathfinal)"
            Write-Host ""
            if ($pcversion.Contains("2023") -or $pcversion.Contains("2024") -or $pcversion.Contains("2025")) {
                # For 2023 and later, use FPTW (for Jasper Lake)
                .\FPTW.exe -BIOS -D $backuppathfinal
            }
            else {
                # Else, use AFUWIN
                .\AFUWINx64.EXE /O $backuppathfinal
            }
            Write-Host ""
            Write-Host "Backup done !" -ForegroundColor Green
            Write-Host ""
        }
        else {
            Write-Host "No valid drive letter selected, backup cancelled." -ForegroundColor Yellow
            Write-Host ""
        }
    }
    else {
        Write-Host "Backup cancelled." -ForegroundColor Yellow
        Write-Host ""
    }
}

pause

Clear-Host
header

# Proceed to flash
if ($isY13 -eq $true) {
    Write-Host "You are ready to flash (Unowhy Y13 $(model2label($pcversion)))"
    Write-Host "Do you want to proceed now ?" -ForegroundColor Green
    Write-Host "Warning: Please, put PLUG your charger, CLOSE your programs, SAVE your works and DON'T CLOSE this window OR SHUTDOWN your PC, until the flash stop !!!" -ForegroundColor Red
    $conf = Read-Host "[Y]/[N]:"
    Write-Host ""
    if ($conf -eq 'y') {
        $flashproceed = $true
    }
}
else {
    Write-Host "This PC is not an Unowhy Y13 or the version is not selected, flash cancelled." -ForegroundColor Red
    Write-Host ""
    exit
}

Clear-Host
header

# Flashing
if ($flashproceed -eq $true) {
    $binfile = binselect($pcversion)
    $binpath = "..\ROM\" + $binfile
    $binfinal = """$binpath"""

    Write-Host "Flashing..." -ForegroundColor Red
    Write-Host "File located at: $($binfinal)"
    Write-Host ""
    flash $pcversion $binfinal
    Write-Host ""
    Write-Host "Flash done !" -ForegroundColor Green
    Write-Host ""
}
 
# Flash cancelled
if ($flashproceed -eq $false) {
    Write-Host "Flash cancelled." -ForegroundColor Yellow
}

exit
