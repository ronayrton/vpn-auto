<#
.SYNOPSIS
    Script completo: instala e configura FortiClient VPN

.DESCRIPTION
    Instala o FortiClient e configura a conexão VPN automaticamente.

.PARAMETER Username
    Usuário de autenticação (obrigatório)

.PARAMETER Password
    Senha de autenticação (opcional - será solicitado se não informado)

.PARAMETER SkipInstall
    Pula instalação e apenas configura

.EXAMPLE
    .\install-and-configure.ps1 -Username "usuario"

.NOTES
    Autor: Equipe de Suporte
    Versão: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Username,
    [string]$Password,
    [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colors = @{
        "INFO"    = "Cyan"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR"   = "Red"
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

$script:ConnectionName = "TJRN"
$script:Gateway = "vpn.tjrn.jus.br"
$script:Port = 10443

function Invoke-InstallFortiClient {
    Write-Log "Iniciando instalação do FortiClient..."
    
    $tempPath = Join-Path $env:TEMP "FortiClientVPNSetup.exe"
    $downloadUrls = @(
        "https://github.com/ronayrton/vpn-auto/releases/download/v1.0.0/vpntjrn.exe"
    )
    
    foreach ($url in $downloadUrls) {
        Write-Log "Baixando: $url"
        
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-RestMethod -Uri $url -OutFile $tempPath -TimeoutSec 120
            
            if (Test-Path $tempPath) {
                $fileSize = (Get-Item $tempPath).Length
                if ($fileSize -gt 1000) {
                    Write-Log "Download concluído: $([math]::Round($fileSize / 1MB, 2)) MB" -Level "SUCCESS"
                    
                    Write-Log "Instalando..."
                    Start-Process -FilePath $tempPath -ArgumentList "/quiet /norestart" -WindowStyle Hidden -Wait
                    
                    Write-Log "Instalação concluída" -Level "SUCCESS"
                    return $true
                }
            }
        }
        catch {
            Write-Log "Falha: $($_.Exception.Message)" -Level "WARNING"
        }
    }
    
    throw "Falha no download e instalação"
}

function Invoke-ConfigureVPN {
    param([string]$User)
    
    Write-Log "Configurando VPN..."
    
    $vpnConfigPath = Join-Path $env:APPDATA "FortiClient\Vpn\Connections"
    
    if (-not (Test-Path $vpnConfigPath)) {
        New-Item -ItemType Directory -Path $vpnConfigPath -Force | Out-Null
    }
    
    $configFile = Join-Path $vpnConfigPath "$ConnectionName.fcc"
    
    $configContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<FortiClientVPNProfile>
    <Name>$ConnectionName</Name>
    <Type>1</Type>
    <Server>$Gateway</Server>
    <Port>$Port</Port>
    <Username>$User</Username>
    <AuthType>1</AuthType>
    <SavePassword>true</SavePassword>
    <RememberPassword>true</RememberPassword>
    <DefaultGateway>true</DefaultGateway>
    <Timeout>30</Timeout>
    <VpnType>1</VpnType>
</FortiClientVPNProfile>
"@
    
    $configContent | Out-File -FilePath $configFile -Encoding UTF8 -Force
    
    Write-Log "VPN configurada: $ConnectionName -> $Gateway`:$Port" -Level "SUCCESS"
    Write-Log "Arquivo: $configFile" -Level "SUCCESS"
}

function Main {
    Write-Log "========================================" -Level "INFO"
    Write-Log "FortiClient - Install & Configure" -Level "INFO"
    Write-Log "========================================" -Level "INFO"
    Write-Log "Conexão: $ConnectionName" -Level "INFO"
    Write-Log "Servidor: $Gateway`:$Port" -Level "INFO"
    Write-Log "Usuário: $Username" -Level "INFO"
    Write-Log "========================================" -Level "INFO"
    
    if (-not $SkipInstall) {
        Invoke-InstallFortiClient
    }
    
    Invoke-ConfigureVPN -User $Username
    
    Write-Log "========================================" -Level "SUCCESS"
    Write-Log "Concluído! Abra o FortiClient para conectar." -Level "SUCCESS"
    Write-Log "========================================" -Level "SUCCESS"
}

Main