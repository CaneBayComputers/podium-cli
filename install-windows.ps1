# Podium Windows Installation Script
# This script sets up WSL2, Docker Desktop, and Podium CLI on Windows

param(
    [switch]$SkipReboot
)

function Write-Output($Message) {
    Write-Host $Message
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-VirtualizationSupport {
    try {
        # Check if Hyper-V is available (indicates virtualization support)
        $hyperv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
        if ($hyperv -and $hyperv.State -eq "Enabled") {
            return $true
        }
        
        # Check if virtualization is enabled in BIOS/UEFI
        $cpu = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
        if ($cpu.VirtualizationFirmwareEnabled -eq $true) {
            return $true
        }
        
        # Alternative check using systeminfo
        $systemInfo = systeminfo /fo csv | ConvertFrom-Csv
        $hyperVRequirements = $systemInfo."Hyper-V Requirements"
        if ($hyperVRequirements -match "Yes") {
            return $true
        }
        
        return $false
    }
    catch {
        # If we can't determine, assume false for safety
        return $false
    }
}

function Test-VMEnvironment {
    try {
        # Check common VM indicators
        $manufacturer = (Get-WmiObject -Class Win32_ComputerSystem).Manufacturer
        $model = (Get-WmiObject -Class Win32_ComputerSystem).Model
        
        $vmIndicators = @(
            "VMware", "VirtualBox", "Microsoft Corporation", 
            "QEMU", "Xen", "Parallels", "Virtual Machine"
        )
        
        foreach ($indicator in $vmIndicators) {
            if ($manufacturer -match $indicator -or $model -match $indicator) {
                return $true
            }
        }
        
        return $false
    }
    catch {
        return $false
    }
}

function Test-WSLInstalled {
    try {
        $wslVersion = wsl --version 2>$null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Test-DockerInstalled {
    try {
        $dockerVersion = docker --version 2>$null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Install-WSL2 {
    Write-Output "Installing WSL2..."
    
    # Enable WSL and Virtual Machine Platform features
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    
    # Install WSL2
    wsl --install --no-launch
    
    if ($LASTEXITCODE -eq 0) {
        Write-Output "[SUCCESS] WSL2 installation initiated successfully"
        return $true
    } else {
        Write-Output "[ERROR] Failed to install WSL2"
        return $false
    }
}

function Install-DockerDesktop {
    Write-Output "Installing Docker Desktop..."
    
    # Try winget first (Windows 10 1709+ / Windows 11)
    try {
        winget install Docker.DockerDesktop --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Output "[SUCCESS] Docker Desktop installed via winget"
            return $true
        }
    }
    catch {
        Write-Output "winget not available, trying direct download..."
    }
    
    # Fallback to direct download
    $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"
    
    try {
        Write-Output "Downloading Docker Desktop..."
        Invoke-WebRequest -Uri $dockerUrl -OutFile $dockerInstaller
        
        Write-Output "Running Docker Desktop installer..."
        Start-Process -FilePath $dockerInstaller -ArgumentList "install", "--quiet" -Wait
        
        Remove-Item $dockerInstaller -Force
        Write-Output "[SUCCESS] Docker Desktop installed"
        return $true
    }
    catch {
        Write-Output "[ERROR] Failed to install Docker Desktop: $($_.Exception.Message)"
        return $false
    }
}

function Install-PodiumCLI {
    Write-Output "Installing Podium CLI in WSL2..."
    
    # Check if Ubuntu is the default WSL distro, if not set it
    $distros = wsl -l -q
    if ($distros -notcontains "Ubuntu") {
        Write-Output "Installing Ubuntu..."
        wsl --install -d Ubuntu --no-launch
    }
    
    # Install Podium CLI
    $installCommand = "curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-ubuntu.sh | bash"
    
    try {
        wsl -d Ubuntu -e bash -c $installCommand
        if ($LASTEXITCODE -eq 0) {
            Write-Output "[SUCCESS] Podium CLI installed successfully"
            return $true
        } else {
            Write-Output "[ERROR] Failed to install Podium CLI"
            return $false
        }
    }
    catch {
        Write-Output "[ERROR] Error installing Podium CLI: $($_.Exception.Message)"
        return $false
    }
}

function Test-Installation {
    Write-Output "`nTesting installation..."
    
    # Test WSL2
    if (Test-WSLInstalled) {
        Write-Output "[SUCCESS] WSL2 is working"
    } else {
        Write-Output "[ERROR] WSL2 is not working"
    }
    
    # Test Docker
    if (Test-DockerInstalled) {
        Write-Output "[SUCCESS] Docker is working"
    } else {
        Write-Output "[WARNING] Docker is not working (may need to start Docker Desktop)"
    }
    
    # Test Podium CLI
    try {
        Write-Output "Testing Podium CLI in WSL2..."
        $podiumTest = wsl -d Ubuntu -e bash -c "which podium" 2>$null
        if ($LASTEXITCODE -eq 0) {
            $podiumVersion = wsl -d Ubuntu -e bash -c "podium --version" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Output "[SUCCESS] Podium CLI is working: $podiumVersion"
            } else {
                Write-Output "[WARNING] Podium CLI found but version check failed"
            }
        } else {
            Write-Output "[ERROR] Podium CLI is not installed"
            Write-Output "You can install it manually with:"
            Write-Output "  wsl -d Ubuntu -e bash -c `"curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-ubuntu.sh | bash`""
        }
    }
    catch {
        Write-Output "[ERROR] Cannot test Podium CLI - WSL2 may not be ready"
    }
}

# Check execution policy first
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -eq 'Restricted') {
    Write-Output @"
================================================================
                    EXECUTION POLICY ERROR                    
                                                              
  Your PowerShell execution policy is set to 'Restricted'    
  which prevents this script from running.                   
                                                              
  Please run this command instead:                           
  PowerShell -ExecutionPolicy Bypass -File install-windows.ps1 
                                                              
  Or temporarily change your execution policy:               
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser 
                                                              
================================================================
"@    exit 1
}

# Main installation process
Write-Output @"
================================================================
                    Podium Windows Installer                  
                                                              
  This script will install:                                  
  - WSL2 (Windows Subsystem for Linux)                      
  - Docker Desktop                                          
  - Podium CLI                                              
                                                              
  Execution Policy: $executionPolicy                                
================================================================
"@
# Check virtualization support first
$isVM = Test-VMEnvironment
$hasVirtualization = Test-VirtualizationSupport

if ($isVM -and -not $hasVirtualization) {
    Write-Output @"
================================================================
                    VIRTUALIZATION NOT SUPPORTED                    
                                                              
  You are running in a Virtual Machine without nested virtualization.
  WSL2 and Docker Desktop require hardware virtualization support.
                                                              
  Solutions:                                                    
  1. Enable nested virtualization in your VM settings:
     - VMware: Enable "Virtualize Intel VT-x/EPT or AMD-V/RVI"
     - VirtualBox: Enable "Nested VT-x/AMD-V" in processor settings
     - Hyper-V: Enable nested virtualization via PowerShell
                                                              
  2. Run this installer on a physical Windows machine instead
                                                              
  3. Use alternative development setup without Docker/WSL2
                                                              
================================================================
"@
    Read-Host "Press Enter to exit"
    exit 1
}

if ($isVM) {
    Write-Output @"
================================================================
                    VIRTUAL MACHINE DETECTED                    
                                                              
  Running in VM: This installation may require nested virtualization
  to be enabled in your hypervisor settings.
                                                              
  If installation fails, enable nested virtualization:
  - VMware: VM Settings > Processors > Virtualization Engine
  - VirtualBox: Settings > System > Processor > Enable Nested VT-x
  - Hyper-V: Set-VMProcessor -VMName <name> -ExposeVirtualizationExtensions $true
                                                              
================================================================
"@
    $response = Read-Host "Continue anyway? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Output "Installation cancelled."
        exit 0
    }
}

# Check for admin rights
if (-not (Test-AdminRights)) {
    Write-Output @"
================================================================
                    ADMINISTRATOR REQUIRED                    
                                                              
  This script requires Administrator privileges to:          
  - Install WSL2 Windows features                           
  - Install Docker Desktop                                  
  - Modify system settings                                  
                                                              
  Please:                                                    
  1. Right-click PowerShell and select "Run as Administrator" 
  2. Run this command:                                       
     PowerShell -ExecutionPolicy Bypass -File install-windows.ps1 
                                                              
================================================================
"@    Read-Host "Press Enter to exit"
    exit 1
}

$needsReboot = $false

# Check and install WSL2
if (Test-WSLInstalled) {
    Write-Output "[SUCCESS] WSL2 is already installed"} else {
    if (Install-WSL2) {
        $needsReboot = $true
    } else {
        Write-Output "Failed to install WSL2. Exiting."        exit 1
    }
}

# Check and install Docker Desktop
if (Test-DockerInstalled) {
    Write-Output "[SUCCESS] Docker Desktop is already installed"} else {
    if (-not (Install-DockerDesktop)) {
        Write-Output "Failed to install Docker Desktop. Exiting."        exit 1
    }
}

# Handle reboot requirement
if ($needsReboot -and -not $SkipReboot) {
    Write-Output "`n"    Write-Output "================================================================"    Write-Output "                    REBOOT REQUIRED                          "    Write-Output "                                                              "    Write-Output "  WSL2 installation requires a system reboot.               "    Write-Output "                                                              "    Write-Output "  After reboot, run this script again to complete setup:    "    Write-Output "  PowerShell -ExecutionPolicy Bypass -File install-windows.ps1 "    Write-Output "                                                              "    Write-Output "================================================================"    
    $response = Read-Host "`nReboot now? (y/N)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        Write-Output "Rebooting in 10 seconds..."        Start-Sleep -Seconds 10
        Restart-Computer -Force
    } else {
        Write-Output "Please reboot manually and run this script again."        exit 0
    }
}

# Install Podium CLI (only if no reboot needed or after reboot)
if (-not $needsReboot) {
    if (-not (Install-PodiumCLI)) {
        Write-Output "Warning: Podium CLI installation failed, but you can install it manually later."    }
    
    # Test everything
    Test-Installation
    
    Write-Output "`n"    Write-Output "================================================================"    Write-Output "                    INSTALLATION COMPLETE                     "    Write-Output "                                                              "    Write-Output "  Next steps:                                                "    Write-Output "  1. Start Docker Desktop                                   "    Write-Output "  2. Open WSL2: wsl                                         "    Write-Output "  3. Run: podium new myproject                              "    Write-Output "                                                              "    Write-Output "  Need help? Visit: https://podiumdev.io                    "    Write-Output "  Email: canebaycomputers@gmail.com                         "    Write-Output "================================================================"}
