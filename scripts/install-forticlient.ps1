#>
.SYNOPSIS
    Script de automacao para instalacao do FortiClient VPN

.DESCRIPTION
    Este script automatiza o download e instalacao do FortiClient VPN em ambientes corporativos.
    Designed para uso em suporte tecnico remoto (Assistencia Rapida do Windows).

.PARAMETER SkipCheck
    Pula verificacao de instalacao existente

.PARAMETER CustomUrl
    URL customizada para o instalador

.PARAMETER SkipConfig
    Pula configuracao automatica da VPN

.EXAMPLE
    .\install-forticlient.ps1

.EXAMPLE
    .\install-forticlient.ps1 -CustomUrl "https://servidor.com/vpn.exe"

.EXAMPLE
    .\install-forticlient.ps1 -SkipConfig

.NOTES
    Autor: Equipe de Suporte
    Versao: 3.0.1
    Data: 2026-04-15
#>

[CmdletBinding()]
param(
    [switch]$SkipCheck,
    [switch]$SkipConfig,
    [string]$CustomUrl
)

# ==============================================================================
# CONFIGURACOES DA VPN - Edite aqui conforme necessario
# ==============================================================================
$VPNConfig = @{
    NomePerfil = "TJRN"           # Nome do perfil VPN
    Gateway    = "vpn.tjrn.jus.br"  # Endereco do servidor VPN
    Porta      = 10443           # Porta do servidor VPN (padrao: 443)
}
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colors = @{
        "INFO"    = "Cyan"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR"   = "Red"
        "INPUT"   = "White"
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

function Test-IsInstalled {
    $fortiExe = "C:\Program Files\Fortinet\FortiClient\FortiClient.exe"
    if (Test-Path $fortiExe) {
        Write-Log "FortiClient já instalado: $fortiExe" -Level "INFO"
        return $true
    }
    $app = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*FortiClient*" }
    if ($app) {
        Write-Log "FortiClient já instalado: $($app.Name) v$($app.Version)" -Level "INFO"
        return $true
    }
    $reg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -like "*FortiClient*" }
    if ($reg) {
        Write-Log "FortiClient já instalado (registro): $($reg.DisplayName)" -Level "INFO"
        return $true
    }
    return $false
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-FortiClientInstaller {
    param([string[]]$Urls)
    
    $tempPath = Join-Path $env:TEMP "FortiClientVPNSetup.exe"
    
    foreach ($url in $Urls) {
        Write-Log "Tentando baixar: $url"
        
        try {
            Write-Log "Baixando instalador..."
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            
            if ($url -match "google.com" -or $url -match "drive.google.com") {
                $webClient = New-Object System.Net.WebClient
                $webClient.Headers.Add("User-Agent", "Mozilla/5.0")
                $webClient.DownloadFile($url, $tempPath)
            }
            else {
                Invoke-RestMethod -Uri $url -OutFile $tempPath -TimeoutSec 120
            }
            
            if (Test-Path $tempPath) {
                $fileSize = (Get-Item $tempPath).Length
                if ($fileSize -gt 1000) {
                    Write-Log "Download concluido. Tamanho: $([math]::Round($fileSize / 1MB, 2)) MB" -Level "SUCCESS"
                    return $tempPath
                }
            }
        }
        catch {
            Write-Log "Falha ao baixar de $url : $($_.Exception.Message)" -Level "WARNING"
            continue
        }
    }
    
    return $null
}

function Install-FortiClient {
    param([string]$InstallerPath)
    
    if (-not (Test-Path $InstallerPath)) {
        throw "Instalador nao encontrado: $InstallerPath"
    }
    
    Write-Log "Iniciando instalacao silenciosa..."
    
    try {
        Write-Log "Limpando restos de instalacao anterior..." -Level "INFO"
        
        try {
            Stop-Service -Name "msiserver" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            Start-Service -Name "msiserver" -ErrorAction SilentlyContinue
        } catch { }
        
        $rollbackKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Installer\Rollback\Scripts"
        Remove-Item -Path $rollbackKey -Recurse -ErrorAction SilentlyContinue
        
        $logFile = "$env:TEMP\FortiClientInstall.log"
        
        Write-Log "Executando instalador..." -Level "INFO"
        $process = Start-Process -FilePath $InstallerPath -ArgumentList "/quiet /norestart" -WindowStyle Hidden -Wait -PassThru
        
        Start-Sleep -Seconds 15
        
        $fortiExe = "C:\Program Files\Fortinet\FortiClient\FortiClient.exe"
        if (Test-Path $fortiExe) {
            Write-Log "Instalacao concluida (FortiClient.exe encontrado)" -Level "SUCCESS"
            return $true
        }
        
        $fortiProc = Get-Process -Name "FortiClientVPN" -ErrorAction SilentlyContinue
        if ($fortiProc) {
            Write-Log "Instalacao concluida (FortiClientVPN executando)" -Level "SUCCESS"
            return $true
        }
        
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
Write-Log "Instalacao concluida com sucesso!" -Level "SUCCESS"

        if (-not $installSuccess) {
            Write-Log "Instalacao finalizada com erros" -Level "ERROR"
            }
        }
        
        # Configuracao automatica da VPN (sempre executa, mesmo se ja instalado)
        if (-not $SkipConfig) {
            Write-Log "========================================" -Level "INFO"
            Write-Log "Iniciando configuracao da VPN..." -Level "INFO"
            Write-Log "========================================" -Level "INFO"
            
            $configSuccess = New-VPNConfiguration
            
if ($configSuccess) {
                Write-Log "========================================" -Level "SUCCESS"
                Write-Log "VPN configurada automaticamente!" -Level "SUCCESS"
                Write-Log "========================================" -Level "SUCCESS"
            }
        }
    }
    catch {
        Write-Log "Erro crítico: $($_.Exception.Message)" -Level "ERROR"
        Register-InstallationMetric -Success $false
        throw
    }
    finally {
        if ($installerPath -and (Test-Path $installerPath)) {
            Write-Log "Limpando arquivos temporários..."
            Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        }
        
        Write-Log "========================================" -Level "INFO"
        Write-Log "Processo concluído!" -Level "SUCCESS"
        Write-Log "========================================" -Level "INFO"
    }
}

if ($MyInvocation.InvocationName -ne ".") {
    Main
}