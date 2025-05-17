#!/bin/bash

# Monitor avançado para o sistema AssistPericias
# Versão: 1.0 - 08/05/2025

APP_DIR="/opt/assistpericias"
LOG_DIR="$APP_DIR/logs"
ALERT_LOG="$LOG_DIR/alertas_$(date +%Y%m%d).log"
CONFIG_DIR="$APP_DIR/config"

# Criar diretórios necessários
mkdir -p $LOG_DIR
mkdir -p $CONFIG_DIR

# Função para registro de logs
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$ALERT_LOG"
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

# Carregar configurações (criar arquivo padrão se não existir)
if [ ! -f "$CONFIG_DIR/monitor_config.sh" ]; then
  log "Criando arquivo de configuração padrão..."
  mkdir -p $CONFIG_DIR
  cat > "$CONFIG_DIR/monitor_config.sh" << 'EOF'
# Configurações do monitor
CHECK_INTERVAL=300  # Em segundos (5 minutos)
CPU_THRESHOLD=80    # Porcentagem
MEM_THRESHOLD=80    # Porcentagem
DISK_THRESHOLD=90   # Porcentagem
MAX_RESTART_ATTEMPTS=3
NOTIFY_EMAIL="adiel@assistpericias.com.br"
EOF
fi

# Incluir arquivo de configuração
source "$CONFIG_DIR/monitor_config.sh"

# Verificar status do serviço
check_service() {
  log "Verificando status do serviço..."
  
  pm2 describe assistpericias-web > /dev/null
  if [ $? -ne 0 ]; then
    log "ALERTA: Serviço não está em execução! Tentando reiniciar..."
    restart_attempts=0
    
    while [ $restart_attempts -lt $MAX_RESTART_ATTEMPTS ]; do
      cd $APP_DIR && pm2 start src/startWebPanel.js --name assistpericias-web
      
      # Verificar se reiniciou com sucesso
      sleep 5
      pm2 describe assistpericias-web > /dev/null
      if [ $? -eq 0 ]; then
        log "Serviço reiniciado com sucesso!"
        pm2 save
        return 0
      fi
      
      restart_attempts=$((restart_attempts + 1))
      log "Tentativa $restart_attempts de $MAX_RESTART_ATTEMPTS falhou. Tentando novamente..."
      sleep 10
    done
    
    log "CRÍTICO: Não foi possível reiniciar o serviço após $MAX_RESTART_ATTEMPTS tentativas!"
    send_alert "Falha crítica no serviço AssistPericias" "O serviço não pôde ser reiniciado após $MAX_RESTART_ATTEMPTS tentativas."
    return 1
  else
    # Verificar status específico no PM2
    status=$(pm2 jlist | grep assistpericias-web -A 10 | grep status | head -1 | awk -F'"' '{print $4}')
    if [ "$status" != "online" ]; then
      log "ALERTA: Serviço está em estado anormal: $status. Tentando reiniciar..."
      cd $APP_DIR && pm2 restart assistpericias-web
      sleep 5
      
      # Verificar novamente
      new_status=$(pm2 jlist | grep assistpericias-web -A 10 | grep status | head -1 | awk -F'"' '{print $4}')
      if [ "$new_status" != "online" ]; then
        log "CRÍTICO: Serviço ainda em estado anormal após reinício: $new_status"
        send_alert "Estado anormal do serviço" "O serviço AssistPericias está em estado: $new_status"
      else
        log "Serviço restaurado para estado online."
      fi
    else
      log "Serviço está rodando normalmente."
    fi
  fi
}

# Verificar uso de recursos
check_resources() {
  log "Verificando uso de recursos..."
  
  # Verificar CPU
  cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
  cpu_usage_int=${cpu_usage%.*}
  
  if [ $cpu_usage_int -gt $CPU_THRESHOLD ]; then
    log "ALERTA: Uso de CPU alto: $cpu_usage%"
    send_alert "Uso elevado de CPU" "O uso atual de CPU é de $cpu_usage%, acima do limite de $CPU_THRESHOLD%."
  fi
  
  # Verificar memória
  mem_total=$(free -m | awk 'NR==2{print $2}')
  mem_used=$(free -m | awk 'NR==2{print $3}')
  mem_usage=$(echo "scale=2; $mem_used * 100 / $mem_total" | bc)
  mem_usage_int=${mem_usage%.*}
  
  if [ $mem_usage_int -gt $MEM_THRESHOLD ]; then
    log "ALERTA: Uso de memória alto: $mem_usage%"
    send_alert "Uso elevado de memória" "O uso atual de memória é de $mem_usage%, acima do limite de $MEM_THRESHOLD%."
  fi
  
  # Verificar disco
  disk_usage=$(df -h / | awk 'NR==2{print $5}' | tr -d '%')
  
  if [ $disk_usage -gt $DISK_THRESHOLD ]; then
    log "ALERTA: Uso de disco alto: $disk_usage%"
    send_alert "Uso elevado de disco" "O uso atual de disco é de $disk_usage%, acima do limite de $DISK_THRESHOLD%."
  fi
}

