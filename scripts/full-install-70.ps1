<#
.SYNOPSIS
    Script completo: instala e configura FortiClient VPN 7.0

.DESCRIPTION
    Instala o FortiClient 7.0 e configura a conexão VPN automaticamente.

.NOTES
    Autor: Equipe de Suporte
    Versão: 1.0.0
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
    Write-Log "Baixando FortiClient 7.0..."
    $tempPath = Join-Path $env:TEMP "FortiClientVPNSetup.exe"
    $url = "https://github.com/ronayrton/vpn-auto/releases/download/v2.0.0/FortiClientVPN7.0.exe"
    Invoke-RestMethod -Uri $url -OutFile $tempPath -TimeoutSec 120
    $size = (Get-Item $tempPath).Length / 1MB
    Write-Log "Download: $([math]::Round($size, 1)) MB" -Level "SUCCESS"
    
    Write-Log "Instalando..."
    Start-Process -FilePath $tempPath -ArgumentList "/quiet /norestart" -WindowStyle Hidden -Wait
    Write-Log "Instalacao concluida" -Level "SUCCESS"
}

function Configure-VPN {
    Write-Log "Configurando VPN..."
    
    $vpnPath = Join-Path $env:APPDATA "FortiClient\Vpn\Connections"
    if (-not (Test-Path $vpnPath)) { New-Item -ItemType Directory -Path $vpnPath -Force | Out-Null }
    
    $configFile = Join-Path $vpnPath "$ConnectionName.conn"
    
    $xmlContent = '<?xml version="1.0" encoding="UTF-8" ?><FortiClientVPNProfile><Name>' + $ConnectionName + '</Name><Type>ssl</Type><RemoteGateway>' + $Gateway + '</RemoteGateway><Port>' + $Port + '</Port><Username>' + $Username + '</Username><AuthMethod>0</AuthMethod><SavePassword>true</SavePassword><DefaultGateway>true</DefaultGateway></FortiClientVPNProfile>'
    
    $xmlContent | Out-File -FilePath $configFile -Encoding UTF8 -Force
    Write-Log "VPN configurada em: $configFile" -Level "SUCCESS"
}

Write-Log "========================================" -Level "INFO"
Write-Log "FortiClient 7.0 - Install & Configure" -Level "INFO"
Write-Log "========================================" -Level "INFO"

if (-not $Username) { 
    $Username = Read-Host "Digite seu usuario de rede"
}

Write-Log "Usuario: $Username" -Level "INFO"
Write-Log "Conexao: $ConnectionName -> $Gateway`:$Port" -Level "INFO"
Write-Log "========================================" -Level "INFO"

if (-not (Test-IsInstalled)) { Install-FortiClient } else { Write-Log "Ja instalado" -Level "SUCCESS" }

Configure-VPN

Write-Log "========================================" -Level "SUCCESS"
Write-Log "Pronto! Reinicie o PC e verifique a VPN." -Level "SUCCESS"
Write-Log "========================================" -Level "SUCCESS"