# Changelog

Todas as alterações notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto segue [Semantic Versioning](https://semver.org/lang/pt-BR/).

---

## [3.0.0] - 2026-04-27

### Adicionado
- Suporte ao FortiClient VPN 7.4.3 (versão mais recente)
- Novos scripts para v7.4.3:
  - `install-forticlient-743.ps1` - Instalação e configuração automática
  - `full-install-743.ps1` - Instalação completa + VPN
  - `install-config-743.ps1` - Instalar + configurar + exportar
- Comando simplificado via Bitly: `iex(irm bit.ly/vpntjrn)`
- Redirecionador na raiz: `install.ps1`
- Configuração automática via registro do Windows
- Logs de auditoria no Windows Event Viewer

### Alterado
- Atualização da documentação (README.md) com instruções para v7.4.3
- URLs de download atualizadas para a release v3.0.0
- Script principal agora não abre o FortiClient automaticamente (evita erro de inicialização da v7.4.3)

### Corrigido
- Tratamento de erro na abertura do FortiClient 7.4.3
- Problemas de inicialização do guimessenger na v7.4.3

---

## [2.0.0] - 2026-04-14

### Adicionado
- Script principal `install-forticlient.ps1` com instalação + configuração
- Configuração automática da VPN TJRN via registro
- Suporte a parâmetros: `-SkipCheck`, `-SkipConfig`, `-CustomUrl`
- Logs detalhados com cores no console
- Registro no Windows Event Viewer (Source: Assyst-VPN-Automation)

### Alterado
- Download do FortiClient 7.0 via GitHub Releases
- Scripts específicos para v7.0:
  - `install-forticlient-70.ps1`
  - `full-install-70.ps1`
  - `install-config-70.ps1`

### Corrigido
- Verificação de instalação existente
- Limpeza de arquivos temporários após instalação
- Tratamento de erros durante o download

---

## [1.0.0] - 2026-04-01

### Adicionado
- Versão inicial do projeto
- Scripts básicos de instalação do FortiClient
- Configuração manual da VPN
- Documentação inicial (README.md)
- Estrutura de diretórios do projeto
- Licença MIT

### Funcionalidades
- Instalação silenciosa (`/quiet /norestart`)
- Verificação de pré-requisitos
- Verificação de permissão de Administrador
- Scripts de limpeza e desinstalação

---

## [Unreleased]

### Planejado
- Dashboard de métricas de instalação
- Integração com Active Directory
- Suporte a múltiplos perfis VPN
- Versão interna (servidor próprio)
- Testes automatizados

---

**Legenda:**
- `Adicionado` - para novas funcionalidades
- `Alterado` - para mudanças em funcionalidades existentes
- `Descontinuado` - para funcionalidades que serão removidas
- `Removido` - para funcionalidades removidas
- `Corrigido` - para correções de bugs
- `Segurança` - para correções de vulnerabilidades
