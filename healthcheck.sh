#!/bin/bash
APP_DIR="$(pwd)"
LOG_FILE="$APP_DIR/logs/healthcheck_$(date +%Y%m%d).log"

echo "$(date): Iniciando verificação de integridade" >> $LOG_FILE

# Verificar se o serviço está em execução
pm2 describe assistpericias-web > /dev/null
if [ $? -ne 0 ]; then
  echo "$(date): ALERTA - Serviço não está em execução. Tentando reiniciar..." >> $LOG_FILE
  cd $APP_DIR && pm2 start src/startWebPanel.js --name assistpericias-web
fi

# Verificar se o serviço está respondendo
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/)
if [ "$response" != "200" ] && [ "$response" != "302" ]; then
  echo "$(date): ALERTA - Serviço não está respondendo. Tentando reiniciar..." >> $LOG_FILE
  cd $APP_DIR && pm2 restart assistpericias-web
fi

echo "$(date): Verificação de integridade concluída" >> $LOG_FILE
