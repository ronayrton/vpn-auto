<#
.SYNOPSIS
    Script completo: instala e configura FortiClient VPN

.DESCRIPTION
    Instala o FortiClient e configura a conexão VPN automaticamente.

.NOTES
    Autor: Equipe de Suporte
    Versão: 3.0.0
#>

if ($args.Count -gt 0) { $Username = $args[0] }

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Stop"

$ConnectionName = "TJRN"
$Gateway = "vpn.tjrn.jus.br"
$Port = 10443

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colors = @{"INFO"="Cyan";"SUCCESS"="Green";"WARNING"="Yellow";"ERROR"="Red"}
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

function Test-IsInstalled {
    $app = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*FortiClient*" }
    if ($app) { return $true }
    $reg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -like "*FortiClient*" }
    return ($null -ne $reg)
}

function Install-FortiClient {
    Write-Log "Baixando FortiClient..."
    $tempPath = Join-Path $env:TEMP "FortiClientVPNSetup.exe"
    $url = "https://github.com/ronayrton/vpn-auto/releases/download/v1.0.0/vpntjrn.exe"
    Invoke-RestMethod -Uri $url -OutFile $tempPath -TimeoutSec 120
    Write-Log "Instalando..."
    Start-Process -FilePath $tempPath -ArgumentList "/quiet /norestart" -WindowStyle Hidden -Wait
    Write-Log "Concluído" -Level "SUCCESS"
}

function Configure-VPN {
    Write-Log "Configurando VPN..."
    
    $vpnPath = Join-Path $env:APPDATA "FortiClient\Vpn\Connections"
    if (-not (Test-Path $vpnPath)) { New-Item -ItemType Directory -Path $vpnPath -Force | Out-Null }
    
    $oldFile = Join-Path $vpnPath "$ConnectionName.fcc"
    if (Test-Path $oldFile) { Remove-Item $oldFile -Force }
    
    $configFile = Join-Path $vpnPath "$ConnectionName.conn"
    
    $config = @"<?xml version="1.0" encoding="UTF-8"?>
<FortiClientVPNProfile>
    <Name>$ConnectionName</Name>
    <Type>ssl</Type>
    <RemoteGateway>$Gateway</RemoteGateway>
    <Port>$Port</Port>
    <Username>$Username</Username>
    <AuthMethod>0</AuthMethod>
    <SavePassword>true</SavePassword>
    <DefaultGateway>true</DefaultGateway>
    <SplitTunneling>true</SplitTunneling>
    <Theme>0</Theme>
    <ShowPassword>false</ShowPassword>
    <Connected>false</Connected>
    <ConnectionWarningDuration>0</ConnectionWarningDuration>
    <LastConnected>0</LastConnected>
    <KeepAlive>0</KeepAlive>
    <IdleTimeout>0</IdleTimeout>
    <DesktopShortcut>false</DesktopShortcut>
    <StartWithWindows>false</StartWithWindows>
    <StartMinimized>false</StartMinimized>
    <DisableTrayIcon>false</DisableTrayIcon>
    <AllowConnectionToMultipleServers>true</AllowConnectionToMultipleServers>
</FortiClientVPNProfile>
"@
    $config | Out-File -FilePath $configFile -Encoding UTF8 -Force
    Write-Log "VPN configurada: $configFile" -Level "SUCCESS"
    
    $fcconfig = "C:\Program Files\Fortinet\FortiClient\FCConfig.exe"
    if (Test-Path $fcconfig) {
        try {
            Write-Log "Importando configuração..."
            & $fcconfig -m vpn -i $configFile 2>$null
        } catch {}
    }
}

Write-Log "========================================" -Level "INFO"
Write-Log "FortiClient VPN - Install & Configure" -Level "INFO"
Write-Log "========================================" -Level "INFO"

if (-not $Username) { 
    $Username = Read-Host "Digite seu usuário de rede (ex: nome.sobrenome)"
}

Write-Log "Usuário: $Username" -Level "INFO"

if (-not (Test-IsInstalled)) { Install-FortiClient } else { Write-Log "Já instalado" -Level "SUCCESS" }

Configure-VPN
Write-Log "Pronto! Abra o FortiClient e conecte." -Level "SUCCESS"