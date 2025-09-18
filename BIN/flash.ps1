# Unowhy Tools BIOS Unlocker
# by STY1001

#

function header {
    Write-Host "Unowhy Tools BIOS Unlocker"
    Write-Host "for Unowhy Y13"
    Write-Host "by STY1001"
    Write-Host ""
}

function confver {
    clear
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
    $confver = Read-Host
    if ($confver -eq '1') {
        $pcversion = "2019"
    }
    if ($confver -eq '2') {
        $pcversion = "2020"
    }
    if ($confver -eq '3') {
        $pcversion = "2021"
    }
    if ($confver -eq '4') {
        $pcversion = "2022_1"
    }
    if ($confver -eq '5') {
        $pcversion = "2022_2"
    }
    if ($confver -eq '6') {
        $pcversion = "2023_1"
    }
    if ($confver -eq '7') {
        $pcversion = "2024_1"
    }
    if ($confver -eq '8') {
        $pcversion = "2025_1"
    }

    return $pcversion
}

function model2label ([string]$model) {

    $modellabel = ""

    if ($model.contains("2019")) {
        $modellabel = "2019"
    }
    if ($model.contains("2020")) {
        $modellabel = "2020"
    }
    if ($model.contains("2021")) {
        $modellabel = "2021"
    }
    if ($model.contains("2022_1")) {
        $modellabel = "2022 (0.1.1)"
    }
    if ($model.contains("2022_2")) {
        $modellabel = "2022 (0.5.1)"
    }
    if ($model.contains("2023_1")) {
        $modellabel = "2023 (0.20.15)"
    }
    if ($model.contains("2024_1")) {
        $modellabel = "2024 (0.20.11)"
    }
    if ($model.contains("2025_1")) {
        $modellabel = "2025 (0.20.18)"
    }

    return $modellabel
}

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

    if ($pcversion.contains("2019")) {
        $binreturn = $bin2019
    }
    if ($pcversion.contains("2020")) {
        $binreturn = $bin2020
    }
    if ($pcversion.contains("2021")) {
        $binreturn = $bin2021
    }
    if ($pcversion.contains("2022_1")) {
        $binreturn = $bin2022_1
    }
    if ($pcversion.contains("2022_2")) {
        $binreturn = $bin2022_2
    }
    if ($pcversion.contains("2023_1")) {
        $binreturn = $bin2023_1
    }
    if ($pcversion.contains("2024_1")) {
        $binreturn = $bin2024_1
    }
    if ($pcversion.contains("2025_1")) {
        $binreturn = $bin2025_1
    }

    return $binreturn
}

function flash ([string]$pcversion, [string]$binpathfinal) {

    if ($pcversion.Contains("2023") -or $pcversion.Contains("2024") -or $pcversion.Contains("2025")) {
        .\FPTW.exe -BIOS -F $binpathfinal
    }
    else {
        .\AFUWINx64.EXE $binpathfinal /P /N /R
    }
}

# Start here

[string]$model = Get-CimInstance -Classname Win32_ComputerSystem | Select-Object SystemSKUNumber
[string]$biosver = Get-CimInstance -Classname Win32_BIOS | Select-Object SMBIOSBIOSVersion

$pcversion = "null"
$isY13 = "false"
$flashproceed = "false"

if ($model.contains("Y13G002S4EI")) {
    $pcversion = "2019"
}
if ($model.contains("Y13G010S4EI")) {
    $pcversion = "2020"
}
if ($model.contains("Y13G011S4EI")) {
    $pcversion = "2021"
}
if ($model.contains("Y13G012S4EI")) {
    if($biosver.contains("0.1.1")) {
        $pcversion = "2022_1"
    }
    if($biosver.contains("0.5.1")) {
        $pcversion = "2022_2"
    }
    $pcversion = "2022_1"
}
if ($model.contains("Y13G113S4EI")) {
    if($biosver.contains("0.20.15")) {
        $pcversion = "2023_1"
    }
    $pcversion = "2023_1"
}
if ($model.contains("Y13G201S4EI")) {
    if($biosver.contains("0.20.11")) {
        $pcversion = "2024_1"
    }
    $pcversion = "2024_1"
}
if ($model.contains("Y13G202S4EI"))
{
    if($biosver.contains("0.20.18")) {
        $pcversion = "2025_1"
    }
    $pcversion = "2025_1"
}

clear
header

if ($pcversion.contains("null")) {
    Write-Host "This PC: (Save this info in case of problem)"
    Write-Host "- SKU: $($model)"
    Write-Host "- BIOS Version: $($biosver)"
    Write-Host ""
    Write-Host "Are you sure that PC is an Unowhy Y13 ?"
    $confY13 = Read-Host "[Y]/[N]"
    Write-Host ""
    if ($confY13 -eq 'y') {
        $isY13 = "true"
        $pcversion = confver
    }
}
else {
    Write-Host "This PC: (Save this info in case of problem)"
    Write-Host "- SKU: $($model)"
    Write-Host "- BIOS Version: $($biosver)"
    Write-Host ""
    Write-Host "Are you sure that Unowhy Y13 is a $(model2label($pcversion)) ?"
    $confpcver = Read-Host "[Y]/[N]"
    Write-Host ""
    if ($confpcver -eq 'n') {
        $pcversion = confver
    }
    elseif ($confpcver -eq 'y') {
        $isY13 = "true"
    }
}

if ($pcversion.contains("null")) {
    $isY13 = "false"
}

clear
header

if ($isY13.Contains("true")) {
    Write-Host "You are ready to flash (Unowhy Y13 $(model2label($pcversion)))"
    Write-Host "Do you want to proceed now ?" -ForegroundColor Green
    Write-Host "Warning: Please, put PLUG your charger, CLOSE your programs, SAVE your works and DON'T CLOSE this window OR SHUTDOWN your PC, until the flash stop !!!" -ForegroundColor Red
    $conf = Read-Host "[Y]/[N]"
    Write-Host ""
    if ($conf -eq 'y') {
        $flashproceed = "true"
    }
}

$binfile = binselect($pcversion)
$binpath = "..\ROM\" + $binfile
$binfinal = """$binpath"""

clear
header

if ($flashproceed.Contains("true")) {
    Write-Host "Flashing..." -ForegroundColor Red
    Write-Host "File located at: $($binfinal)"
    flash $pcversion $binfinal
    Write-Host ""
    Write-Host "Please Reboot, To access to the BIOS, press DEL or ESC at boot"
    pause
    exit
}
