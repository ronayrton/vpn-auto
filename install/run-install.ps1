<#
.SYNOPSIS
    Script de instalação remota do FortiClient VPN

.DESCRIPTION
    Executa o script principal diretamente de uma URL remota.
    Suporta execução via Assistência Rápida do Windows.

.PARAMETER Url
    URL alternativa para o script (opcional)

.EXAMPLE
    # Execução padrão
    iex (iwr "https://raw.githubusercontent.com/SEU_USUARIO/assyst-vpn-automation/main/scripts/install-forticlient.ps1")

.EXAMPLE
    # Execução com URL customizada
    .\run-install.ps1 -ScriptUrl "https://seu-servidor.com/scripts/install-forticlient.ps1"

.NOTES
    Autor: Equipe de Suporte
    Versão: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ScriptUrl = "https://raw.githubusercontent.com/assyst/assyst-vpn-automation/main/scripts/install-forticlient.ps1"
)

$ErrorActionPreference = "Stop"

function Write-LogInfo {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [INFO] $Message" -ForegroundColor Cyan
}

Write-LogInfo "=========================================="
Write-LogInfo "Assyst VPN - Instalação Remota"
Write-LogInfo "=========================================="
Write-LogInfo "Baixando script de instalacao..."
Write-LogInfo "URL: $ScriptUrl"

try {
    $scriptContent = Invoke-WebRequest -Uri $ScriptUrl -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
    
    $tempScript = Join-Path $env:TEMP "install-forticlient-$(Get-Random).ps1"
    
    $scriptContent.Content | Out-File -FilePath $tempScript -Encoding UTF8 -ErrorAction Stop
    
    Write-LogInfo "Script baixado. Executando..."
    
    & $tempScript
    
    Write-LogInfo "Removendo script temporario..."
    Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
    
    Write-LogInfo "Processo concluido."
}
catch {
    Write-Host "[$timestamp] [ERROR] Falha: $($_.Exception.Message)" -ForegroundColor Red
    throw
}