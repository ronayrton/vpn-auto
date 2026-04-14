<#
.SYNOPSIS
    Script completo: instala e configura FortiClient VPN

.DESCRIPTION
    Instala o FortiClient e configura a conexão VPN automaticamente.
    Uso: iex (iwr "URL" -UseBasicParsing) -Username "usuario" -Password "senha"

.PARAMETER Username
    Usuário de autenticação (obrigatório)

.PARAMETER Password
    Senha de autenticação (opcional)

.NOTES
    Autor: Equipe de Suporte
    Versão: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Username,
    [string]$Password
)

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
    
    try {
        Invoke-RestMethod -Uri $url -OutFile $tempPath -TimeoutSec 120
        $fileSize = (Get-Item $tempPath).Length
        Write-Log "Download: $([math]::Round($fileSize / 1MB, 2)) MB" -Level "SUCCESS"
        
        Write-Log "Instalando (silencioso)..."
        Start-Process -FilePath $tempPath -ArgumentList "/quiet /norestart" -WindowStyle Hidden -Wait
        
        Write-Log "Instalação concluída" -Level "SUCCESS"
    }
    catch {
        Write-Log "Erro no download/instalação: $($_.Exception.Message)" -Level "WARNING"
    }
}

function Configure-VPN {
    Write-Log "Configurando VPN: $ConnectionName"
    Write-Log "Servidor: $Gateway`:$Port"
    
    $vpnPath = Join-Path $env:APPDATA "FortiClient\Vpn\Connections"
    if (-not (Test-Path $vpnPath)) {
        New-Item -ItemType Directory -Path $vpnPath -Force | Out-Null
    }
    
    $configFile = Join-Path $vpnPath "$ConnectionName.fcc"
    
    $config = @"
<?xml version="1.0" encoding="UTF-8"?>
<FortiClientVPNProfile>
    <Name>$ConnectionName</Name>
    <Type>1</Type>
    <Server>$Gateway</Server>
    <Port>$Port</Port>
    <Username>$Username</Username>
    <AuthType>1</AuthType>
    <SavePassword>true</SavePassword>
    <RememberPassword>true</RememberPassword>
    <DefaultGateway>true</DefaultGateway>
    <Timeout>30</Timeout>
    <VpnType>1</VpnType>
</FortiClientVPNProfile>
"@
    
    $config | Out-File -FilePath $configFile -Encoding UTF8 -Force
    
    Write-Log "Configuração salva: $configFile" -Level "SUCCESS"
}

Write-Log "========================================" -Level "INFO"
Write-Log "FortiClient VPN - Install & Configure" -Level "INFO"
Write-Log "========================================" -Level "INFO"
Write-Log "Usuário: $Username" -Level "INFO"
Write-Log "Conexão: $ConnectionName -> $Gateway`:$Port" -Level "INFO"
Write-Log "========================================" -Level "INFO"

if (-not (Test-IsInstalled)) {
    Write-Log "Instalando FortiClient..." -Level "INFO"
    Install-FortiClient
}
else {
    Write-Log "FortiClient já instalado" -Level "SUCCESS"
}

Configure-VPN

Write-Log "========================================" -Level "SUCCESS"
Write-Log "Pronto! Abra o FortiClient e conecte." -Level "SUCCESS"
Write-Log "========================================" -Level "SUCCESS"