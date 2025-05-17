#!/bin/bash

# Script de backup do sistema AssistPericias
APP_DIR="/opt/assistpericias"
BACKUP_DIR="/opt/backups/assistpericias"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/assistpericias_backup_$TIMESTAMP.tar.gz"

# Criar diretório de backup
mkdir -p $BACKUP_DIR

# Realizar backup dos dados
echo "Iniciando backup do sistema AssistPericias..."
tar -czf $BACKUP_FILE -C $APP_DIR data src config

# Verificar se o backup foi bem-sucedido
if [ $? -eq 0 ]; then
  echo "Backup criado com sucesso: $BACKUP_FILE"
  
  # Limpar backups antigos (manter apenas os últimos 7)
  echo "Removendo backups antigos..."
  find $BACKUP_DIR -name "assistpericias_backup_*.tar.gz" -type f -mtime +7 -delete
else
  echo "ERRO: Falha ao criar o backup."
fi

# Registrar o backup no log
echo "$(date): Backup $BACKUP_FILE criado" >> $APP_DIR/logs/backup.log
