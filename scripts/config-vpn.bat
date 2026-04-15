@echo off
echo ========================================
echo   VPN TJRN - Configuracao Rapida
echo ========================================
echo.

if "%1"=="" (
    set /p USUARIO=Digite seu usuario de rede: 
) else (
    set USUARIO=%1
)

echo.
echo Criando configuracao...

set VPN_PATH=%APPDATA%\FortiClient\Vpn\Connections
if not exist "%VPN_PATH%" mkdir "%VPN_PATH%"

echo ^<?xml version="1.0" encoding="UTF-8" ?^>^<FortiClientVPNProfile^>^<Name^>TJRN^</Name^>^<Type^>ssl^</Type^>^<RemoteGateway^>vpn.tjrn.jus.br^</RemoteGateway^>^<Port^>10443^</Port^>^<Username^>%USUARIO%^</Username^>^<AuthMethod^>0^</AuthMethod^>^<SavePassword^>true^</SavePassword^>^<DefaultGateway^>true^</DefaultGateway^>^</FortiClientVPNProfile^> > "%VPN_PATH%\TJRN.conn"

echo Configuracao criada em: %VPN_PATH%\TJRN.conn
echo.

echo Pressione qualquer tecla para abrir FortiClient...
pause > nul

start "" "C:\Program Files\Fortinet\FortiClient\FortiClient.exe"

echo.
echo ========================================
echo   INSTRUCOES
echo ========================================
echo 1. Abra o FortiClient
echo 2. Procure por "TJRN" na lista
echo 3. Se nao aparecer, clique em "+" para adicionar
echo 4. Configure manualmente:
echo    - Nome: TJRN
echo    - Gateway: vpn.tjrn.jus.br
echo    - Porta: 10443
echo    - Usuario: %USUARIO%
echo 5. Clique em Conectar
echo ========================================

pause