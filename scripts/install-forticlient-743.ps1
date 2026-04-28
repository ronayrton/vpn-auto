<#
.SYNOPSIS
    Script de automação para instalação e configuração do FortiClient VPN 7.4.3

.DESCRIPTION
    Este script automatiza o download, instalação e configuração do FortiClient VPN versão 7.4.3.

.PARAMETER SkipCheck
    Pula verificação de instalação existente

.PARAMETER CustomUrl
    URL customizada para o instalador

.PARAMETER SkipConfig
    Pula configuração automática da VPN

.EXAMPLE
    .\install-forticlient-743.ps1

.EXAMPLE
    .\install-forticlient-743.ps1 -SkipConfig

.NOTES
    Autor: Equipe de Suporte
    Versão: 1.1.0
    Data: Abril 2026
#>

[CmdletBinding()]
param(
    [switch]$SkipCheck,
    [switch]$SkipConfig,
    [string]$CustomUrl
)

# ==============================================================================
# CONFIGURAÇÕES DA VPN
# ==============================================================================
$VPNConfig = @{
    NomePerfil = "TJRN"
    Gateway    = "vpn.tjrn.jus.br"
    Porta      = 10443
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
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

function Test-IsInstalled {
    $fortiExe = "C:\Program Files\Fortinet\FortiClient\FortiClient.exe"
    if (Test-Path $fortiExe) {
        $versionInfo = (Get-Item $fortiExe).VersionInfo
        Write-Log "FortiClient ja instalado: $($versionInfo.ProductName) v$($versionInfo.ProductVersion)" -Level "INFO"
        return $true
    }
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

    $tempPath = Join-Path $env:TEMP "FortiClientVPNSetup_743.exe"

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
        Write-Log "Limpando restos de instalacao anterior..." -Level "INFO"

        try {
            Stop-Service -Name "msiserver" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            Start-Service -Name "msiserver" -ErrorAction SilentlyContinue
        } catch { }

        $rollbackKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Installer\Rollback\Scripts"
        Remove-Item -Path $rollbackKey -Recurse -ErrorAction SilentlyContinue

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
            return $true
        }
        else {
            Write-Log "Instalacao finalizada com codigo: $($process.ExitCode)" -Level "WARNING"
            if (Test-Path $fortiExe) {
                Write-Log "FortiClient.exe encontrado mesmo com codigo de erro" -Level "SUCCESS"
                return $true
            }
            return $false
        }
    }
    catch {
        Write-Log "Erro durante instalacao: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Register-InstallationMetric {
    param([bool]$Success)

    $eventLogName = "Application"
    $source = "Assyst-VPN-Automation"

    try {
        if (-not [System.Diagnostics.EventLog]::SourceExists($source)) {
            New-EventLog -LogName $eventLogName -Source $source -ErrorAction SilentlyContinue
        }

        $message = if ($Success) { "FortiClientVPN 7.4.3 instalado com sucesso" } else { "Falha na instalacao do FortiClientVPN 7.4.3" }
        Write-EventLog -LogName $eventLogName -Source $source -Message $message -EventId 1001 -EntryType $(if ($Success) { "Information" } else { "Error" }) -ErrorAction SilentlyContinue
    }
    catch {
        Write-Log "Nao foi possivel registrar metrica: $($_.Exception.Message)" -Level "WARNING"
    }
}

