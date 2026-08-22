# Zeltro CLI installer for Windows, via WSL2.
#
# Zeltro is a Linux tool. On Windows it runs inside WSL2, which is a real Linux
# kernel rather than an emulation layer, so everything behaves as it does on a
# Linux host -- including container IPs being directly routable, which is NOT
# true on macOS.
#
# TWO STAGES, because enabling the WSL Windows features requires a reboot.
# Stage 1 enables them and schedules stage 2 to resume automatically at the next
# logon; stage 2 installs the distro and Zeltro. The user reboots once and the
# install continues on its own.
#
#   Stage 1 (what a user runs):
#     irm https://raw.githubusercontent.com/CaneBayComputers/zeltro-cli/master/install-windows.ps1 | iex
#
#   Stage 2 runs itself after the reboot. To run it by hand:
#     powershell -ExecutionPolicy Bypass -File install-windows.ps1 -Stage 2
#
# Windows 10 (version 2004 / build 19041 and newer) and Windows 11 are both
# supported by this one script; nothing in it is Windows 11 specific. Older
# builds are refused up front by Assert-WindowsBuild.
#
# Must be run from a PowerShell started with Run as administrator: enabling the
# Windows optional features and writing the machine RunOnce key both require it.
#
# TESTING STATUS. Stage 1, the RunOnce reboot-resume, and the elevation it needs
# are verified on a Windows 11 VM: the reboot fires stage 2 automatically in an
# elevated window with no user action. The WSL half of stage 2 is NOT verified
# there and cannot be -- Hyper-V will not launch inside VirtualBox for want of
# SLAT, so the distro downloads and then fails to register. Everything past
# `wsl --install` has only been done by hand, on a Windows 10 Home box.

# ASCII ONLY IN THIS FILE. Windows PowerShell 5.1 reads a file with no BOM as
# ANSI, so a UTF-8 character arrives mangled. An em-dash in particular becomes
# mojibake CONTAINING a double quote, which terminates the enclosing string and
# makes the parser silently swallow the rest of the block. The installer then
# ran, printed one line, returned cleanly, and did nothing, with no error.

[CmdletBinding()]
param(
    [int]$Stage = 1,
    [string]$Distro = "Ubuntu-24.04",
    [string]$LinuxUser = $env:USERNAME.ToLower()
)

$ErrorActionPreference = "Stop"
$ScriptPath = $MyInvocation.MyCommand.Path
$StateFile  = "$env:ProgramData\zeltro-install-state.json"
$LogFile    = "$env:ProgramData\zeltro-install\install.log"

function Say  ($m) { Write-Host $m -ForegroundColor Cyan }
function Ok   ($m) { Write-Host "OK  $m" -ForegroundColor Green }
function Warn ($m) { Write-Host "!!  $m" -ForegroundColor Yellow }
function Die  ($m) {
    Write-Host "ERR $m" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Full log: $LogFile"
    try { Stop-Transcript | Out-Null } catch { }
    # Stage 2 runs from RunOnce in a window of its own. Without this pause that
    # window closes the instant the script exits, so the user sees it flash and
    # vanish with no error and no idea the install failed.
    if ($Stage -eq 2) { Read-Host "  Press Enter to close" | Out-Null }
    exit 1
}

# wsl.exe writes UTF-16LE. PowerShell 5.1 captures it through the pipeline using
# the console's ANSI encoding, so every real character arrives followed by a NUL:
# 171 characters of WSL text become a 350-character string. It PRINTS correctly,
# because NULs are invisible, but no -match against it can ever succeed. That
# silently disabled the error diagnostics below -- they looked right, printed the
# right text, and never once fired. Strip the NULs before touching the string.
function Get-WslOutput ($lines) { ($lines | Out-String) -replace "`0", "" }

# Transcript everything. Stage 2 is unattended and its window disappears on
# exit, so without a log on disk a failed install leaves nothing to read.
function Start-Log {
    New-Item -ItemType Directory -Force -Path (Split-Path $LogFile) | Out-Null
    try { Start-Transcript -Path $LogFile -Append -ErrorAction Stop | Out-Null } catch { }
}

function Assert-Elevated {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $pr = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Die "Right-click PowerShell and choose Run as administrator, then run this again."
    }
}

