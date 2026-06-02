#!/bin/bash
# =========================================================
# Script: sftp_dedicado.sh
# Objetivo: Criar SFTP em porta dedicada (2222)
# Ambiente: Ubuntu 24.04
# Execução: root
# =========================================================

set -e

SFTP_PORT=2222
SFTP_GROUP="sftpusers"
SFTP_USER="usuario_sftp"
BASE_DIR="/sftp"

echo "==> Criando grupo SFTP"
getent group ${SFTP_GROUP} >/dev/null || groupadd ${SFTP_GROUP}

echo "==> Criando usuário SFTP"
id ${SFTP_USER} >/dev/null 2>&1 || useradd \
  -g ${SFTP_GROUP} \
  -d /upload \
  -s /usr/sbin/nologin \
  ${SFTP_USER}

echo "==> Definindo senha do usuário"
passwd ${SFTP_USER}

echo "==> Criando estrutura de diretórios (chroot)"
mkdir -p ${BASE_DIR}/${SFTP_USER}/upload

chown root:root ${BASE_DIR}/${SFTP_USER}
chmod 755 ${BASE_DIR}/${SFTP_USER}

chown ${SFTP_USER}:${SFTP_GROUP} ${BASE_DIR}/${SFTP_USER}/upload
chmod 750 ${BASE_DIR}/${SFTP_USER}/upload

echo "==> Criando sshd_config_sftp"
cat > /etc/ssh/sshd_config_sftp <<EOF
Port ${SFTP_PORT}
ListenAddress 0.0.0.0
Protocol 2

Subsystem sftp internal-sftp

PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
UsePAM yes

X11Forwarding no
AllowTcpForwarding no

Match Group ${SFTP_GROUP}
    ChrootDirectory ${BASE_DIR}/%u
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
EOF

echo "==> Garantindo diretório /run/sshd (privilege separation)"
mkdir -p /run/sshd
chmod 755 /run/sshd

echo "==> Criando serviço systemd ssh-sftp"
cat > /etc/systemd/system/ssh-sftp.service <<EOF
[Unit]
Description=OpenSSH SFTP Server (porta dedicada)
After=network.target

[Service]
RuntimeDirectory=sshd
RuntimeDirectoryMode=0755
ExecStart=/usr/sbin/sshd -D -f /etc/ssh/sshd_config_sftp
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "==> Recarregando systemd"
systemctl daemon-reexec
systemctl daemon-reload

echo "==> Validando configuração sshd"
sshd -t -f /etc/ssh/sshd_config_sftp

echo "==> Subindo serviço ssh-sftp"
systemctl enable ssh-sftp
systemctl restart ssh-sftp

echo "==> Status final"
systemctl status ssh-sftp --no-pager

echo "✅ SFTP dedicado configurado com sucesso na porta ${SFTP_PORT}"
