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

function Test-WindowsEdition {
    try {
        $edition = (Get-WmiObject -Class Win32_OperatingSystem).Caption
        $isHome = $edition -match "Home"
        $isPro = $edition -match "Pro|Enterprise|Education"
        
        return @{
            Edition = $edition
            IsHome = $isHome
            IsPro = $isPro
            SupportsHyperV = $isPro
        }
    }
    catch {
        return @{
            Edition = "Unknown"
            IsHome = $false
            IsPro = $false
            SupportsHyperV = $false
        }
    }
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
    # First check for Docker Desktop (Windows)
    try {
        $dockerVersion = docker --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
    }
    catch {}
    
    # Check for Docker in WSL
    try {
        $wslDockerVersion = wsl -e docker --version 2>$null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Install-WSL {
    param(
        [bool]$UseWSL2 = $true
    )
    
    if ($UseWSL2) {
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
            Write-Output "[WARNING] WSL2 installation failed, falling back to WSL1..."
            return Install-WSL -UseWSL2 $false
        }
    } else {
        Write-Output "Installing WSL1..."
        
        # Enable only WSL feature (no Virtual Machine Platform needed)
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
        
        if ($LASTEXITCODE -eq 0) {
            Write-Output "[SUCCESS] WSL1 feature enabled successfully"
            Write-Output "[INFO] A reboot is required to complete WSL1 installation"
            return $true
        } else {
            Write-Output "[ERROR] Failed to enable WSL1 feature"
            return $false
        }
    }
}

function Install-Docker {
    param(
        [bool]$UseDockerDesktop = $true,
        [bool]$IsVM = $false,
        [bool]$IsWindowsHome = $false
    )
    
    # Determine Docker installation strategy
    if ($IsWindowsHome -and $IsVM) {
        Write-Output "Windows Home + VM detected: Installing Docker inside WSL (more reliable)"
        return Install-DockerInWSL
    } elseif (-not $UseDockerDesktop) {
        Write-Output "Installing Docker inside WSL..."
        return Install-DockerInWSL
    } else {
        Write-Output "Installing Docker Desktop..."
        return Install-DockerDesktop
    }
}

function Install-DockerDesktop {
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

function Install-DockerInWSL {
    Write-Output "Installing Docker inside WSL Ubuntu..."
    
    # Check if Ubuntu is available
    $distros = wsl -l -q 2>$null
    if (-not $distros -or $distros -notcontains "Ubuntu") {
        Write-Output "[WARNING] Ubuntu WSL distribution not found. Installing Ubuntu..."
        
        # Install Ubuntu distribution
        wsl --set-default-version 1
        wsl --install -d Ubuntu --no-launch
        
        if ($LASTEXITCODE -ne 0) {
            Write-Output "[ERROR] Failed to install Ubuntu distribution"
            return $false
        }
        
        Write-Output "[SUCCESS] Ubuntu distribution installed"
        Write-Output "[INFO] Launching Ubuntu for initial user setup..."
        Write-Output "[INFO] Please complete Ubuntu setup (username/password) then close Ubuntu"
        Write-Output "[INFO] The installer will continue automatically after Ubuntu setup"
        
        # Launch Ubuntu for initial setup
        Start-Process -FilePath "wsl" -ArgumentList "-d", "Ubuntu" -Wait
        
        Write-Output "[INFO] Ubuntu setup completed, continuing with Docker installation..."
    }
    
    # Install Docker in WSL
    $dockerInstallScript = @"
# Update package list
sudo apt-get update

# Install Docker dependencies
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=`$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu `$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker `$USER

# Start Docker service
sudo service docker start

# Enable Docker to start on boot
echo 'sudo service docker start' >> ~/.bashrc

echo "[SUCCESS] Docker installed in WSL"
"@
    
    try {
        # Write script to temp file and execute
        $scriptPath = "/tmp/install-docker.sh"
        $dockerInstallScript | wsl -d Ubuntu -e bash -c "cat > $scriptPath && chmod +x $scriptPath && bash $scriptPath"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Output "[SUCCESS] Docker installed inside WSL Ubuntu"
            Write-Output "[INFO] Docker will start automatically when you open WSL"
            return $true
        } else {
            Write-Output "[ERROR] Failed to install Docker in WSL"
            return $false
        }
    }
    catch {
        Write-Output "[ERROR] Error installing Docker in WSL: $($_.Exception.Message)"
        return $false
    }
}

function Install-PodiumCLI {
    param(
        [bool]$UseWSL2 = $true
    )
    
    $wslVersion = if ($UseWSL2) { "WSL2" } else { "WSL1" }
    Write-Output "Installing Podium CLI in $wslVersion..."
    
    # Set the appropriate WSL version
    if (-not $UseWSL2) {
        wsl --set-default-version 1
    }
    
    # Check if Ubuntu is installed, if not install it
    $distros = wsl -l -q 2>$null
    if (-not $distros -or $distros -notcontains "Ubuntu") {
        Write-Output "Installing Ubuntu distribution..."
        
        if ($UseWSL2) {
            # Try WSL2 installation
            wsl --install -d Ubuntu --no-launch
            if ($LASTEXITCODE -ne 0) {
                Write-Output "[WARNING] WSL2 Ubuntu installation failed, trying WSL1..."
                wsl --set-default-version 1
                wsl --install -d Ubuntu --no-launch
            }
        } else {
            # Install with WSL1
            wsl --install -d Ubuntu --no-launch
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Output "[ERROR] Failed to install Ubuntu distribution"
            return $false
        }
        
        # Wait a moment for installation to complete
        Start-Sleep -Seconds 3
    }
    
    # Install Podium CLI
    $installCommand = "curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-ubuntu.sh | bash"
    
    Write-Output "Installing Podium CLI..."
    try {
        # First ensure Ubuntu is ready
        $ubuntuReady = wsl -d Ubuntu -e bash -c "echo 'Ubuntu Ready'" 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Output "[ERROR] Ubuntu distribution is not ready. You may need to complete Ubuntu setup manually."
            Write-Output "Run: wsl -d Ubuntu"
            Write-Output "Then run: curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-ubuntu.sh | bash"
            return $false
        }
        
        # Install Podium CLI
        wsl -d Ubuntu -e bash -c $installCommand
        if ($LASTEXITCODE -eq 0) {
            Write-Output "[SUCCESS] Podium CLI installed successfully"
            return $true
        } else {
            Write-Output "[ERROR] Failed to install Podium CLI"
            Write-Output "Manual installation command:"
            Write-Output "  wsl -d Ubuntu -e bash -c `"$installCommand`""
            return $false
        }
    }
    catch {
        Write-Output "[ERROR] Error installing Podium CLI: $($_.Exception.Message)"
        Write-Output "Manual installation command:"
        Write-Output "  wsl -d Ubuntu -e bash -c `"$installCommand`""
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
        # Check if it's Docker Desktop or Docker in WSL
        try {
            $dockerVersion = docker --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Output "[SUCCESS] Docker Desktop is working"
            } else {
                $wslDockerVersion = wsl -e docker --version 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Output "[SUCCESS] Docker in WSL is working"
                }
            }
        }
        catch {
            Write-Output "[SUCCESS] Docker is installed (version check failed)"
        }
    } else {
        Write-Output "[WARNING] Docker is not working"
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
# Check system environment and Windows edition
$isVM = Test-VMEnvironment
$windowsInfo = Test-WindowsEdition
$hasVirtualization = Test-VirtualizationSupport

Write-Output "Detected: $($windowsInfo.Edition)"

# Determine WSL version strategy
$useWSL2 = $true
$wslStrategy = "WSL2 (recommended)"

if ($windowsInfo.IsHome) {
    if ($isVM) {
        # Windows Home in VM - use WSL1
        $useWSL2 = $false
        $wslStrategy = "WSL1 (Windows Home + VM compatibility)"
        Write-Output @"
================================================================
                    WINDOWS HOME + VM DETECTED                    
                                                              
  Windows Home Edition in Virtual Machine detected.
  Using WSL1 for maximum compatibility.
                                                              
  WSL1 Benefits:
  - No Hyper-V requirements (perfect for Home edition)
  - Works reliably in VMs without nested virtualization
  - Full Docker Desktop support
  - All Podium CLI features work perfectly
                                                              
  Strategy: $wslStrategy
================================================================
"@
    } else {
        # Windows Home on real hardware - try WSL2, fallback to WSL1
        Write-Output @"
================================================================
                    WINDOWS HOME EDITION DETECTED                    
                                                              
  Windows Home Edition detected on physical hardware.
  Will attempt WSL2, with automatic fallback to WSL1 if needed.
                                                              
  Note: WSL2 may require enabling virtualization in BIOS.
  If WSL2 fails, we'll automatically use WSL1 (fully compatible).
                                                              
  Strategy: $wslStrategy with WSL1 fallback
================================================================
"@
    }
} else {
    # Windows Pro/Enterprise - full WSL2 support
    if ($isVM -and -not $hasVirtualization) {
        Write-Output @"
================================================================
                    NESTED VIRTUALIZATION REQUIRED                    
                                                              
  Windows Pro/Enterprise in VM without nested virtualization.
  WSL2 requires nested virtualization to be enabled.
                                                              
  Enable nested virtualization in your VM settings:
  - VMware: Enable "Virtualize Intel VT-x/EPT or AMD-V/RVI"
  - VirtualBox: Enable "Nested VT-x/AMD-V" in processor settings
  - Hyper-V: Set-VMProcessor -VMName <name> -ExposeVirtualizationExtensions $true
                                                              
  Or we can use WSL1 instead (fully functional).
================================================================
"@
        $response = Read-Host "Use WSL1 instead? (Y/n)"
        if ($response -ne 'n' -and $response -ne 'N') {
            $useWSL2 = $false
            $wslStrategy = "WSL1 (VM compatibility mode)"
        } else {
            Write-Output "Please enable nested virtualization and run installer again."
            exit 1
        }
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

# Check and install WSL
if (Test-WSLInstalled) {
    Write-Output "[SUCCESS] WSL is already installed"
} else {
    if (Install-WSL -UseWSL2 $useWSL2) {
        $needsReboot = $true
    } else {
        Write-Output "Failed to install WSL. Exiting."
        exit 1
    }
}

# Check and install Docker (except for Windows Home + VM, handled after reboot)
if (Test-DockerInstalled) {
    Write-Output "[SUCCESS] Docker is already installed"
} elseif (-not ($windowsInfo.IsHome -and $isVM)) {
    # Install Docker Desktop for non-VM or non-Home environments
    if (-not (Install-DockerDesktop)) {
        Write-Output "Failed to install Docker Desktop. Exiting."
        exit 1
    }
}

# Handle reboot requirement
if ($needsReboot -and -not $SkipReboot) {
    Write-Output "`n"
    Write-Output "================================================================"
    Write-Output "                    REBOOT REQUIRED                          "
    Write-Output "                                                              "
    Write-Output "  WSL installation requires a system reboot.               "
    Write-Output "                                                              "
    Write-Output "  After reboot, run this script again to complete setup:    "
    Write-Output "  PowerShell -ExecutionPolicy Bypass -File install-windows.ps1 "
    Write-Output "                                                              "
    Write-Output "================================================================"    
    $response = Read-Host "`nReboot now? (y/N)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        Write-Output "Rebooting in 10 seconds..."
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    } else {
        Write-Output "Please reboot manually and run this script again."
        exit 0
    }
}

