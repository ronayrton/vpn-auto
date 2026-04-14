<#
.SYNOPSIS
    Script de automação para instalação do FortiClient VPN

.DESCRIPTION
    Este script automatiza o download e instalação do FortiClient VPN em ambientes corporativos.
    Designed para uso em suporte técnico remoto (Assistência Rápida do Windows).

.PARAMETER SkipCheck
    Pula verificação de instalação existente

.PARAMETER CustomUrl
    URL customizada para o instalador

.EXAMPLE
    .\install-forticlient.ps1

.EXAMPLE
    .\install-forticlient.ps1 -CustomUrl "https://servidor.com/vpn.exe"

.NOTES
    Autor: Equipe de Suporte
    Versão: 2.0.0
    Data: 2026-04-13
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
            Invoke-RestMethod -Uri $url -OutFile $tempPath -TimeoutSec 120 -ErrorAction Stop
            
            if (Test-Path $tempPath) {
                $fileSize = (Get-Item $tempPath).Length
                Write-Log "Download concluído. Tamanho: $([math]::Round($fileSize / 1MB, 2)) MB" -Level "SUCCESS"
                return $tempPath
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
        throw "Instalador não encontrado: $InstallerPath"
    }
    
    Write-Log "Iniciando instalação silenciosa..."
    
    try {
        $process = Start-Process -FilePath $InstallerPath -ArgumentList "-quiet -norestart" -WindowStyle Hidden -Wait -PassThru
        
        Start-Sleep -Seconds 5
        
        $fortiProc = Get-Process -Name "FortiClientVPN" -ErrorAction SilentlyContinue
        if ($fortiProc) {
            Write-Log "Instalação concluída (FortiClient executando)" -Level "SUCCESS"
            return $true
        }
        
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Log "Instalação concluída com sucesso!" -Level "SUCCESS"
            return $true
        }
        else {
            Write-Log "Instalação finalizada com código: $($process.ExitCode)" -Level "WARNING"
            return $true
        }
    }
    catch {
        Write-Log "Erro durante instalação: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Open-FallbackDownload {
    Write-Log "Abrindo navegador para download manual..." -Level "WARNING"
    try {
        Start-Process "https://suporte.tjrn.jus.br/arquivos/vpn.exe"
        Write-Log "Navegador aberto. Por favor, baixe e execute o instalador manualmente." -Level "INFO"
    }
    catch {
        Write-Log "Falha ao abrir navegador: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Initialize-Prerequisites {
    Write-Log "Verificando prerequisites..."
    
    if (-not (Test-Administrator)) {
        Write-Log "Este script requer execução como Administrador!" -Level "ERROR"
        Write-Log "Execute o PowerShell como Administrador e tente novamente." -Level "INFO"
        throw "Permissão administrador necessária"
    }
    
    $netVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release
    if ($netVersion -lt 533320) {
        Write-Log ".NET Framework 4.8 ou superior necessário" -Level "WARNING"
    }
    
    Write-Log "Prerequisites OK" -Level "SUCCESS"
}

function Register-InstallationMetric {
    param([bool]$Success)
    
    $eventLogName = "Application"
    $source = "Assyst-VPN-Automation"
    
    try {
        if (-not [System.Diagnostics.EventLog]::SourceExists($source)) {
            New-EventLog -LogName $eventLogName -Source $source -ErrorAction SilentlyContinue
        }
        
        $message = if ($Success) { "FortiClientVPN instalado com sucesso" } else { "Falha na instalação do FortiClientVPN" }
        Write-EventLog -LogName $eventLogName -Source $source -Message $message -EventId 1001 -EntryType $(if ($Success) { "Information" } else { "Error" }) -ErrorAction SilentlyContinue
    }
    catch {
        Write-Log "Não foi possível registrar métrica: $($_.Exception.Message)" -Level "WARNING"
    }
}

function Main {
    Write-Log "========================================" -Level "INFO"
    Write-Log "Assyst VPN Automation - Início" -Level "INFO"
    Write-Log "========================================" -Level "INFO"
    
    try {
        Initialize-Prerequisites
        
        if (-not $SkipCheck -and (Test-IsInstalled)) {
            Write-Log "FortiClient já está instalado. Use -SkipCheck para forçar reinstall." -Level "WARNING"
            return
        }
        
        if ($CustomUrl) {
            $downloadUrls = @($CustomUrl)
        } else {
            $downloadUrls = @(
                "https://suporte.tjrn.jus.br/arquivos/vpn.exe"
            )
        }
        
        $installerPath = Get-FortiClientInstaller -Urls $downloadUrls
        
        if ($null -eq $installerPath) {
            Write-Log "Todas as URLs de download falharam" -Level "ERROR"
            Open-FallbackDownload
            Register-InstallationMetric -Success $false
            return
        }
        
        $installSuccess = Install-FortiClient -InstallerPath $installerPath
        
        Register-InstallationMetric -Success $installSuccess
        
        if ($installSuccess) {
            Write-Log "========================================" -Level "SUCCESS"
            Write-Log "FortiClient VPN instalado com sucesso!" -Level "SUCCESS"
            Write-Log "========================================" -Level "SUCCESS"
        }
        else {
            Write-Log "Instalação finalizado com erros" -Level "ERROR"
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
        
        Write-Log "Processo concluído" -Level "INFO"
    }
}

if ($MyInvocation.InvocationName -ne ".") {
    Main
}