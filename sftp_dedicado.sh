#!/bin/bash

# Configurações - SFTP Dedicado
set -e # Aborta em caso de erro

SFTP_PORT=2222
SFTP_GROUP="sftpusers"
SFTP_USER="usuario_sftp"
BASE_DIR="/sftp"
USER_CHROOT="$BASE_DIR/$SFTP_USER"
UPLOAD_DIR="$USER_CHROOT/uploads"

# Cores para saída
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Iniciando configuração de SFTP em porta dedicada...${NC}"

# 1. Verificar se é root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Este script deve ser executado como root." 
   exit 1
fi

# 2. Criar grupo se não existir
if ! getent group "$SFTP_GROUP" > /dev/null; then
    groupadd "$SFTP_GROUP"
    echo -e "${GREEN}✅ Grupo $SFTP_GROUP criado.${NC}"
fi

# 3. Criar usuário sem shell, apontando o home para o chroot
if ! id "$SFTP_USER" &>/dev/null; then
    useradd -d "$USER_CHROOT" -m -g "$SFTP_GROUP" -s /bin/false "$SFTP_USER"
    echo -e "${YELLOW}Digite a senha para o novo usuário $SFTP_USER:${NC}"
    passwd "$SFTP_USER"
else
    echo -e "${YELLOW}⚠️ Usuário $SFTP_USER já existe. Pulando criação.${NC}"
fi

# 4. Configurar estrutura de diretórios e permissões (Chroot)
# O diretório de Chroot e seus pais DEVEM pertencer ao root para o sshd aceitar
mkdir -p "$BASE_DIR"
mkdir -p "$UPLOAD_DIR"
chown root:root "$BASE_DIR"
chown root:root "$USER_CHROOT"
chmod 755 "$USER_CHROOT"

# Diretório de upload onde o usuário terá escrita
chown "$SFTP_USER":"$SFTP_GROUP" "$UPLOAD_DIR"
chmod 775 "$UPLOAD_DIR"

echo -e "${GREEN}✅ Estrutura de diretórios configurada em $USER_CHROOT${NC}"

# 5. Criar arquivo de configuração SSH específico para SFTP
cat <<EOF > /etc/ssh/sshd_config_sftp
Port $SFTP_PORT
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Segurança básica
PermitRootLogin no
PasswordAuthentication yes
X11Forwarding no
AllowTcpForwarding no

# Configuração SFTP
Subsystem sftp internal-sftp

Match Group $SFTP_GROUP
    ChrootDirectory %h
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
EOF

# 6. Criar Unit no Systemd
cat <<EOF > /etc/systemd/system/ssh-sftp.service
[Unit]
Description=Serviço SFTP em Porta Dedicada
After=network.target

[Service]
ExecStartPre=/usr/bin/mkdir -p /run/sshd
ExecStart=/usr/sbin/sshd -D -f /etc/ssh/sshd_config_sftp
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
RuntimeDirectory=sshd

[Install]
WantedBy=multi-user.target
EOF

# 7. Ativar serviço
systemctl daemon-reload
systemctl enable ssh-sftp
systemctl restart ssh-sftp

echo -e "${GREEN}✅ SFTP configurado com sucesso na porta $SFTP_PORT!${NC}"
echo -e "${YELLOW}Dica: Teste com: sftp -P $SFTP_PORT $SFTP_USER@127.0.0.1${NC}"
echo -e "${YELLOW}Lembre-se de liberar a porta no seu firewall.${NC}"