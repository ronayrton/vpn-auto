<#
.SYNOPSIS
    Script completo: desinstala, limpa e instala FortiClient VPN

.DESCRIPTION
    Faz clean install do FortiClient + configura VPN

.NOTES
    Autor: Equipe de Suporte
    Versão: 5.0.0
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

function Uninstall-FortiClient {
    Write-Log "1. Parando processos..."
    Get-Process FortiClient*,FortiTray,FortiSSLVPN* -ErrorAction SilentlyContinue | Stop-Process -Force
    
    Write-Log "2. Desinstalando FortiClient..."
    $uninstall = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*FortiClient*" }
    if ($uninstall) {
        $uninstall.Uninstall() | Out-Null
        Write-Log "Desinstalado" -Level "SUCCESS"
    }
    
    Write-Log "3. Removendo residuos..."
    $progPath = "${env:ProgramFiles}\Fortinet\FortiClient"
    if (Test-Path $progPath) { Remove-Item $progPath -Recurse -Force }
    
    $progPath86 = "${env:ProgramFiles(x86)}\Fortinet\FortiClient"
    if (Test-Path $progPath86) { Remove-Item $progPath86 -Recurse -Force }
    
    Write-Log "4. Limpando configuracoes..."
    Remove-Item "$env:APPDATA\FortiClient" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\FortiClient" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\ProgramData\Fortinet" -Recurse -Force -ErrorAction SilentlyContinue
    
    Remove-Item "HKLM:\SOFTWARE\Fortinet" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "HKCU:\SOFTWARE\Fortinet" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Log "Desinstalacao completa" -Level "SUCCESS"
}

function Install-FortiClient {
    Write-Log "5. Baixando FortiClient..."
    $tempPath = Join-Path $env:TEMP "FortiClientVPNSetup.exe"
    $url = "https://github.com/ronayrton/vpn-auto/releases/download/v1.0.0/vpntjrn.exe"
    Invoke-RestMethod -Uri $url -OutFile $tempPath -TimeoutSec 120
    $size = (Get-Item $tempPath).Length / 1MB
    Write-Log "Download: $([math]::Round($size, 1)) MB" -Level "SUCCESS"
    
    Write-Log "6. Instalando..."
    Start-Process -FilePath $tempPath -ArgumentList "/quiet /norestart" -WindowStyle Hidden -Wait
    Write-Log "Instalacao concluida" -Level "SUCCESS"
}

function Configure-VPN {
    Write-Log "7. Configurando VPN..."
    
    Start-Sleep -Seconds 3
    
    $vpnPath = Join-Path $env:APPDATA "FortiClient\Vpn\Connections"
    if (-not (Test-Path $vpnPath)) { New-Item -ItemType Directory -Path $vpnPath -Force | Out-Null }
    
    $configFile = Join-Path $vpnPath "$ConnectionName.conn"
    
    $xmlContent = '<?xml version="1.0" encoding="UTF-8" ?><FortiClientVPNProfile><Name>' + $ConnectionName + '</Name><Type>ssl</Type><RemoteGateway>' + $Gateway + '</RemoteGateway><Port>' + $Port + '</Port><Username>' + $Username + '</Username><AuthMethod>0</AuthMethod><SavePassword>true</SavePassword><DefaultGateway>true</DefaultGateway><SplitTunneling>true</SplitTunneling><Theme>0</Theme><ShowPassword>false</ShowPassword><Connected>false</Connected></FortiClientVPNProfile>'
    
    $xmlContent | Out-File -FilePath $configFile -Encoding UTF8 -Force
    Write-Log "VPN configurada: $configFile" -Level "SUCCESS"
}

Write-Log "========================================" -Level "INFO"
Write-Log "FortiClient - Clean Install & Configure" -Level "INFO"
Write-Log "========================================" -Level "INFO"

if (-not $Username) { 
    $Username = Read-Host "Digite seu usuario de rede"
}

Write-Log "Usuario: $Username" -Level "INFO"
Write-Log "Conexao: $ConnectionName -> $Gateway`:$Port" -Level "INFO"
Write-Log "========================================" -Level "INFO"

Uninstall-FortiClient
Install-FortiClient
Configure-VPN

Write-Log "========================================" -Level "SUCCESS"
Write-Log "CONCLUIDO!" -Level "SUCCESS"
Write-Log "Reinicie o PC para aplicar a VPN" -Level "WARNING"
Write-Log "========================================" -Level "SUCCESS"