<#
.SYNOPSIS
    Instala e configura FortiClient VPN

.DESCRIPTION
    Script completo: baixa, instala e cria configuração VPN
#>

$Username = $args[0]

if (-not $Username) {
    $Username = Read-Host "Digite seu usuario de rede"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "========================================"
Write-Host "FortiClient VPN - Install & Configure"
Write-Host "========================================"

# 1. Baixar e instalar
Write-Host "[1] Baixando FortiClient..."
$tempPath = Join-Path $env:TEMP "FortiClientVPNSetup.exe"
$url = "https://github.com/ronayrton/vpn-auto/releases/download/v2.0.0/FortiClientVPN7.0.exe"

try {
    Invoke-RestMethod -Uri $url -OutFile $tempPath -TimeoutSec 120
    $size = (Get-Item $tempPath).Length / 1MB
    Write-Host "Download: $([math]::Round($size, 1)) MB"
    
    Write-Host "[2] Instalando..."
    Start-Process -FilePath $tempPath -ArgumentList "/quiet /norestart" -WindowStyle Hidden -Wait
    Write-Host "Instalacao concluida"
}
catch {
    Write-Host "Erro no download/instalacao: $($_.Exception.Message)"
}

# 2. Criar config
Write-Host "[3] Criando configuracao VPN..."
$vpnPath = Join-Path $env:APPDATA "FortiClient\Vpn\Connections"
New-Item -ItemType Directory -Path $vpnPath -Force | Out-Null

$configFile = Join-Path $vpnPath "TJRN.conn"
$xml = '<?xml version="1.0" encoding="UTF-8" ?><FortiClientVPNProfile><Name>TJRN</Name><Type>ssl</Type><RemoteGateway>vpn.tjrn.jus.br</RemoteGateway><Port>10443</Port><Username>' + $Username + '</Username><AuthMethod>0</AuthMethod><SavePassword>true</SavePassword><DefaultGateway>true</DefaultGateway></FortiClientVPNProfile>'

$xml | Out-File -FilePath $configFile -Encoding UTF8 -Force

Write-Host "Configuracao salva: $configFile"

# 3. Abrir FortiClient
Write-Host "[4] Abrindo FortiClient..."
Start-Process "C:\Program Files\Fortinet\FortiClient\FortiClient.exe"

Write-Host ""
Write-Host "========================================"
Write-Host "CONCLUIDO!"
Write-Host "========================================"
Write-Host "No FortiClient:"
Write-Host "1. Procure por TJRN"
Write-Host "2. Se nao aparecer, clique em +"
Write-Host "3. Configure manualmente"
Write-Host "4. Conecte!"
Write-Host ""
Read-Host