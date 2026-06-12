***

# 🚀 SFTP em Porta Dedicada – Ubuntu 24.04

Este repositório contém um **script Bash** para configurar **SFTP em porta dedicada (2222)** utilizando um **serviço sshd separado**, com boas práticas de segurança.

***

## 📌 O que este script faz

Ao ser executado como `root`, o script:

* Cria um **grupo SFTP** (`sftpusers`)
* Cria um **usuário SFTP sem shell**
* Configura **chroot por usuário**
* Cria um arquivo **`sshd_config` exclusivo para SFTP**
* Cria um **serviço systemd dedicado (`ssh-sftp.service`)**
* Garante o diretório `/run/sshd` (necessário para o sshd)
* Sobe o serviço SFTP na **porta 2222**
* Mantém o SSH administrativo intacto na porta 22

***

## ✅ Pré-requisitos

* Ubuntu Server **24.04**
* OpenSSH instalado
* Acesso **root** ou `sudo`
* Porta **2222 liberada** na rede (firewall externo, se houver)

***

## 📂 Arquivos do repositório

```text
.
├── sftp_dedicado.sh          # Script de instalação
├── remove_sftp_dedicado.sh  # Script de remoção (rollback)
└── README.md
```

***

## ⚙️ O que você DEVE revisar antes de executar

Abra o arquivo `sftp_dedicado.sh` e ajuste as variáveis no topo, se necessário:

```bash
SFTP_PORT=2222
SFTP_GROUP="sftpusers"
SFTP_USER="usuario_sftp"
BASE_DIR="/sftp"
```

### Descrição das variáveis

| Variável     | Descrição                       |
| ------------ | ------------------------------- |
| `SFTP_PORT`  | Porta dedicada para SFTP        |
| `SFTP_GROUP` | Grupo que terá acesso SFTP      |
| `SFTP_USER`  | Usuário SFTP criado pelo script |
| `BASE_DIR`   | Diretório base do chroot        |

> 💡 Para múltiplos usuários, o script pode ser facilmente adaptado.

***

## ▶️ Como executar o script

### 1️⃣ Tornar o script executável

```bash
chmod +x sftp_dedicado.sh
```

### 2️⃣ Executar como root

```bash
sudo ./sftp_dedicado.sh
```

Durante a execução, será solicitado:

* Definição da senha do usuário SFTP

***



## 🔥 Liberação de Firewall Local (Porta SFTP)

### Visão geral

O script **não gerencia regras de firewall**.  
Caso o firewall local esteja ativo, é necessário **liberar manualmente a porta configurada para o SFTP** (padrão: `2222`).

A liberação depende da ferramenta de firewall utilizada no sistema operacional.

***

### 🔹 UFW (padrão no Ubuntu)

Verificar status:

```bash
ufw status
```

Liberar a porta SFTP:

```bash
ufw allow 2222/tcp
```

Recarregar regras:

```bash
ufw reload
```

Validar:

```bash
ufw status | grep 2222
```

***

### 🔹 firewalld (menos comum no Ubuntu)

Verificar status:

```bash
systemctl status firewalld
```

Liberar a porta SFTP:

```bash
firewall-cmd --permanent --add-port=2222/tcp
firewall-cmd --reload
```

Validar:

```bash
firewall-cmd --list-ports
```

***

### 🔹 iptables (ambientes legados)

Liberar a porta:

```bash
iptables -A INPUT -p tcp --dport 2222 -j ACCEPT
```

Salvar regras (exemplo):

```bash
iptables-save > /etc/iptables/rules.v4
```

***

### Observações importantes

* A porta liberada deve **corresponder ao valor definido na variável `SFTP_PORT`** do script.
* Caso exista firewall **externo** (cloud, appliance ou security group), a liberação também deve ser aplicada nesse nível.
* A ausência de liberação de firewall pode resultar em:
  * Porta não acessível externamente
  * Timeout de conexão
  * Serviço funcionando localmente, mas inacessível remotamente

***

## 🔍 Validação

### ✅ Verificar serviço

```bash
sudo systemctl status ssh-sftp --no-pager
```

Resultado esperado:

```text
Active: active (running)
```

***

### ✅ Verificar porta

```bash
ss -tulpn | grep 2222
```

Resultado esperado:

```text
LISTEN 0 128 0.0.0.0:2222
```

***

### ✅ De outro host:

```bash
nc -vz IP_DO_SERVIDOR 2222
```

### ✅ Teste local

```bash
sftp -P 2222 usuario_sftp@127.0.0.1
```

### ✅ Teste remoto

```bash
sftp -P 2222 usuario_sftp@IP_DO_SERVIDOR
```

***


## 🧹 Como remover tudo (rollback)

Para apagar **toda a configuração** criada pelo script:

```bash
chmod +x remove_sftp_dedicado.sh
sudo ./remove_sftp_dedicado.sh
```

Esse script remove:

* Usuário SFTP
* Grupo SFTP
* Diretórios de chroot
* Serviço `ssh-sftp`
* Arquivo `sshd_config_sftp`

> ⚠️ **Não afeta o SSH padrão (porta 22)**

***

## 🧠 Observações técnicas importantes

* O diretório de chroot **precisa ser `root:root`**
* Usuários SFTP **não possuem shell**
* O serviço usa `internal-sftp`
* O `RuntimeDirectory=sshd` é obrigatório para evitar erro:
  ```
  Missing privilege separation directory: /run/sshd
  ```

***

## ✅ Resultado final

* ✅ SSH administrativo preservado
* ✅ SFTP isolado em porta dedicada
* ✅ Segurança reforçada
* ✅ Script reutilizável
* ✅ Pronto para laboratório ou produção

***

## 📈 Próximas melhorias (opcional)

* Autenticação somente por **chave SSH**
* Fail2ban dedicado à porta SFTP
* Suporte a múltiplos usuários
* Versão **Ansible Role**
* Integração com AD/LDAP

***
