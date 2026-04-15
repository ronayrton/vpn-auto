<#
.SYNOPSIS
    Instala, configura e exporta FortiClient VPN

.DESCRIPTION
    Script completo: baixa, instala, cria config e exporta XML
    Se ja estiver instalado, pula para configuração
#>

$Username = $args[0]
$ExportPath = $args[1]

if (-not $Username) {
    $Username = Read-Host "Digite seu usuario de rede"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "========================================"
Write-Host "FortiClient VPN - Install & Configure"
Write-Host "========================================"

# Verificar se ja esta instalado
$fortiPath = "C:\Program Files\Fortinet\FortiClient\FortiClient.exe"
$jaInstalado = Test-Path $fortiPath

if ($jaInstalado) {
    Write-Host "[STATUS] FortiClient ja instalado - pulando instalacao"
} else {
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
}

# 2. Criar config
Write-Host "[3] Criando configuracao VPN..."
$vpnPath = Join-Path $env:APPDATA "FortiClient\Vpn\Connections"
New-Item -ItemType Directory -Path $vpnPath -Force | Out-Null

$configFile = Join-Path $vpnPath "TJRN.conn"
$xml = '<?xml version="1.0" encoding="UTF-8" ?><FortiClientVPNProfile><Name>TJRN</Name><Type>ssl</Type><RemoteGateway>vpn.tjrn.jus.br</RemoteGateway><Port>10443</Port><Username>' + $Username + '</Username><AuthMethod>0</AuthMethod><SavePassword>true</SavePassword><DefaultGateway>true</DefaultGateway></FortiClientVPNProfile>'

$xml | Out-File -FilePath $configFile -Encoding UTF8 -Force

Write-Host "Configuracao salva: $configFile"

# 3. Exportar XML se solicitado
if ($ExportPath) {
    $exportFile = Join-Path $ExportPath "TJRN-vpn-config.xml"
    $xml | Out-File -FilePath $exportFile -Encoding UTF8 -Force
    Write-Host "XML exportado: $exportFile"
}

# 4. Abrir FortiClient
Write-Host "[4] Abrindo FortiClient..."
Start-Process $fortiPath

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