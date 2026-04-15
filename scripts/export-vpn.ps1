<#
.SYNOPSIS
    Exporta configuração VPN do FortiClient

.DESCRIPTION
    Cria XML exportável para importar no FortiClient
#>

param(
    [string]$Username,
    [string]$OutputPath
)

if (-not $Username) {
    $Username = Read-Host "Digite seu usuario de rede"
}

if (-not $OutputPath) {
    $OutputPath = $env:USERPROFILE
}

$xmlExport = @"
<?xml version="1.0" encoding="UTF-8"?>
<forticlient_vpn>
  <vpn>
    <ssl>
      <connections>
        <connection>
          <name>TJRN</name>
          <server>vpn.tjrn.jus.br</server>
          <port>10443</port>
          <username>$Username</username>
          <password></password>
          <save_password>true</save_password>
          <autoconnect>false</autoconnect>
          <verify_server_cert>false</verify_server_cert>
        </connection>
      </connections>
    </ssl>
  </vpn>
</forticlient_vpn>
"@

$xmlFile = Join-Path $OutputPath "TJRN-vpn-export.xml"
$xmlExport | Out-File -FilePath $xmlFile -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "XML Exportado!"
Write-Host "========================================"
Write-Host "Arquivo: $xmlFile"
Write-Host ""
Write-Host "Para importar no FortiClient:"
Write-Host "1. Abra FortiClient"
Write-Host "2. Va em Configurações ou Menu"
Write-Host "3. Procure 'Importar' ou 'Import'"
Write-Host "4. Selecione este arquivo XML"
Write-Host ""
Read-Host