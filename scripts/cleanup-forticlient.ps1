<#
.SYNOPSIS
    Limpa completamente FortiClient

.DESCRIPTION
    Remove FortiClient e todas as configurações

.NOTES
    Autor: Equipe de Suporte
#>

# Parar serviços
Get-Process FortiClient* -ErrorAction SilentlyContinue | Stop-Process -Force

# Remover pastas de configuração
Write-Host "Removendo configurações..."
Remove-Item "$env:APPDATA\FortiClient" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\FortiClient" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\ProgramData\Fortinet" -Recurse -Force -ErrorAction SilentlyContinue

# Remover registro
Write-Host "Removendo registro..."
Remove-Item "HKLM:\SOFTWARE\Fortinet" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "HKCU:\SOFTWARE\Fortinet" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Limpeza concluída!" -ForegroundColor Green
Write-Host "Reinicie o computador e instale novamente." -ForegroundColor Yellow