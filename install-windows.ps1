# Podium Windows Installation Script
# This script sets up WSL2, Docker Desktop, and Podium CLI on Windows

param(
    [switch]$SkipReboot
)

# Colors for output
$RED = "Red"
$GREEN = "Green" 
$YELLOW = "Yellow"
$CYAN = "Cyan"
$BLUE = "Blue"

function Write-ColorOutput($Message, $Color = "White") {
    Write-Host $Message -ForegroundColor $Color
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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
    Write-ColorOutput "Installing WSL2..." $CYAN
    
    # Enable WSL and Virtual Machine Platform features
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    
    # Install WSL2
    wsl --install --no-launch
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "[SUCCESS] WSL2 installation initiated successfully" $GREEN
        return $true
    } else {
        Write-ColorOutput "[ERROR] Failed to install WSL2" $RED
        return $false
    }
}

function Install-DockerDesktop {
    Write-ColorOutput "Installing Docker Desktop..." $CYAN
    
    # Try winget first (Windows 10 1709+ / Windows 11)
    try {
        winget install Docker.DockerDesktop --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "[SUCCESS] Docker Desktop installed via winget" $GREEN
            return $true
        }
    }
    catch {
        Write-ColorOutput "winget not available, trying direct download..." $YELLOW
    }
    
    # Fallback to direct download
    $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"
    
    try {
        Write-ColorOutput "Downloading Docker Desktop..." $CYAN
        Invoke-WebRequest -Uri $dockerUrl -OutFile $dockerInstaller
        
        Write-ColorOutput "Running Docker Desktop installer..." $CYAN
        Start-Process -FilePath $dockerInstaller -ArgumentList "install", "--quiet" -Wait
        
        Remove-Item $dockerInstaller -Force
        Write-ColorOutput "[SUCCESS] Docker Desktop installed" $GREEN
        return $true
    }
    catch {
        Write-ColorOutput "[ERROR] Failed to install Docker Desktop: $($_.Exception.Message)" $RED
        return $false
    }
}

function Install-PodiumCLI {
    Write-ColorOutput "Installing Podium CLI in WSL2..." $CYAN
    
    # Check if Ubuntu is the default WSL distro, if not set it
    $distros = wsl -l -q
    if ($distros -notcontains "Ubuntu") {
        Write-ColorOutput "Installing Ubuntu..." $CYAN
        wsl --install -d Ubuntu --no-launch
    }
    
    # Install Podium CLI
    $installCommand = "curl -fsSL https://raw.githubusercontent.com/CaneBayComputers/podium-cli/master/install-ubuntu.sh | bash"
    
    try {
        wsl -d Ubuntu -e bash -c $installCommand
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "[SUCCESS] Podium CLI installed successfully" $GREEN
            return $true
        } else {
            Write-ColorOutput "[ERROR] Failed to install Podium CLI" $RED
            return $false
        }
    }
    catch {
        Write-ColorOutput "[ERROR] Error installing Podium CLI: $($_.Exception.Message)" $RED
        return $false
    }
}

function Test-Installation {
    Write-ColorOutput "`nTesting installation..." $CYAN
    
    # Test WSL2
    if (Test-WSLInstalled) {
        Write-ColorOutput "[SUCCESS] WSL2 is working" $GREEN
    } else {
        Write-ColorOutput "[ERROR] WSL2 is not working" $RED
    }
    
    # Test Docker
    if (Test-DockerInstalled) {
        Write-ColorOutput "[SUCCESS] Docker is working" $GREEN
    } else {
        Write-ColorOutput "[WARNING] Docker is not working (may need to start Docker Desktop)" $YELLOW
    }
    
    # Test Podium CLI
    try {
        $podiumVersion = wsl -e podium --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "[SUCCESS] Podium CLI is working: $podiumVersion" $GREEN
        } else {
            Write-ColorOutput "[ERROR] Podium CLI is not working" $RED
        }
    }
    catch {
        Write-ColorOutput "[ERROR] Cannot test Podium CLI" $RED
    }
}

# Check execution policy first
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -eq 'Restricted') {
    Write-ColorOutput @"
╔══════════════════════════════════════════════════════════════╗
║                    EXECUTION POLICY ERROR                    ║
║                                                              ║
║  Your PowerShell execution policy is set to 'Restricted'    ║
║  which prevents this script from running.                   ║
║                                                              ║
║  Please run this command instead:                           ║
║  PowerShell -ExecutionPolicy Bypass -File install-windows.ps1 ║
║                                                              ║
║  Or temporarily change your execution policy:               ║
║  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"@ $RED
    exit 1
}

