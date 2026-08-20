# Podium CLI installer for Windows, via WSL2.
#
# Podium is a Linux tool. On Windows it runs inside WSL2, which is a real Linux
# kernel rather than an emulation layer, so everything behaves as it does on a
# Linux host -- including container IPs being directly routable, which is NOT
# true on macOS.
#
# TWO STAGES, because enabling the WSL Windows features requires a reboot.
# Stage 1 enables them and schedules stage 2 to resume automatically at the next
# logon; stage 2 installs the distro and Podium. The user reboots once and the
# install continues on its own.
#
#   Stage 1 (what a user runs):
#     irm https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-windows.ps1 | iex
#
#   Stage 2 runs itself after the reboot. To run it by hand:
#     powershell -ExecutionPolicy Bypass -File install-windows.ps1 -Stage 2
#
# Must be run from an ELEVATED PowerShell: enabling Windows optional features
# and writing the machine RunOnce key both require it.
#
# NOT YET TESTED END TO END. Every step was performed by hand on a Windows 10
# Home box and works; this script is that sequence automated, and the automation
# itself has not been run yet.

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
$StateFile  = "$env:ProgramData\podium-install-state.json"

function Say  ($m) { Write-Host $m -ForegroundColor Cyan }
function Ok   ($m) { Write-Host "OK  $m" -ForegroundColor Green }
function Warn ($m) { Write-Host "!!  $m" -ForegroundColor Yellow }
function Die  ($m) { Write-Host "ERR $m" -ForegroundColor Red; exit 1 }

function Assert-Elevated {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $pr = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Die "Run this from an elevated PowerShell (right-click > Run as administrator)."
    }
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
    # So: a running hypervisor IS the capability check. Only interrogate the CPU
    # when there is no hypervisor yet, which is the genuine first-run case.
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
    $resumeDir = "$env:ProgramData\podium-install"
    New-Item -ItemType Directory -Force -Path $resumeDir | Out-Null
    $resumeScript = "$resumeDir\install-windows.ps1"
    if ($ScriptPath) {
        Copy-Item $ScriptPath $resumeScript -Force
    } else {
        Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-windows.ps1" -OutFile $resumeScript
    }

    @{ stage = 2; distro = $Distro; linuxUser = $LinuxUser } |
        ConvertTo-Json | Set-Content -Path $StateFile -Encoding UTF8

    # RunOnce rather than a scheduled task: it fires once at the next logon, as
    # the logging-in administrator, and deletes itself. A scheduled task would
    # have to be cleaned up afterwards and can outlive a failed install.
    $cmd = "powershell -ExecutionPolicy Bypass -NoProfile -File `"$resumeScript`" -Stage 2"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" `
                     -Name "PodiumInstallStage2" -Value $cmd
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
# Stage 2 -- WSL runtime, distro, Podium
###############################################################################
function Invoke-Stage2 {
    Assert-Elevated
    Say "Stage 2: installing WSL runtime, $Distro, and Podium"

    if (Test-Path $StateFile) {
        $st = Get-Content $StateFile -Raw | ConvertFrom-Json
        if ($st.distro)    { $Distro    = $st.distro }
        if ($st.linuxUser) { $LinuxUser = $st.linuxUser }
    }

    # The WSL shipped as a Windows component is old -- it has no `--version` and
    # a weaker localhost relay. `--update` pulls the current one. Without this
    # the install appears to work and then behaves subtly differently.
    Say "Updating the WSL runtime (this can take a few minutes)..."
    wsl --update 2>&1 | Out-String | Write-Verbose
    wsl --set-default-version 2 2>&1 | Out-String | Write-Verbose
    Ok "WSL runtime current"

    $installed = (wsl -l -q 2>$null) -join " "
    if ($installed -match [regex]::Escape($Distro)) {
        Ok "$Distro already installed"
    } else {
        Say "Installing $Distro (large download)..."
        # --no-launch avoids the interactive first-run user prompt, which would
        # block an unattended install waiting for input nobody is giving it.
        wsl --install -d $Distro --no-launch 2>&1 | Out-String | Write-Verbose
        Ok "$Distro installed"
    }

    # Configure the distro: systemd (Docker needs it) and a non-root user with
    # passwordless sudo, because the Podium installer refuses to run as root.
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

    Say "Installing Podium inside $Distro..."
    $install = @"
set -e
cd "\$HOME"
curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-ubuntu.sh -o /tmp/install-ubuntu.sh
bash /tmp/install-ubuntu.sh
"@
    Invoke-InDistro -Script $install -User $LinuxUser
    Ok "Podium installed"

    # Docker's group membership only applies to new sessions.
    wsl --terminate $Distro 2>&1 | Out-Null
    Start-Sleep -Seconds 5

    Say "Running podium configure..."
    Invoke-InDistro -Script "podium configure --projects-dir /home/$LinuxUser/podium-projects" -User $LinuxUser

    Remove-Item $StateFile -ErrorAction SilentlyContinue
    Write-Host ""
    Ok "Installation complete."
    Write-Host ""
    Write-Host "  Open a Podium shell:   wsl -d $Distro"
    Write-Host "  Create a project:      podium new php my-project"
    Write-Host ""
    Warn "Two things specific to Windows:"
    Write-Host "  1. WSL shuts an idle distro down and stops its containers with it."
    Write-Host "     Keep a terminal open, or run:  wsl -d $Distro -u root -e sleep infinity"
    Write-Host "  2. Browse projects using the LAN ACCESS address that 'podium status'"
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
    $cmd = "echo $b64 | base64 -d > /tmp/podium-step.sh; chmod +x /tmp/podium-step.sh; /tmp/podium-step.sh < /dev/null; rc=`$?; rm -f /tmp/podium-step.sh; exit `$rc"
    wsl -d $Distro -u $User -- bash -c $cmd
    if ($LASTEXITCODE -ne 0) { Die "Step failed inside $Distro (exit $LASTEXITCODE)" }
}

switch ($Stage) {
    1 { Invoke-Stage1 }
    2 { Invoke-Stage2 }
    default { Die "Unknown stage: $Stage" }
}
