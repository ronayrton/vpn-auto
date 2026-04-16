<!-- omit in toc -->
# Assyst VPN Automation

Automação para instalação do FortiClient VPN em ambientes corporativos usando PowerShell.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+--blue)](https://docs.microsoft.com/pt-br/powershell/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Objetivo

Automatizar a instalação do FortiClient VPN em estações de trabalho corporativas, reduzindo o tempo de atendimento do suporte técnico em Assistência Rápida do Windows.

## Quick Start (1 linha)

```powershell
irm "https://raw.githubusercontent.com/ronayrton/vpn-auto/main/scripts/install-forticlient.ps1?t=$(Get-Random)" -OutFile "$env:TEMP\install.ps1"; & "$env:TEMP\install.ps1"
```

> **Nota**: Execute o PowerShell como Administrador antes de executar o comando acima.

## Estrutura do Projeto

```
vpn-auto/
├── README.md                      # Este arquivo
├── LICENSE                        # Licença MIT
├── scripts/
│   ├── install-forticlient.ps1     # Script principal (instalar + configurar)
│   ├── config-vpn.ps1            # Configurar VPN apenas
│   ├── configure-vpn-ui.ps1      # Configurar VPN com Interface Gráfica
│   ├── cleanup-forticlient.ps1   # Desinstalar FortiClient
│   ├── full-install-70.ps1       # Instalação completa (FortiClient 7.0)
│   ├── install-forticlient-70.ps1 # Instalar apenas (versão 7.0)
│   ├── install-config-70.ps1     # Instalar + configurar (7.0)
│   ├── install-and-configure.ps1 # Instalar + configurar
│   ├── export-vpn.ps1           # Exportar configuração VPN
│   └── clean-install.ps1         # Limpar + instalar
├── install/
│   └── run-install.ps1           # Script para execução remota
└── docs/
    └── runbook.md               # Guia para técnicos
```

## Scripts

### scripts/install-forticlient.ps1 (Principal)

Script principal que executa:
1. **Verificação de permissões** - Confirma execução como Administrador
2. **Verificação se já instalado** - Detecta instalação existente
3. **Download do instalador** - Baixa de URLs configuradas
4. **Instalação silenciosa** -Executa com parâmetros `/quiet /norestart`
5. **Configuração automática** - Cria perfil TJRN no registro
6. **Tratamento de erros** - Try/Catch com logs detalhados

**Parâmetros:**
- `-SkipCheck` - Pula verificação de instalação
- `-SkipConfig` - Pula configuração automática
- `-CustomUrl` - URL customizada do instalador

### scripts/config-vpn.ps1

Script para configurar apenas o perfil VPN (sem instalação):
- Cria perfil TJRN no registro
- Configura gateway vpn.tjrn.jus.br:10443
- Não armazena senha (usuário digita manualmente)

### scripts/cleanup-forticlient.ps1

Script para desinstalar o FortiClient:
- Remove via.msiexec
- Limpa arquivos remanescentes
- Limpa registros do Windows

### scripts/clean-install.ps1

Script para limpeza completa:
- Desinstala versão anterior
- Limpa registros e arquivos
- Instala nova versão

## URLs de Download

O script tenta múltiplas fontes (ordem de prioridade):

| # | URL | Versão FortiClient |
|---|-----|-------------------|
| 1 | https://github.com/ronayrton/vpn-auto/releases/download/v2.0.0/FortiClientVPN7.0.exe | 7.0 |
| 2 | https://github.com/ronayrton/vpn-auto/releases/download/v1.0.0/vpntjrn.exe | 7.2 |

## Configuração VPN (Registro)

O script configura automaticamente o perfil TJRN no registro:

Caminho: `HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\TJRN`

Propriedades:
- `Server` = vpn.tjrn.jus.br:10443
- `Description` = VPN Automática TJRN
- `promptusername` = 0
- `promptcertificate` = 0
- `ServerCert` = 1
- `sso_enabled` = 0
- `use_external_browser` = 0
- `username` = (vazio)
- `show_remember_password` = 1
- `save_credentials` = 1
- `save_password` = 1
- `warn_invalid_server_certificate` = 1

## Tecnologias

- **PowerShell 5.1+** - Linguagem principal
- **Windows Event Log** - Logging de auditoria
- **Invoke-WebRequest** - Download de arquivos

## Benefícios

- **Redução de tempo**: ~5 minutos por atendimento
- **Automação**: Sem intervenção manual do usuário
- **Consistência**: Instalação padronizada em todas as máquinas
- **Auditoria**: Logs de instalação no Event Viewer

## Pré-requisitos

- Windows 10/11 ou Windows Server 2016+
- PowerShell 5.1+
- Permissão de Administrador
- Acesso à internet para download

## Logs

Os logs são exibidos no console durante a execução e também registrados no Windows Event Viewer:

- **Log Name**: Application
- **Source**: Assyst-VPN-Automation
- **Event ID**: 1001

## Suporte

Para dúvidas ou problemas:
1. Execute com `-Verbose` para logs detalhados
2. Verifique o Event Viewer
3. Abra uma issue no GitHub

## Licença

Este projeto está sob licença MIT. Veja o arquivo [LICENSE](LICENSE) para detalhes.

---

Feito com ❤ pela Equipe de Suporte