# Main installation process
Write-ColorOutput @"
╔══════════════════════════════════════════════════════════════╗
║                    Podium Windows Installer                  ║
║                                                              ║
║  This script will install:                                  ║
║  • WSL2 (Windows Subsystem for Linux)                      ║
║  • Docker Desktop                                          ║
║  • Podium CLI                                              ║
║                                                              ║
║  Execution Policy: $executionPolicy                                ║
╚══════════════════════════════════════════════════════════════╝
"@ $BLUE

# Check for admin rights
if (-not (Test-AdminRights)) {
    Write-ColorOutput @"
╔══════════════════════════════════════════════════════════════╗
║                    ADMINISTRATOR REQUIRED                    ║
║                                                              ║
║  This script requires Administrator privileges to:          ║
║  • Install WSL2 Windows features                           ║
║  • Install Docker Desktop                                  ║
║  • Modify system settings                                  ║
║                                                              ║
║  Please:                                                    ║
║  1. Right-click PowerShell and select "Run as Administrator" ║
║  2. Run this command:                                       ║
║     PowerShell -ExecutionPolicy Bypass -File install-windows.ps1 ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"@ $RED
    Read-Host "Press Enter to exit"
    exit 1
}

$needsReboot = $false

# Check and install WSL2
if (Test-WSLInstalled) {
    Write-ColorOutput "[SUCCESS] WSL2 is already installed" $GREEN
} else {
    if (Install-WSL2) {
        $needsReboot = $true
    } else {
        Write-ColorOutput "Failed to install WSL2. Exiting." $RED
        exit 1
    }
}

# Check and install Docker Desktop
if (Test-DockerInstalled) {
    Write-ColorOutput "[SUCCESS] Docker Desktop is already installed" $GREEN
} else {
    if (-not (Install-DockerDesktop)) {
        Write-ColorOutput "Failed to install Docker Desktop. Exiting." $RED
        exit 1
    }
}

# Handle reboot requirement
if ($needsReboot -and -not $SkipReboot) {
    Write-ColorOutput "`n" $WHITE
    Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" $YELLOW
    Write-ColorOutput "║                    REBOOT REQUIRED                          ║" $YELLOW
    Write-ColorOutput "║                                                              ║" $YELLOW
    Write-ColorOutput "║  WSL2 installation requires a system reboot.               ║" $YELLOW
    Write-ColorOutput "║                                                              ║" $YELLOW
    Write-ColorOutput "║  After reboot, run this script again to complete setup:    ║" $YELLOW
    Write-ColorOutput "║  PowerShell -ExecutionPolicy Bypass -File install-windows.ps1 ║" $YELLOW
    Write-ColorOutput "║                                                              ║" $YELLOW
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" $YELLOW
    
    $response = Read-Host "`nReboot now? (y/N)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        Write-ColorOutput "Rebooting in 10 seconds..." $CYAN
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    } else {
        Write-ColorOutput "Please reboot manually and run this script again." $YELLOW
        exit 0
    }
}

# Install Podium CLI (only if no reboot needed or after reboot)
if (-not $needsReboot) {
    if (-not (Install-PodiumCLI)) {
        Write-ColorOutput "Warning: Podium CLI installation failed, but you can install it manually later." $YELLOW
    }
    
    # Test everything
    Test-Installation
    
    Write-ColorOutput "`n" $WHITE
    Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" $GREEN
    Write-ColorOutput "║                    INSTALLATION COMPLETE                     ║" $GREEN
    Write-ColorOutput "║                                                              ║" $GREEN
    Write-ColorOutput "║  Next steps:                                                ║" $GREEN
    Write-ColorOutput "║  1. Start Docker Desktop                                   ║" $GREEN
    Write-ColorOutput "║  2. Open WSL2: wsl                                         ║" $GREEN
    Write-ColorOutput "║  3. Run: podium new myproject                              ║" $GREEN
    Write-ColorOutput "║                                                              ║" $GREEN
    Write-ColorOutput "║  Need help? Visit: https://podiumdev.io                    ║" $GREEN
    Write-ColorOutput "║  Email: canebaycomputers@gmail.com                         ║" $GREEN
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" $GREEN
}