# Windows 10 is supported and always was -- nothing in this script is Windows 11
# specific, and the whole sequence was first done by hand on a Windows 10 Home
# box. What actually matters is the BUILD number, because "wsl --update" and
# "wsl --install" did not exist before version 2004.
#
# Without this gate an old Windows 10 machine enables the features, reboots,
# resumes into stage 2, and only THEN dies at "wsl --update" -- having already
# made the user reboot for nothing. Check before touching anything.
function Assert-WindowsBuild {
    $cv    = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    $build = [int]$cv.CurrentBuildNumber
    $name  = $cv.ProductName
    $disp  = $cv.DisplayVersion
    if (-not $disp) { $disp = $cv.ReleaseId }

    # 18362 = Windows 10 1903, the first build with WSL2 at all.
    if ($build -lt 18362) {
        Die @"
WSL2 needs Windows 10 version 1903 (build 18362) or newer.
This machine reports $name $disp (build $build).

There is no workaround here: WSL2 requires the Virtual Machine Platform, which
this build does not have. Update Windows and re-run.
"@
    }

    # 19041 = Windows 10 2004, the first build shipping "wsl --install" and
    # "wsl --update". Earlier builds can run WSL2 but need the kernel MSI
    # installed by hand, which this installer does not do.
    if ($build -lt 19041) {
        Die @"
This Windows build is too old for an unattended install.
This machine reports $name $disp (build $build).

WSL2 itself works here, but the "wsl --update" and "wsl --install" commands did
not arrive until Windows 10 version 2004 (build 19041), and this installer
depends on both. Updating Windows to 21H2 or 22H2 is far less work than the
manual kernel-MSI route, so that is the recommended fix.
"@
    }

    if ($build -ge 22000) { $label = "Windows 11" } else { $label = "Windows 10" }
    Ok "$label $disp (build $build) supports WSL2"
}

function Assert-Virtualization {
    # These flags inverting is not a hardware change, it is the OS losing sight
    # of the hardware. Measured on one machine, before and after enabling WSL:
    #
    #                                    before    after
    #     HypervisorPresent               False    True
    #     SecondLevelAddressTranslation   True     False
    #     VMMonitorModeExtensions         True     False
    #
    # Once a hypervisor is running Windows is itself virtualized and can no
    # longer see those CPU extensions, so they read False on a machine where
    # WSL2 demonstrably works. An earlier version of this function hard-failed
    # on SLAT and refused to run on exactly the machine it had already set up,
    # telling the user their CPU was inadequate.
    #
    # So: a running hypervisor is taken as the capability check. Only interrogate
    # the CPU when there is no hypervisor yet, which is the genuine first-run
    # case.
    #
    # Caveat, measured on the Windows 11 test VM: inside a virtual machine
    # HypervisorPresent reads True because the GUEST is running under the host's
    # hypervisor -- it read True there with WSL and VirtualMachinePlatform both
    # Disabled and no distro installed. So this can pass on a VM that lacks
    # nested virtualization, where WSL2 will not actually work. That is the
    # better trade: the failure then surfaces from `wsl --install` with a real
    # message, rather than refusing to run on a physical machine that already
    # works.
    if ((Get-CimInstance Win32_ComputerSystem).HypervisorPresent) {
        Ok "Virtualization active (a hypervisor is already running)"
        return
    }

    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    if (-not $cpu.VirtualizationFirmwareEnabled) {
        Die "Virtualization is disabled in firmware. Enable it in BIOS/UEFI (Intel VT-x / AMD-V) and re-run."
    }
    if (-not $cpu.SecondLevelAddressTranslationExtensions) {
        # A warning, not a refusal. This flag is unreliable enough that refusing
        # on it risks blocking a machine that would work fine.
        Warn "SLAT not reported by this CPU. WSL2 requires it; if the install fails, that is the likely cause."
    }
    Ok "Virtualization available ($($cpu.Name.Trim()))"
}