# Verificar integridade do banco de dados
check_database() {
  log "Verificando integridade do banco de dados..."
  
  for file in $(find $APP_DIR/data -name "*.json"); do
    if [ -f "$file" ]; then
      filename=$(basename -- "$file")
      
      # Verificar se é um JSON válido
      jq . "$file" > /dev/null 2>&1
      if [ $? -ne 0 ]; then
        log "ALERTA: Arquivo $filename está corrompido!"
        
        # Tentar recuperar do backup
        backup_file=$(find $APP_DIR/data/backups -name "${filename%.json}_*.json" | sort -r | head -1)
        if [ -n "$backup_file" ]; then
          log "Tentando restaurar a partir do backup: $backup_file"
          cp "$backup_file" "$file"
          
          # Verificar novamente
          jq . "$file" > /dev/null 2>&1
          if [ $? -eq 0 ]; then
            log "Arquivo restaurado com sucesso a partir do backup."
          else
            log "CRÍTICO: Não foi possível restaurar o arquivo a partir do backup!"
            send_alert "Corrupção de banco de dados" "O arquivo $filename está corrompido e não pôde ser restaurado."
          fi
        else
          log "CRÍTICO: Não há backup disponível para restauração!"
          send_alert "Corrupção de banco de dados" "O arquivo $filename está corrompido e não há backup disponível."
        fi
      fi
    fi
  done
}

# Verificar conectividade
check_connectivity() {
  log "Verificando conectividade do serviço..."
  
  response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/)
  if [ "$response" != "200" ] && [ "$response" != "302" ]; then
    log "ALERTA: Serviço não está respondendo corretamente (HTTP $response)"
    
    # Verificar logs para erros recentes
    recent_errors=$(tail -n 100 "$LOG_DIR/app.log" 2>/dev/null | grep -i "error\|exception\|fail" | tail -5)
    
    send_alert "Falha de conectividade" "O serviço não está respondendo corretamente (HTTP $response). Erros recentes: $recent_errors"
    
    # Tentar reiniciar o serviço
    log "Tentando reiniciar o serviço..."
    cd $APP_DIR && pm2 restart assistpericias-web
    
    # Verificar novamente após reinício
    sleep 5
    new_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/)
    if [ "$new_response" != "200" ] && [ "$new_response" != "302" ]; then
      log "CRÍTICO: Serviço continua não respondendo após reinício (HTTP $new_response)"
    else
      log "Serviço restaurado, agora respondendo com HTTP $new_response"
    fi
  else
    log "Serviço está respondendo normalmente (HTTP $response)"
  fi
}

# Verificar espaço em disco para logs
check_log_space() {
  log "Verificando espaço em disco para logs..."
  
  log_size=$(du -s $LOG_DIR | awk '{print $1}')
  
  # Se o tamanho dos logs exceder 1GB (1048576 KB)
  if [ $log_size -gt 1048576 ]; then
    log "ALERTA: Diretório de logs está muito grande ($log_size KB). Rotacionando logs antigos..."
    
    # Encontrar e comprimir logs com mais de 7 dias
    find $LOG_DIR -name "*.log" -type f -mtime +7 | while read logfile; do
      if [ ! -f "$logfile.gz" ]; then
        log "Comprimindo log antigo: $logfile"
        gzip -9 "$logfile"
      fi
    done
    
    # Remover logs comprimidos com mais de 30 dias
    find $LOG_DIR -name "*.log.gz" -type f -mtime +30 -delete
    
    # Calcular novo tamanho após limpeza
    new_log_size=$(du -s $LOG_DIR | awk '{print $1}')
    log "Tamanho do diretório de logs reduzido de $log_size KB para $new_log_size KB"
  fi
}

# Enviar alerta (por email ou outro método)
send_alert() {
  local subject="$1"
  local message="$2"
  
  log "Enviando alerta: $subject - $message"
  
  # Registrar alerta em arquivo separado
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $subject: $message" >> "$LOG_DIR/alertas_criticos.log"
  
  # Enviar por email, se configurado
  if [ -n "$NOTIFY_EMAIL" ]; then
    echo "$message" | mail -s "[AssistPericias] $subject" "$NOTIFY_EMAIL"
  fi
}

# Verificar atualizações pendentes
check_updates() {
  log "Verificando atualizações pendentes..."
  
  # Verificar se existe arquivo de flag de atualização
  if [ -f "$APP_DIR/update_required" ]; then
    update_info=$(cat "$APP_DIR/update_required")
    log "Atualização pendente detectada: $update_info"
    send_alert "Atualização pendente" "Uma atualização está pendente para o sistema AssistPericias: $update_info"
  fi
}

# Executar todas as verificações
log "Iniciando monitormento avançado do sistema AssistPericias"
check_service
check_resources
check_database
check_connectivity
check_log_space
check_updates
log "Monitoramento concluído"

# Criar arquivo de estado para rastreamento
echo "$(date +"%Y-%m-%d %H:%M:%S")" > "$LOG_DIR/last_monitor_check"
