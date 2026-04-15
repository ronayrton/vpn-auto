<# 
.SYNOPSIS
    Configura VPN FortiClient
.DESCRIPTION
    Cria configuração e abre FortiClient
#>

$Username = $args[0]

if (-not $Username) {
    $Username = Read-Host "Digite seu usuario de rede"
}

$vpnPath = Join-Path $env:APPDATA "FortiClient\Vpn\Connections"
New-Item -ItemType Directory -Path $vpnPath -Force | Out-Null

$configFile = Join-Path $vpnPath "TJRN.conn"

$xml = '<?xml version="1.0" encoding="UTF-8" ?><FortiClientVPNProfile><Name>TJRN</Name><Type>ssl</Type><RemoteGateway>vpn.tjrn.jus.br</RemoteGateway><Port>10443</Port><Username>' + $Username + '</Username><AuthMethod>0</AuthMethod><SavePassword>true</SavePassword><DefaultGateway>true</DefaultGateway></FortiClientVPNProfile>'

$xml | Out-File -FilePath $configFile -Encoding UTF8 -Force

Write-Host ""
Write-Host "========================================"
Write-Host "VPN Configurada!"
Write-Host "========================================"
Write-Host "Arquivo: $configFile"
Write-Host ""
Write-Host "Pressione ENTER para abrir FortiClient..."
Read-Host

Start-Process "C:\Program Files\Fortinet\FortiClient\FortiClient.exe"

Write-Host ""
Write-Host "INSTRUCOES:"
Write-Host "1. Procure por TJRN na lista"
Write-Host "2. Se nao aparecer, clique em + para adicionar"
Write-Host "3. Configure manualmente"
Write-Host "4. Clique em Conectar"
Write-Host ""
Read-Host