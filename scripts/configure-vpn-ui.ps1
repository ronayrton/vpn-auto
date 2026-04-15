<#
.SYNOPSIS
    Script de configuração de VPN via UI Automation

.DESCRIPTION
    Abre FortiClient e configura a VPN automaticamente via interface gráfica

.NOTES
    Autor: Equipe de Suporte
    Versão: 1.0.0
#>

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$Username = Read-Host "Digite seu usuario de rede"

function Get-UIAutomationElement {
    param($Parent, $ControlType, $Name, $Timeout = 10)
    
    $condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, $ControlType)
    $nameCondition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $Name)
    $andCondition = New-Object System.Windows.Automation.AndCondition(@($condition, $nameCondition))
    
    $start = Get-Date
    while ((Get-Date) -lt $start.AddSeconds($Timeout)) {
        $element = $Parent.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $andCondition)
        if ($element) { return $element }
        Start-Sleep -Milliseconds 500
    }
    return $null
}

Write-Log "Iniciando configuracao via UI..." -Level "INFO"

# Abrir FortiClient
$fortiPath = "C:\Program Files\Fortinet\FortiClient\FortiClient.exe"
if (-not (Test-Path $fortiPath)) {
    Write-Log "FortiClient nao encontrado!" -Level "ERROR"
    exit 1
}

$fortiProcess = Start-Process $fortiPath -PassThru
Start-Sleep -Seconds 5

try {
    $uiAuto = [System.Windows.Automation.AutomationElement]::RootElement
    
    # Procurar janela principal
    $mainWindow = Get-UIAutomationElement -Parent $uiAuto -ControlType "Window" -Name "FortiClient" -Timeout 15
    
    if (-not $mainWindow) {
        Write-Log "Janela do FortiClient nao encontrada. Tentando metodo alternativo..." -Level "WARNING"
        
        # Tentar via clicks de координат - tela inicial do FortiClient
        # Isso é mais difícil de fazer sem saber a posição exata
        
        Write-Log "Abrindo formulario de conexao..." -Level "INFO"
        
        # Matar e reiniciar com параметр
        $fortiProcess.Kill()
        Start-Sleep -Seconds 2
        
        # Abrir FortiClient em modo de config
        Start-Process $fortiPath -ArgumentList "--vpn" -PassThru
        Start-Sleep -Seconds 5
    }
    
    # Se não conseguir via UI, criar arquivo de backup
    Write-Log "Criando arquivo de config..." -Level "INFO"
    
    $vpnPath = Join-Path $env:APPDATA "FortiClient\Vpn\Connections"
    if (-not (Test-Path $vpnPath)) { New-Item -ItemType Directory -Path $vpnPath -Force | Out-Null }
    
    $configFile = Join-Path $vpnPath "TJRN.conn"
    
    $xmlContent = '<?xml version="1.0" encoding="UTF-8" ?><FortiClientVPNProfile><Name>TJRN</Name><Type>ssl</Type><RemoteGateway>vpn.tjrn.jus.br</RemoteGateway><Port>10443</Port><Username>' + $Username + '</Username><AuthMethod>0</AuthMethod><SavePassword>true</SavePassword><DefaultGateway>true</DefaultGateway></FortiClientVPNProfile>'
    
    $xmlContent | Out-File -FilePath $configFile -Encoding UTF8 -Force
    
    Write-Log "Configuracao salva em: $configFile" -Level "SUCCESS"
    Write-Log "Abra o FortiClient e configure manualmente." -Level "WARNING"
    
}
catch {
    Write-Log "Erro: $($_.Exception.Message)" -Level "ERROR"
}
finally {
    # Manter FortiClient aberto
}