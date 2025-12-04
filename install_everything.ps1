<#
.SYNOPSIS
Installs Chocolatey, automation tools, developer tools, productivity apps, and configures OS settings.

.DESCRIPTION
This script installs a full workstation configuration using Chocolatey and Windows capabilities.
It installs Azure tooling, CLI tools, developer environments, productivity applications, and
configures Remote Desktop, Windows Explorer to show hidden files, protected system files, and file 
extensions.

This script is intended for enterprise workstation bootstrapping, automation, lab setup,
or repeatable onboarding.

.AUTHOR
Shannon Eldridge-Kuehn

.VERSION
1.1

.NOTES
Run from an elevated PowerShell session.
Logs stored in C:\Logs\InstallWorkstation.log
#>

# ======================================================
# Logging Setup
# ======================================================

$LogPath = "C:\Logs"
$LogFile = Join-Path $LogPath "InstallWorkstation.log"

If (!(Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

Start-Transcript -Path $LogFile -Append

Write-Host "Starting workstation installation..."

# ======================================================
# Ensure Script Runs as Administrator
# ======================================================
If (-Not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltinRole]::Administrator)) {

    Write-Host "Restarting script as Administrator..."
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Stop-Transcript
    Exit
}

# ======================================================
# Execution Policy
# ======================================================
Write-Host "Setting execution policy..."
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

# ======================================================
# Install Chocolatey
# ======================================================
Write-Host "Installing Chocolatey..."
Set-ExecutionPolicy Bypass -Scope Process -Force
Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# ======================================================
# Install Applications
# ======================================================
$Apps = @(
    "az.powershell",
    "powershell-core",
    "DSC.PSDesiredStateConfiguration",
    "azure-cli",
    "office365business",
    "MicrosoftAzurestorageExplorer",
    "postman",
    "python",
    "kubernetes-cli",
    "kubernetes-helm",
    "terraform",
    "googlechrome",
    "spotify",
    "microsoft-office-deployment",
    "slack",
    "vscode",
    "visualstudio2026enterprise",
    "dotnet-sdk",
    "microsoft-windows-terminal"
)

Write-Host "Installing applications..."
foreach ($App in $Apps) {
    try {
        choco install $App -y
    }
    catch {
        Write-Warning "Failed to install $App. Error: $_"
    }
}

# ======================================================
# Enable Remote Desktop
# ======================================================
Write-Host "Enabling Remote Desktop..."
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" `
    -Name fDenyTSConnections -Value 0

# ======================================================
# Unhide Files, System Files, and Extensions
# ======================================================
Write-Host "Configuring Windows Explorer visibility..."

Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name Hidden -Value 1

Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name ShowSuperHidden -Value 1

Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name HideFileExt -Value 0

Stop-Process -Name explorer -Force
Start-Process explorer.exe

Write-Host "Installation complete."

Stop-Transcript
