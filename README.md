<!-- omit in toc -->
# Assyst VPN Automation

Automação para instalação do FortiClient VPN em ambientes corporativos usando PowerShell.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+--blue)](https://docs.microsoft.com/pt-br/powershell/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Objetivo

Automatizar a instalação do FortiClient VPN em estações de trabalho corporativas, reduzindo o tempo de atendimento do suporte técnico em Assistance Ránpida do Windows.

## Quick Start (1 linha)

```powershell
# Execução direta (sem baixar arquivos)
iex (iwr "https://raw.githubusercontent.com/ronayrton/vpn-auto/main/scripts/install-forticlient.ps1?$(Get-Random)" -UseBasicParsing)
```

> **Nota**: Execute o PowerShell como Administrador antes de executar o comando acima.

## Estrutura do Projeto

```
assyst-vpn-automation/
├── README.md              # Este arquivo
├── LICENSE                # Licença MIT
├── .gitignore              # Configurações Git
├── scripts/
│   └── install-forticlient.ps1    # Script principal
├── install/
│   └── run-install.ps1           # Script para execução remota
└── docs/
    └── runbook.md                # Guia para técnicos
```

## Scripts

### scripts/install-forticlient.ps1

Script principal que executa:

1. **Verificação de permissões** - Confirma execução como Administrador
2. **Download do instalador** - Baixa de URLs configuradas (com fallback)
3. **Instalação silenciosa** - Executa com parâmetros `/quiet /norestart`
4. **Tratamento de erros** - Try/Catch com logs detalhados
5. **Fallback manual** - Abre navegador se download falhar

### install/run-install.ps1

Script para execução remota que baixa e executa o script principal diretamente de uma URL.

```powershell
# Executar
.\install\run-install.ps1

# Ou direto
iex (iwr "https://raw.githubusercontent.com/assyst/assyst-vpn-automation/main/install/run-install.ps1")
```

## URLs de Download

O script tenta múltiplas fontes (ordem de prioridade):

| # | URL | Status |
|---|-----|--------|
| 1 | https://suporte.tjrn.jus.br/arquivos/vpn.exe | Primária |

> **Nota**: Adicione suas próprias URLs no array `$downloadUrls` dentro do script.

## Tecnologias

- **PowerShell 5.1+** - Linguagem principal
- **Windows Event Log** - Logging de auditoria
- **Invoke-WebRequest** - Download de arquivos

## Benefícios

- **Redução de tempo**: ~5 minutos por atendimento
- **Automação**: Sem intervenção manual do usuário
- **Consistência**: Instalação padronizada em todas as máquinas
- **Auditoria**: Logs de instalação no Event Viewer
- **Fallback**: Procedimento manual como backup

## Pré-requisitos

- Windows 10/11 ou Windows Server 2016+
- PowerShell 5.1+
- Permissão de Administrador
- Acesso à internet para download

## Configuração AWS S3 (Futuro)

O projeto está preparado para integração futura com AWS S3:

```powershell
# Estrutura planejada:
# s3://bucket-name/forticlient/FortiClientVPNSetup.exe
# s3://bucket-name/scripts/install-forticlient.ps1
```

Para habilitar, adicione o AWS Module no script.

## Extensibilidade

O projeto suporta adição de novos scripts de instalação:

```
scripts/
├── install-forticlient.ps1    # VPN
├── install-java.ps1          # Java (futuro)
├── install-printers.ps1       # Impressoras (futuro)
└── install-office.ps1         # Office (futuro)
```

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