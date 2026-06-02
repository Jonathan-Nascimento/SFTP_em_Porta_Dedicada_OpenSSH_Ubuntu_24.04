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

## 🔍 Como validar se funcionou

### ✅ Verificar serviço

```bash
systemctl status ssh-sftp
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
