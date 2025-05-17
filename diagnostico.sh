#!/bin/bash

# Script de diagnóstico do sistema AssistPericias
APP_DIR="/opt/assistpericias"
LOG_FILE="$APP_DIR/logs/diagnostico_$(date +%Y%m%d_%H%M%S).log"

# Iniciar o log
echo "====== DIAGNÓSTICO DO SISTEMA ASSISTPERICIAS ======" | tee -a $LOG_FILE
echo "Data e hora: $(date)" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Verificar status do serviço
echo "== Status do serviço ==" | tee -a $LOG_FILE
pm2 describe assistpericias-web | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Verificar uso de recursos
echo "== Uso de recursos ==" | tee -a $LOG_FILE
echo "Uso de CPU:" | tee -a $LOG_FILE
top -b -n 1 | grep "assistpericias" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

echo "Uso de memória:" | tee -a $LOG_FILE
free -m | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

echo "Uso de disco:" | tee -a $LOG_FILE
df -h | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Verificar arquivos de dados
echo "== Arquivos de dados ==" | tee -a $LOG_FILE
for file in "$APP_DIR/data"/*.json; do
  if [ -f "$file" ]; then
    filename=$(basename -- "$file")
    filesize=$(stat -c%s "$file")
    echo "$filename: $filesize bytes" | tee -a $LOG_FILE
  fi
done
echo "" | tee -a $LOG_FILE

# Verificar últimos logs
echo "== Últimos logs ==" | tee -a $LOG_FILE
tail -n 20 $(find $APP_DIR/logs -type f -name "*.log" | sort -r | head -1) | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Verificar conectividade
echo "== Teste de conectividade ==" | tee -a $LOG_FILE
curl -s -o /dev/null -w "Status code: %{http_code}\n" http://localhost:3000/ | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

echo "====== FIM DO DIAGNÓSTICO ======" | tee -a $LOG_FILE
echo "Log completo salvo em: $LOG_FILE"
