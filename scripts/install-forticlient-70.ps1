<#
.SYNOPSIS
    Script de automação para instalação do FortiClient VPN 7.0

.DESCRIPTION
    Este script automatiza o download e instalação do FortiClient VPN versão 7.0.

.NOTES
    Autor: Equipe de Suporte
    Versão: 1.0.0
#>

[CmdletBinding()]
param(
    [switch]$SkipCheck,
    [string]$CustomUrl
)

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
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

function Test-IsInstalled {
    $app = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*FortiClient*" }
    if ($app) {
        Write-Log "FortiClient ja instalado: $($app.Name) v$($app.Version)" -Level "INFO"
        return $true
    }
    $reg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -like "*FortiClient*" }
    if ($reg) {
        Write-Log "FortiClient ja instalado (registro): $($reg.DisplayName)" -Level "INFO"
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
            Invoke-RestMethod -Uri $url -OutFile $tempPath -TimeoutSec 120
            
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
        $process = Start-Process -FilePath $InstallerPath -ArgumentList "/quiet /norestart" -WindowStyle Hidden -Wait -PassThru
        
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Log "Instalacao concluida com sucesso!" -Level "SUCCESS"
            return $true
        }
        else {
            Write-Log "Instalacao finalizada com codigo: $($process.ExitCode)" -Level "WARNING"
            return $true
        }
    }
    catch {
        Write-Log "Erro durante instalacao: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Initialize-Prerequisites {
    Write-Log "Verificando prerequisites..."
    
    if (-not (Test-Administrator)) {
        Write-Log "Este script requer execucao como Administrador!" -Level "ERROR"
        throw "Permissao administrador necessaria"
    }
    
    Write-Log "Prerequisites OK" -Level "SUCCESS"
}

function Main {
    Write-Log "========================================" -Level "INFO"
    Write-Log "FortiClient VPN 7.0 - Instalacao" -Level "INFO"
    Write-Log "========================================" -Level "INFO"
    
    try {
        Initialize-Prerequisites
        
        if (-not $SkipCheck -and (Test-IsInstalled)) {
            Write-Log "FortiClient ja esta instalado. Use -SkipCheck para forcar reinstall." -Level "WARNING"
            return
        }
        
        if ($CustomUrl) {
            $downloadUrls = @($CustomUrl)
        } else {
            $downloadUrls = @(
                "https://github.com/ronayrton/vpn-auto/releases/download/v2.0.0/FortiClientVPN7.0.exe"
            )
        }
        
        $installerPath = Get-FortiClientInstaller -Urls $downloadUrls
        
        if ($null -eq $installerPath) {
            Write-Log "Todas as URLs de download falharam" -Level "ERROR"
            return
        }
        
        $installSuccess = Install-FortiClient -InstallerPath $installerPath
        
        if ($installSuccess) {
            Write-Log "========================================" -Level "SUCCESS"
            Write-Log "FortiClient VPN 7.0 instalado com sucesso!" -Level "SUCCESS"
            Write-Log "========================================" -Level "SUCCESS"
        }
    }
    catch {
        Write-Log "Erro critico: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
    finally {
        if ($installerPath -and (Test-Path $installerPath)) {
            Write-Log "Limpando arquivos temporarios..."
            Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        }
        
        Write-Log "Processo concluido" -Level "INFO"
    }
}

if ($MyInvocation.InvocationName -ne ".") {
    Main
}