<# 
.SYNOPSIS
    Configura VPN FortiClient

.DESCRIPTION
    Executável que cria configuração e abre FortiClient

.NOTES
    Versão: 1.0
#>

$Username = $args[0]

if (-not $Username) {
    Write-Host "Uso: config-vpn.exe usuario"
    Write-Host "Exemplo: config-vpn.exe l003027"
    $Username = Read-Host "Digite seu usuario de rede"
}

$vpnPath = Join-Path $env:APPDATA "FortiClient\Vpn\Connections"
New-Item -ItemType Directory -Path $vpnPath -Force | Out-Null

$configFile = Join-Path $vpnPath "TJRN.conn"

$xml = @"<?xml version="1.0" encoding="UTF-8" ?><FortiClientVPNProfile><Name>TJRN</Name><Type>ssl</Type><RemoteGateway>vpn.tjrn.jus.br</RemoteGateway><Port>10443</Port><Username>$Username</Username><AuthMethod>0</AuthMethod><SavePassword>true</SavePassword><DefaultGateway>true</DefaultGateway></FortiClientVPNProfile>
"@

$xml | Out-File -FilePath $configFile -Encoding UTF8 -Force

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VPN Configurada!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Arquivo: $configFile"
Write-Host ""
Write-Host "PRESSIONE QUALQUER TECLA PARA ABRIR FORTICLIENT..." -ForegroundColor Yellow
Read-Host

Start-Process "C:\Program Files\Fortinet\FortiClient\FortiClient.exe"

Write-Host ""
Write-Host "AGORA NO FORTICLIENT:" -ForegroundColor Yellow
Write-Host "1. Clique em '+' ou 'Add Connection'" -ForegroundColor White
Write-Host "2. Configure manualmente" -ForegroundColor White
Write-Host "3. Clique em Salvar" -ForegroundColor White
Write-Host ""
Write-Host "Pressione ENTER para sair..."
Read-Host