###############################################################################
# Stage 1 -- enable the Windows features, schedule the resume, reboot
###############################################################################
function Invoke-Stage1 {
    Assert-Elevated
    Start-Log
    Assert-WindowsBuild
    Assert-Virtualization

    $wsl = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State
    $vmp = (Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform).State

    if ($wsl -eq "Enabled" -and $vmp -eq "Enabled") {
        Ok "WSL features already enabled -- skipping the reboot"
        Invoke-Stage2
        return
    }

    Say "Enabling WSL and Virtual Machine Platform..."
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -WarningAction SilentlyContinue | Out-Null
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -WarningAction SilentlyContinue | Out-Null
    Ok "Features enabled"

    # Copy ourselves somewhere durable. The user may have run this piped from
    # the internet, in which case there is no file on disk to resume from.
    $resumeDir = "$env:ProgramData\zeltro-install"
    New-Item -ItemType Directory -Force -Path $resumeDir | Out-Null
    $resumeScript = "$resumeDir\install-windows.ps1"
    if ($ScriptPath) {
        Copy-Item $ScriptPath $resumeScript -Force
    } else {
        Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/CaneBayComputers/zeltro-cli/master/install-windows.ps1" -OutFile $resumeScript
    }

    @{ stage = 2; distro = $Distro; linuxUser = $LinuxUser } |
        ConvertTo-Json | Set-Content -Path $StateFile -Encoding UTF8

    # RunOnce rather than a scheduled task: it fires once at the next logon, as
    # the logging-in administrator, and deletes itself. A scheduled task would
    # have to be cleaned up afterwards and can outlive a failed install.
    $cmd = "powershell -ExecutionPolicy Bypass -NoProfile -File `"$resumeScript`" -Stage 2"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" `
                     -Name "ZeltroInstallStage2" -Value $cmd
    Ok "Stage 2 scheduled to resume automatically after reboot"

    Write-Host ""
    Warn "A reboot is required to finish enabling WSL."
    Write-Host "  After you log back in, installation continues on its own in a"
    Write-Host "  PowerShell window. It takes several minutes and downloads ~1GB."
    Write-Host ""
    $answer = Read-Host "Reboot now? (y/N)"
    if ($answer -match '^[Yy]') { Restart-Computer -Force }
    else { Write-Host "Reboot when ready -- installation resumes automatically." }
}

