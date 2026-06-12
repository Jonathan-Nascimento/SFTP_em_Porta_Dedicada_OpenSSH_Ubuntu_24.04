#!/bin/bash

SFTP_USER="usuario_sftp"
SFTP_GROUP="sftpusers"
BASE_DIR="/sftp"

echo "🧹 Iniciando remoção da configuração SFTP dedicada..."

if [[ $EUID -ne 0 ]]; then
   echo "❌ Execute como root." 
   exit 1
fi

# 1. Parar e remover serviço
echo "Parando serviço ssh-sftp..."
systemctl stop ssh-sftp || true
systemctl disable ssh-sftp || true
[ -f /etc/systemd/system/ssh-sftp.service ] && rm -f /etc/systemd/system/ssh-sftp.service
systemctl daemon-reload

# 2. Remover arquivos de configuração
rm -f /etc/ssh/sshd_config_sftp

# 3. Remover usuário e grupo
echo "Removendo usuário e grupo..."
userdel -r "$SFTP_USER" || echo "Usuário já removido."

# Verificar se o grupo ainda existe e se está vazio antes de remover
if getent group "$SFTP_GROUP" > /dev/null; then
    groupdel "$SFTP_GROUP"
fi

# 4. Limpar diretórios
if [ -d "$BASE_DIR" ]; then
    echo "Removendo diretório base $BASE_DIR..."
    rm -rf "$BASE_DIR"
fi

echo "✅ Remoção concluída com sucesso."
echo "O serviço SSH padrão na porta 22 continua operando normalmente."