# ==============================================================================
# FUNÇÃO DE CONFIGURAÇÃO AUTOMÁTICA DA VPN VIA REGISTRO
# ==============================================================================
function New-VPNConfiguration {
    param()

    # ==============================================================================
    # Verificar se o FortiClient está instalado
    # ==============================================================================
    $fortiClientPath = "C:\Program Files\Fortinet\FortiClient\FortiClient.exe"

    if (-not (Test-Path $fortiClientPath)) {
        Write-Log "FortiClient não encontrado em $fortiClientPath - pulando configuração" -Level "WARNING"
        return $false
    }

    Write-Log "========================================" -Level "INFO"
    Write-Log "Configuração Automática da VPN TJRN" -Level "INFO"
    Write-Log "========================================" -Level "INFO"

    # Aguardar 5 segundos para o FortiClient estar pronto após instalação
    Write-Log "Aguardando 5 segundos..." -Level "INFO"
    Start-Sleep -Seconds 5

    try {
        # ==============================================================================
        # Criar chave do registro para o perfil VPN
        # ==============================================================================
        $registryPath = "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\TJRN"

        Write-Log "Criando perfil VPN no registro..." -Level "INFO"
        Write-Log "Caminho: $registryPath" -Level "INFO"

        # Remover config anterior antes de criar nova
        if (Test-Path $registryPath) {
            Write-Log "Removendo configuração anterior..." -Level "INFO"
            Remove-Item -Path $registryPath -Recurse -Force
        }

        # Criar a chave do registro
        New-Item -Path $registryPath -Force | Out-Null
        Write-Log "Chave do registro criada" -Level "INFO"

        # ==============================================================================
        # Configurar as propriedades do perfil VPN com dados reais
        # ==============================================================================
        $serverAddress = "vpn.tjrn.jus.br:10443"

        # Server - Endereço do gateway VPN
        Set-ItemProperty -Path $registryPath -Name "Server" -Value $serverAddress -Type String -ErrorAction Stop
        Write-Log "  - Server: $serverAddress" -Level "INFO"

        # promptusername = 1 (DWord) - Usar usuário salvo
        Set-ItemProperty -Path $registryPath -Name "promptusername" -Value 1 -Type DWord -ErrorAction Stop
        Write-Log "  - promptusername: 1 (usar usuário salvo)" -Level "INFO"

        # promptcertificate = 0 (DWord) - Nenhum certificado
        Set-ItemProperty -Path $registryPath -Name "promptcertificate" -Value 0 -Type DWord -ErrorAction Stop
        Write-Log "  - promptcertificate: 0" -Level "INFO"

        # ServerCert = "1" (String)
        Set-ItemProperty -Path $registryPath -Name "ServerCert" -Value "1" -Type String -ErrorAction Stop
        Write-Log "  - ServerCert: 1" -Level "INFO"

        # sso_enabled = 0 (DWord) - SSO desativado
        Set-ItemProperty -Path $registryPath -Name "sso_enabled" -Value 0 -Type DWord -ErrorAction Stop
        Write-Log "  - sso_enabled: 0" -Level "INFO"

        # use_external_browser = 0 (DWord)
        Set-ItemProperty -Path $registryPath -Name "use_external_browser" -Value 0 -Type DWord -ErrorAction Stop
        Write-Log "  - use_external_browser: 0" -Level "INFO"

        # username = "f000000" (String) - Usuário automático
        Set-ItemProperty -Path $registryPath -Name "username" -Value "f000000" -Type String -ErrorAction Stop
        Write-Log "  - username: f000000" -Level "INFO"

        # show_remember_password = 1 (DWord) - Mostra opção lembrar senha
        Set-ItemProperty -Path $registryPath -Name "show_remember_password" -Value 1 -Type DWord -ErrorAction Stop
        Write-Log "  - show_remember_password: 1" -Level "INFO"

        # save_credentials = 1 (DWord) - Salva credenciais
        Set-ItemProperty -Path $registryPath -Name "save_credentials" -Value 1 -Type DWord -ErrorAction Stop
        Write-Log "  - save_credentials: 1" -Level "INFO"

        # save_password = 1 (DWord) - Salva senha
        Set-ItemProperty -Path $registryPath -Name "save_password" -Value 1 -Type DWord -ErrorAction Stop
        Write-Log "  - save_password: 1" -Level "INFO"

        # warn_invalid_server_certificate = 1 (DWord)
        Set-ItemProperty -Path $registryPath -Name "warn_invalid_server_certificate" -Value 1 -Type DWord -ErrorAction Stop
        Write-Log "  - warn_invalid_server_certificate: 1" -Level "INFO"

        Write-Log "Perfil VPN configurado com sucesso!" -Level "SUCCESS"

        # ==============================================================================
        # Registrar no Windows Event Viewer
        # ==============================================================================
        $source = "Assyst-VPN-Automation"
        $eventLogName = "Application"
        try {
            if (-not [System.Diagnostics.EventLog]::SourceExists($source)) {
                New-EventLog -LogName $eventLogName -Source $source -ErrorAction SilentlyContinue
            }
            Write-EventLog -LogName $eventLogName -Source $source -Message "VPN TJRN configurada automaticamente - Server: $serverAddress (FortiClient 7.4.3)" -EventId 1001 -EntryType Information -ErrorAction SilentlyContinue
            Write-Log "Registrado no Event Viewer" -Level "INFO"
        }
        catch {
            Write-Log "Não foi possível registrar no Event Viewer: $($_.Exception.Message)" -Level "WARNING"
        }

        Write-Log "========================================" -Level "SUCCESS"
        Write-Log "VPN TJRN configurada com sucesso!" -Level "SUCCESS"
        Write-Log "========================================" -Level "SUCCESS"
        Write-Log "Instalação concluída!" -Level "INFO"
        Write-Log "FortiClient VPN 7.4.3 instalado e configurado." -Level "INFO"
        Write-Log "Abra o FortiClient manualmente para usar a VPN." -Level "INFO"
        Write-Log "========================================" -Level "INFO"

        return $true
    }
    catch {
        Write-Log "========================================" -Level "ERROR"
        Write-Log "Erro ao configurar VPN: $($_.Exception.Message)" -Level "ERROR"
        Write-Log "========================================" -Level "ERROR"

        # Registrar erro no Event Viewer
        try {
            $source = "Assyst-VPN-Automation"
            $eventLogName = "Application"
            if (-not [System.Diagnostics.EventLog]::SourceExists($source)) {
                New-EventLog -LogName $eventLogName -Source $source -ErrorAction SilentlyContinue
            }
            Write-EventLog -LogName $eventLogName -Source $source -Message "Erro ao configurar VPN TJRN: $($_.Exception.Message)" -EventId 1001 -EntryType Error -ErrorAction SilentlyContinue
        }
        catch {
            Write-Log "Não foi possível registrar erro no Event Viewer" -Level "WARNING"
        }

        return $false
    }
}
# ==============================================================================

