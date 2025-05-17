#!/bin/bash

# Script de manutenção automatizada do sistema AssistPericias
# Executa tarefas de manutenção periódicas para garantir o bom funcionamento
# Versão: 1.0 - 08/05/2025

APP_DIR="/opt/assistpericias"
LOG_FILE="$APP_DIR/logs/manutencao_$(date +%Y%m%d).log"

# Função para log
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

# Criar diretório de logs
mkdir -p "$APP_DIR/logs"

log "Iniciando manutenção automatizada do sistema AssistPericias"

# 1. Verificar e limpar arquivos temporários
log "Verificando arquivos temporários..."
find "$APP_DIR/tmp" -type f -mtime +7 -delete 2>/dev/null
find "/tmp" -name "assistpericias-*" -type f -mtime +1 -delete 2>/dev/null

# 2. Otimizar arquivos de banco de dados
log "Otimizando arquivos de banco de dados..."
for file in $(find "$APP_DIR/data" -name "*.json" -type f); do
  filename=$(basename -- "$file")
  log "Otimizando $filename..."
  
  # Fazer backup do arquivo original
  cp "$file" "$file.bak"
  
  # Tentar otimizar (remover espaço em branco desnecessário)
  jq -c . "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  
  # Verificar se a otimização foi bem-sucedida
  if [ $? -ne 0 ]; then
    log "Erro ao otimizar $filename. Restaurando backup..."
    mv "$file.bak" "$file"
  else
    # Comparar tamanhos
    old_size=$(stat -c%s "$file.bak")
    new_size=$(stat -c%s "$file")
    saved=$(( (old_size - new_size) * 100 / old_size ))
    log "Arquivo $filename otimizado: $old_size -> $new_size bytes (economizou $saved%)"
    rm "$file.bak"
  fi
done

# 3. Verificar logs e rotacionar se necessário
log "Verificando logs do sistema..."
find "$APP_DIR/logs" -name "*.log" -type f -size +100M | while read logfile; do
  logname=$(basename -- "$logfile")
  log "Rotacionando log grande: $logname"
  mv "$logfile" "$logfile.$(date +%Y%m%d)"
  gzip "$logfile.$(date +%Y%m%d)"
done

# 4. Verificar integridade do PM2
log "Verificando integridade do PM2..."
pm2 ping > /dev/null
if [ $? -ne 0 ]; then
  log "PM2 não está respondendo. Tentando reiniciar..."
  pm2 kill
  sleep 2
  pm2 resurrect
  if [ $? -ne 0 ]; then
    log "Falha ao restaurar PM2. Iniciando serviços manualmente..."
    cd "$APP_DIR" && pm2 start src/startWebPanel.js --name assistpericias-web
    pm2 save
  fi
fi

# 5. Verificar atualizações do npm
log "Verificando atualizações de pacotes..."
cd "$APP_DIR"
outdated=$(npm outdated --json)
if [ -n "$outdated" ] && [ "$outdated" != "{}" ]; then
  log "Pacotes desatualizados encontrados:"
  echo "$outdated" | jq . | tee -a "$LOG_FILE"
  
  # Criar flag para notificar sobre atualizações disponíveis
  echo "$outdated" > "$APP_DIR/update_required"
else
  log "Todos os pacotes estão atualizados."
  rm -f "$APP_DIR/update_required"
fi

# 6. Limpar cache do npm se estiver muito grande
npm_cache_size=$(du -s $(npm config get cache) 2>/dev/null | awk '{print $1}')
if [ -n "$npm_cache_size" ] && [ $npm_cache_size -gt 1048576 ]; then # Maior que 1GB
  log "Cache do npm está muito grande ($npm_cache_size KB). Limpando..."
  npm cache clean --force
fi

# 7. Verificar e corrigir permissões
log "Verificando permissões de arquivos..."
find "$APP_DIR/src" -type f -name "*.js" -exec chmod 644 {} \;
find "$APP_DIR/src" -type d -exec chmod 755 {} \;
chmod -R 755 "$APP_DIR/node_modules/.bin" 2>/dev/null

# 8. Verificar espaço em disco
disk_usage=$(df -h / | awk 'NR==2{print $5}' | tr -d '%')
if [ $disk_usage -gt 90 ]; then
  log "ALERTA: Uso de disco muito alto ($disk_usage%). Iniciando limpeza..."
  
  # Limpar backups antigos
  find "$APP_DIR/backups" -type f -mtime +30 -delete
  
  # Limpar logs antigos
  find "$APP_DIR/logs" -type f -name "*.log.gz" -mtime +60 -delete
  
  # Verificar novamente
  new_disk_usage=$(df -h / | awk 'NR==2{print $5}' | tr -d '%')
  log "Uso de disco após limpeza: $new_disk_usage%"
fi

log "Manutenção automatizada concluída com sucesso!"
