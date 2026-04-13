<!-- omit in toc -->
# Runbook - Instalação FortiClient VPN

Guia passo a passo para técnicos de suporte.

## Cenário

Usuário precisa de VPN corporativa e o técnico está em suporte remoto via Assistência Rápida do Windows.

---

## Preparação

### 1. Iniciar Assistência Rápida

1. Abra o **Menu Iniciar** do Windows
2. Digite: `Assistência Rápida`
3. Clique em **Assistência Rápida do Windows**
4. Clique em **Ajudar**
5. Peça ao usuário para aceitar a solicitação

### 2. Validar Permissões

> IMPORTANTE: A instalação requer privilégios de administrador.

1. Na sessão de Assistência Rápida, clique em **Obter tela de controle**
2. Peça ao usuário para fornecer conta administrator OU
3. Use `runas` com credenciais administrativa

---

## Instalação Automatizada

### Passo 1: Abrir PowerShell como Administrador

1. No computador do usuário, abra o **Menu Iniciar**
2. Digite: `PowerShell`
3. **Clique direito** em "Windows PowerShell"
4. Selecione **Executar como administrador**

### Passo 2: Executar Script

Cole o seguinte comando no PowerShell:

```powershell
iex (iwr "https://raw.githubusercontent.com/assyst/assyst-vpn-automation/main/scripts/install-forticlient.ps1")
```

### Passo 3: Monitorar Instalação

Aguarde a instalação completar (~2-3 minutos). O script exibe logs em tempo real.

### Passo 4: Validar Sucesso

Verifique se a mensagem **"FortiClient VPN instalado com sucesso!"** aparece.

---

## Instalação Manual (Fallback)

Se o download automatizado falhar:

### 1. Abrir Navegador

1. Abra o Internet Explorer ou Edge
2. Acesse: `https://suporte.tjrn.jus.br/arquivos/vpn.exe`
3. Salve o arquivo

### 2. Executar Instalador

1. Clique direito no arquivo baixado
2. Selecione **Executar como administrador**
3. Aguarde instalação completar

### 3. Validar VPN

1. Abra Iniciar
2. Digite: `FortiClient`
3. Abra o aplicativo
4. Configure a VPN conforme orientações

---

## Validação Pós-Instalação

### Checklist

- [ ] Ícone do FortiClient aparece na área de trabalho
- [ ] FortiClient abre sem erros
- [ ] Usuário consegue configurar conexão VPN
- [ ] Conexão VPN é estabelecida com sucesso

### Teste de Conectividade

1. Abra o FortiClient
2. Configure a conexão com os dados fornecidos pelo usuário
3. Clique em "Conectar"
4. Verifique status "Conectado"

---

## Resolução de Problemas

### Problema: "Executar como Administrador"

**Solução**: O script pede privilégios administrativos. Peça credenciais ao usuário ou use conta administrator.

### Problema: "Download falhou"

**Solução**: Use o fallback manual (navegador) conforme instructions acima.

### Problema: "Instalação travou"

**Solução**:
1. Abra Gerenciador de Tarefas
2. Finalize processos FortiClient*
3. Reinicie o computador
4. Execute novamente

### Problema: "FortiClient não conecta"

**Solução**:
1. Verifique credenciais do usuário
2. Verifique configurações de rede
3. Confirme que o servidor VPN está acessível

---

## Comandos Úteis

### Verificar Instalação

```powershell
Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*FortiClient*"}
```

### Desinstalar

```powershell
# Via PowerShell
Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*FortiClient*"} | ForEach-Object { $_.Uninstall() }
```

### Verificar Serviços

```powershell
Get-Service | Where-Object {$_.DisplayName -like "*FortiClient*"}
```

---

## Informações para Registro

Após atendimento, registre:

| Campo | Valor |
|-------|-------|
| Ticket | [Nº do chamado] |
| Usuário | [Nome do usuário] |
| Máquina | [Nome do computador] |
| Método | Automatizado / Manual |
| Status | Sucesso / Falha |
| Tempo | [Duração] |

---

## Contato

Dúvidas durante atendimento:
- **Email**: suporte@assyst.com.br
- **Ramal**: 4000-1234

---

*Versão 1.0.0 - Atualizado em Abril/2026*