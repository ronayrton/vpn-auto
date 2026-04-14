<#
.SYNOPSIS
    Script de configuração do FortiClient VPN

.DESCRIPTION
    Configura automaticamente a conexão VPN no FortiClient.

.PARAMETER ConnectionName
    Nome da conexão (padrão: TJRN)

.PARAMETER Gateway
    Endereço do servidor VPN

.PARAMETER Port
    Porta do servidor VPN (padrão: 10443)

.PARAMETER Username
    Usuário para autenticação

.EXAMPLE
    .\configure-vpn.ps1 -Username "usuario"

.NOTES
    Autor: Equipe de Suporte
    Versão: 1.0.0
#>

[CmdletBinding()]
param(
    [string]$ConnectionName = "TJRN",
    [string]$Gateway = "vpn.tjrn.jus.br",
    [int]$Port = 10443,
    [Parameter(Mandatory=$true)]
    [string]$Username
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

function Test-FortiClientInstalled {
    $app = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*FortiClient*" }
    if (-not $app) {
        $reg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -like "*FortiClient*" }
        if (-not $reg) {
            return $false
        }
    }
    return $true
}

function New-VPNConnection {
    param(
        [string]$Name,
        [string]$Server,
        [int]$Port,
        [string]$Username
    )
    
    Write-Log "Configurando VPN: $Name"
    Write-Log "Servidor: $Server`:$Port"
    Write-Log "Usuário: $Username"
    
    $fortiPath = "${env:ProgramFiles}\Fortinet\FortiClient\FortiClient.exe"
    
    if (-not (Test-Path $fortiPath)) {
        $fortiPath = "${env:ProgramFiles(x86)}\Fortinet\FortiClient\FortiClient.exe"
    }
    
    if (-not (Test-Path $fortiPath)) {
        throw "FortiClient não encontrado"
    }
    
    $vpnConfigPath = Join-Path $env:APPDATA "FortiClient\Vpn\Connections"
    
    if (-not (Test-Path $vpnConfigPath)) {
        New-Item -ItemType Directory -Path $vpnConfigPath -Force | Out-Null
    }
    
    $configFile = Join-Path $vpnConfigPath "$Name.fcc"
    
    $configContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<FortiClientVPNProfile>
    <Name>$Name</Name>
    <Type>1</Type>
    <Server>$Server</Server>
    <Port>$Port</Port>
    <Username>$Username</Username>
    <AuthType>1</AuthType>
    <SavePassword>true</SavePassword>
    <RememberPassword>true</RememberPassword>
    <ShowPassword>false</ShowPassword>
    <CertValidation></CertValidation>
    <PublicGateway></PublicGateway>
    <DefaultGateway>true</DefaultGateway>
    <Timeout>30</Timeout>
    <KeepAlive>0</KeepAlive>
    <DisconnectOnIdle>false</DisconnectOnIdle>
    <IdleTimeout>0</IdleTimeout>
    <SplitTunneling>true</SplitTunneling>
    <DNSSuffix></DNSSuffix>
    <InterfaceMTU>1400</InterfaceMTU>
    <AuthMethod>1</AuthMethod>
    <EapMethod></EapMethod>
    <VerifyServerCert>false</VerifyServerCert>
    <TrustedServer></TrustedServer>
    <PluginVersion></PluginVersion>
    <MarketVersion>7.0</MarketVersion>
    <VpnType>1</VpnType>
</FortiClientVPNProfile>
"@
    
    $configContent | Out-File -FilePath $configFile -Encoding UTF8 -Force
    
    Write-Log "Arquivo de configuração criado: $configFile" -Level "SUCCESS"
    
    return $configFile
}

function Main {
    Write-Log "========================================" -Level "INFO"
    Write-Log "Configuração VPN FortiClient" -Level "INFO"
    Write-Log "========================================" -Level "INFO"
    
    try {
        if (-not (Test-FortiClientInstalled)) {
            Write-Log "FortiClient não está instalado!" -Level "ERROR"
            Write-Log "Execute o script de instalação primeiro." -Level "INFO"
            return
        }
        
        $configPath = New-VPNConnection -Name $ConnectionName -Server $Gateway -Port $Port -Username $Username
        
        Write-Log "========================================" -Level "SUCCESS"
        Write-Log "VPN configurada com sucesso!" -Level "SUCCESS"
        Write-Log "========================================" -Level "SUCCESS"
        Write-Log "Abra o FortiClient e conecte usando a conexão '$ConnectionName'" -Level "INFO"
    }
    catch {
        Write-Log "Erro: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

Main