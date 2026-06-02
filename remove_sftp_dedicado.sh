#!/bin/bash
# =========================================================
# Script: remove_sftp_dedicado.sh
# Objetivo: Remover completamente o SFTP dedicado
# Ambiente: Ubuntu 24.04
# Execução: root
# =========================================================

set -e

SFTP_USER="usuario_sftp"
SFTP_GROUP="sftpusers"
BASE_DIR="/sftp"
SERVICE_NAME="ssh-sftp"

echo "==> Parando serviço ssh-sftp (se existir)"
systemctl stop ${SERVICE_NAME} 2>/dev/null || true
systemctl disable ${SERVICE_NAME} 2>/dev/null || true

echo "==> Removendo service file"
rm -f /etc/systemd/system/${SERVICE_NAME}.service

echo "==> Recarregando systemd"
systemctl daemon-reexec
systemctl daemon-reload

echo "==> Removendo arquivo sshd_config_sftp"
rm -f /etc/ssh/sshd_config_sftp

echo "==> Removendo diretórios de chroot"
rm -rf ${BASE_DIR}

echo "==> Removendo usuário SFTP"
id ${SFTP_USER} >/dev/null 2>&1 && userdel ${SFTP_USER} || true

echo "==> Removendo grupo SFTP"
getent group ${SFTP_GROUP} >/dev/null && groupdel ${SFTP_GROUP} || true

echo "==> Limpando diretório runtime (se existir)"
rm -rf /run/sshd

echo "✅ Remoção completa do SFTP dedicado finalizada"