# Install Ubuntu, Docker, and Podium CLI (only if no reboot needed or after reboot)
if (-not $needsReboot) {
    # For WSL1 + Windows Home + VM, we need to install Ubuntu and Docker after WSL is ready
    if ($windowsInfo.IsHome -and $isVM -and -not $useWSL2) {
        Write-Output "Installing Ubuntu distribution for WSL1..."
        wsl --set-default-version 1
        wsl --install -d Ubuntu --no-launch
        
        if ($LASTEXITCODE -ne 0) {
            Write-Output "[ERROR] Failed to install Ubuntu distribution"
            Write-Output "Manual installation: wsl --install -d Ubuntu"
            exit 1
        }
        
        Write-Output "[SUCCESS] Ubuntu distribution installed"
        
        # Now install Docker in WSL
        if (-not (Install-DockerInWSL)) {
            Write-Output "Warning: Docker installation failed, but you can install it manually later."
            Write-Output "Manual installation: Run 'wsl -d Ubuntu' then install Docker manually"
        }
    }
    
    # Install Podium CLI
    if (-not (Install-PodiumCLI -UseWSL2 $useWSL2)) {
        Write-Output "Warning: Podium CLI installation failed, but you can install it manually later."
    }
    
    # Test everything
    Test-Installation
    
    Write-Output "`n"
    Write-Output "================================================================"
    Write-Output "                    INSTALLATION COMPLETE                     "
    Write-Output "                                                              "
    Write-Output "  Next steps:                                                "
    Write-Output "  1. Start Docker Desktop                                   "
    Write-Output "  2. Open WSL: wsl                                         "
    Write-Output "  3. Run: podium new myproject                              "
    Write-Output "                                                              "
    Write-Output "  Need help? Visit: https://podiumdev.io                    "
    Write-Output "  Email: canebaycomputers@gmail.com                         "
    Write-Output "================================================================"
}