###############################################################################
# Stage 2 -- WSL runtime, distro, Zeltro
###############################################################################
function Invoke-Stage2 {
    Assert-Elevated
    Start-Log
    Assert-WindowsBuild
    Say "Stage 2: installing WSL runtime, $Distro, and Zeltro"

    if (Test-Path $StateFile) {
        $st = Get-Content $StateFile -Raw | ConvertFrom-Json
        if ($st.distro)    { $Distro    = $st.distro }
        if ($st.linuxUser) { $LinuxUser = $st.linuxUser }
    }

    # The WSL shipped as a Windows component is old -- it has no `--version` and
    # a weaker localhost relay. `--update` pulls the current one. Without this
    # the install appears to work and then behaves subtly differently.
    Say "Updating the WSL runtime (this can take a few minutes)..."
    $out = Get-WslOutput (wsl --update 2>&1)
    if ($LASTEXITCODE -ne 0) { Write-Host $out; Die "wsl --update failed (exit $LASTEXITCODE)." }
    wsl --set-default-version 2 2>&1 | Out-String | Write-Verbose
    Ok "WSL runtime current"

    $installed = (Get-WslOutput (wsl -l -q 2>$null)) -replace "\s+", " "
    if ($installed -match [regex]::Escape($Distro)) {
        Ok "$Distro already installed"
    } else {
        Say "Installing $Distro (large download)..."
        # --no-launch avoids the interactive first-run user prompt, which would
        # block an unattended install waiting for input nobody is giving it.
        $out = Get-WslOutput (wsl --install -d $Distro --no-launch 2>&1)
        if ($LASTEXITCODE -ne 0) {
            Write-Host $out
            # Measured on the VirtualBox test VM: the distro downloads fine and
            # then fails to REGISTER, because Hyper-V will not launch without
            # SLAT. Worth naming explicitly -- the raw WSL error blames firmware
            # virtualization, which sends the user into their BIOS for nothing.
            if ($out -match "HCS_E_HYPERV_NOT_INSTALLED" -or
                $out -match "Second Level Address Translation" -or
                $out -match "virtualization is not enabled") {
                Die @"
WSL2 could not start its virtual machine, so $Distro downloaded but could not
be registered. Windows reports that the hypervisor failed to launch.

Usually one of:
  - Virtualization is off in BIOS/UEFI (Intel VT-x / AMD-V). Turn it on.
  - This machine is itself a VM. WSL2 needs nested virtualization WITH SLAT
    passed through to the guest. VirtualBox does not do that, so WSL2 cannot
    run inside a VirtualBox VM at all.
  - Another hypervisor already owns the CPU.

The exact reason is in the System event log under Hyper-V-Hypervisor.
"@
            }
            Die "wsl --install -d $Distro failed (exit $LASTEXITCODE). WSL's own output is above."
        }
        Ok "$Distro installed"
    }

    # Configure the distro: systemd (Docker needs it) and a non-root user with
    # passwordless sudo, because the Zeltro installer refuses to run as root.
    Say "Configuring the distro..."
    $setup = @"
set -e
cat > /etc/wsl.conf <<'CONF'
[boot]
systemd=true
[user]
default=$LinuxUser
CONF
id $LinuxUser >/dev/null 2>&1 || useradd -m -s /bin/bash -G sudo $LinuxUser
echo '$LinuxUser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$LinuxUser
chmod 440 /etc/sudoers.d/$LinuxUser
"@
    Invoke-InDistro -Script $setup -User "root"
    wsl --terminate $Distro 2>&1 | Out-Null   # restart so systemd comes up
    Start-Sleep -Seconds 5
    Ok "systemd enabled, user '$LinuxUser' created"

    Say "Installing Zeltro inside $Distro..."
    $install = @"
set -e
cd ~
curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/zeltro-cli/master/install-ubuntu.sh -o /tmp/install-ubuntu.sh
bash /tmp/install-ubuntu.sh
"@
    Invoke-InDistro -Script $install -User $LinuxUser
    Ok "Zeltro installed"

    # Docker's group membership only applies to new sessions.
    wsl --terminate $Distro 2>&1 | Out-Null
    Start-Sleep -Seconds 5

    Say "Running zeltro configure..."
    Invoke-InDistro -Script "zeltro configure --projects-dir /home/$LinuxUser/zeltro-projects" -User $LinuxUser

    Remove-Item $StateFile -ErrorAction SilentlyContinue
    try { Stop-Transcript | Out-Null } catch { }
    Write-Host ""
    Ok "Installation complete."
    Write-Host ""
    Write-Host "  Open a Zeltro shell:   wsl -d $Distro"
    Write-Host "  Create a project:      zeltro new php my-project"
    Write-Host ""
    Warn "Two things specific to Windows:"
    Write-Host "  1. WSL shuts an idle distro down and stops its containers with it."
    Write-Host "     Keep a terminal open, or run:  wsl -d $Distro -u root -e sleep infinity"
    Write-Host "  2. Browse projects using the LAN ACCESS address that 'zeltro status'"
    Write-Host "     prints. It is the WSL VM's address and changes when WSL restarts,"
    Write-Host "     so read it from status rather than bookmarking it."
}

# Run a bash script inside the distro without fighting three levels of quoting.
# The script is base64'd in and written to a file, never piped to bash: piping
# puts it on stdin, where any interactive `read` in the program being installed
# consumes the script itself as its answer.
function Invoke-InDistro {
    param([string]$Script, [string]$User = "root")
    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Script))
    # No $? or $rc here on purpose. Neither survives the trip into bash through
    # wsl.exe -- they arrive empty, which silently turned every failure into a
    # success. `trap ... EXIT` removes the temp file without needing to capture
    # a status, and bash -c already exits with the status of the last command.
    $cmd = "echo $b64 | base64 -d > /tmp/zeltro-step.sh; chmod +x /tmp/zeltro-step.sh; trap 'rm -f /tmp/zeltro-step.sh' EXIT; /tmp/zeltro-step.sh < /dev/null"
    wsl -d $Distro -u $User -- bash -c $cmd
    if ($LASTEXITCODE -ne 0) { Die "Step failed inside $Distro (exit $LASTEXITCODE)" }
}

switch ($Stage) {
    1 { Invoke-Stage1 }
    2 { Invoke-Stage2 }
    default { Die "Unknown stage: $Stage" }
}