function Initialize-Prerequisites {
    Write-Log "Verificando pré-requisitos..."

    if (-not (Test-Administrator)) {
        Write-Log "Este script requer execução como Administrador!" -Level "ERROR"
        Write-Log "Execute o PowerShell como Administrador e tente novamente." -Level "INFO"
        throw "Permissão administrador necessária"
    }

    $netVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Release
    if ($netVersion -lt 533320) {
        Write-Log ".NET Framework 4.8 ou superior necessário" -Level "WARNING"
    }

    Write-Log "Pré-requisitos OK" -Level "SUCCESS"
}

function Main {
    Write-Log "========================================" -Level "INFO"
    Write-Log "FortiClient VPN 7.4.3 - Instalação e Configuração" -Level "INFO"
    Write-Log "========================================" -Level "INFO"

    try {
        Initialize-Prerequisites

        $isInstalled = Test-IsInstalled

        if (-not $SkipCheck -and $isInstalled) {
            Write-Log "FortiClient já está instalado. Pulando instalação..." -Level "WARNING"
        }
        else {
            if (-not $isInstalled) {
                Write-Log "FortiClient não encontrado. Iniciando instalação..." -Level "INFO"
            }

            if ($CustomUrl) {
                $downloadUrls = @($CustomUrl)
            } else {
                $downloadUrls = @(
                    "https://github.com/ronayrton/vpn-auto/releases/download/v3.0.0/FortiClientVPN7.4.3.exe"
                )
            }

            $installerPath = Get-FortiClientInstaller -Urls $downloadUrls

            if ($null -eq $installerPath) {
                Write-Log "Todas as URLs de download falharam" -Level "ERROR"
                Register-InstallationMetric -Success $false
                return
            }

            $installSuccess = Install-FortiClient -InstallerPath $installerPath
            Register-InstallationMetric -Success $installSuccess

            if (-not $installSuccess) {
                Write-Log "Instalação finalizada com erros" -Level "ERROR"
            }
        }

        # Configuração automática da VPN (sempre executa, mesmo se já instalado)
        if (-not $SkipConfig) {
            Write-Log "========================================" -Level "INFO"
            Write-Log "Iniciando configuração da VPN..." -Level "INFO"
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
