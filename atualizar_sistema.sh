#!/bin/bash

# Script de atualização automática do sistema AssistPericias
# Executa a atualização do sistema com backup automático e rollback em caso de falha
# Versão: 1.0 - 08/05/2025

APP_DIR="/opt/assistpericias"
BACKUP_DIR="$APP_DIR/backups/sistema"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$APP_DIR/logs/atualizacao_$TIMESTAMP.log"

# Função para log
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

# Criar diretórios necessários
mkdir -p "$BACKUP_DIR"
mkdir -p "$APP_DIR/logs"

log "Iniciando processo de atualização do sistema AssistPericias"

# 1. Verificar estado atual do sistema
log "Verificando estado atual do sistema..."
pm2 describe assistpericias-web > /dev/null
if [ $? -ne 0 ]; then
  log "ERRO: O serviço não está em execução. Abortando atualização."
  exit 1
fi

# 2. Realizar backup completo do sistema
log "Criando backup completo do sistema..."
BACKUP_FILE="$BACKUP_DIR/sistema_$TIMESTAMP.tar.gz"
tar -czf "$BACKUP_FILE" -C "$APP_DIR" data src config
if [ $? -ne 0 ]; then
  log "ERRO: Falha ao criar backup. Abortando atualização."
  exit 1
fi
log "Backup criado com sucesso: $BACKUP_FILE"

# 3. Instalar dependências atualizadas
log "Atualizando dependências do sistema..."
cd "$APP_DIR"
npm update
if [ $? -ne 0 ]; then
  log "AVISO: Houve problemas ao atualizar dependências. Continuando mesmo assim..."
fi

# 4. Atualizar estrutura do banco de dados
log "Verificando atualizações no banco de dados..."
if [ -f "$APP_DIR/db_migrations.js" ]; then
  log "Executando migrações de banco de dados..."
  node "$APP_DIR/db_migrations.js"
  if [ $? -ne 0 ]; then
    log "ERRO: Falha nas migrações de banco de dados. Iniciando rollback..."
    rollback_db
    exit 1
  fi
fi

# 5. Reiniciar o serviço
log "Reiniciando o serviço..."
pm2 restart assistpericias-web
if [ $? -ne 0 ]; then
  log "ERRO: Falha ao reiniciar o serviço. Iniciando rollback..."
  rollback_system
  exit 1
fi

# 6. Verificar se o serviço está funcionando corretamente
sleep 5
log "Verificando funcionamento do serviço após atualização..."
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/)
if [ "$response" != "200" ] && [ "$response" != "302" ]; then
  log "ERRO: Serviço não está respondendo corretamente após atualização (HTTP $response). Iniciando rollback..."
  rollback_system
  exit 1
fi

log "Atualização concluída com sucesso!"
exit 0

# Função para rollback do sistema
rollback_system() {
  log "Iniciando rollback do sistema..."
  
  # Parar o serviço
  pm2 stop assistpericias-web
  
  # Restaurar a partir do backup
  log "Restaurando a partir do backup: $BACKUP_FILE"
  mkdir -p "$APP_DIR/rollback_temp"
  tar -xzf "$BACKUP_FILE" -C "$APP_DIR/rollback_temp"
  
  # Copiar arquivos de volta
  cp -r "$APP_DIR/rollback_temp/src" "$APP_DIR/"
  cp -r "$APP_DIR/rollback_temp/config" "$APP_DIR/"
  
  # Remover diretório temporário
  rm -rf "$APP_DIR/rollback_temp"
  
  # Reiniciar o serviço
  pm2 restart assistpericias-web
  
  log "Rollback concluído. O sistema foi restaurado para o estado anterior."
}

# Função para rollback do banco de dados
rollback_db() {
  log "Iniciando rollback do banco de dados..."
  
  # Restaurar arquivos de dados a partir do backup
  mkdir -p "$APP_DIR/rollback_temp"
  tar -xzf "$BACKUP_FILE" -C "$APP_DIR/rollback_temp"
  
  # Copiar arquivos de dados de volta
  cp -r "$APP_DIR/rollback_temp/data" "$APP_DIR/"
  
  # Remover diretório temporário
  rm -rf "$APP_DIR/rollback_temp"
  
  log "Rollback do banco de dados concluído."
}
