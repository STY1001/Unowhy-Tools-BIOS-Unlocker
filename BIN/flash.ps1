# Unowhy Tools BIOS Unlocker
# by STY1001

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
    Write-Host "[4] 2022"
    Write-Host "[5] 2022 (Alt)"
    Write-Host "[7] 2024"
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
        $pcversion = "2022"
    }
    if ($confver -eq '5') {
        $pcversion = "2022alt"
    }
    if ($confver -eq '6') {
        $pcversion = "2023"
    }
    if ($confver -eq '7') {
        $pcversion = "2024"
    }

    return $pcversion
}

function binselect ([string]$pcversion) {

    $binreturn = ""

    $bin2019 = "BIOS_2019_NoPwd.rom"
    $bin2020 = "BIOS_2020_NoPwd.rom"
    $bin2021 = "BIOS_2021_NoPwd.rom"
    $bin2022 = "Y13_2022_Unlocked.rom"
    $bin2022alt = "Y13_2022_Unlocked_Alt.rom"
    $bin2023 = "Y13_Software_2023_Unlocked.bin"
    $bin2024 = "Y13_Software_2024_Unlocked.bin"

    if ($pcversion.contains("2019")) {
        $binreturn = $bin2019
    }
    if ($pcversion.contains("2020")) {
        $binreturn = $bin2020
    }
    if ($pcversion.contains("2021")) {
        $binreturn = $bin2021
    }
    if ($pcversion.contains("2022")) {
        $binreturn = $bin2022
    }
    if ($pcversion.contains("2022alt")) {
        $binreturn = $bin2022alt
    }
    if ($pcversion.contains("2023")) {
        $binreturn = $bin2023
    }
    if ($pcversion.contains("2024")) {
        $binreturn = $bin2024
    }

    return $binreturn
}

function flash ([string]$pcversion, [string]$binpathfinal) {

    if ($pcversion.Contains("2023") -or $pcversion.Contains("2024")) {
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
    if($biosver.contains("0.5.1")) {
        $pcversion = "2022alt"
    }
    else {
        $pcversion = "2022"
    }
}
if ($model.contains("Y13G113S4EI")) {
    $pcversion = "2023"
}
if ($model.contains("Y13G201S4EI")) {
    $pcversion = "2024"
}

clear
header

if ($pcversion.contains("null")) {
    Write-Host "Are you sure that PC is an Unowhy Y13 ?"
    $confY13 = Read-Host "[Y]/[N]"
    Write-Host ""
    if ($confY13 -eq 'y') {
        $isY13 = "true"
        $pcversion = confver
    }
}
else {
    Write-Host "Are you sure that Unowhy Y13 is an"$pcversion" ?"
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
    Write-Host "You are ready to flash (Unowhy Y13" $pcversion ")"
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
    exit
}
