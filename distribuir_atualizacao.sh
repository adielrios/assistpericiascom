#!/bin/bash

# Script para distribuição de atualizações para múltiplos clientes
# Versão: 1.0 - 08/05/2025

VERSION="1.0.5"
RELEASE_NOTES="Melhorias de desempenho e correções de bugs"
PACKAGE_FILE="/opt/assistpericias/releases/assistpericias-${VERSION}.tar.gz"
CLIENTS_FILE="/opt/assistpericias/config/clients.txt"
LOG_FILE="/opt/assistpericias/logs/distribuicao_$(date +%Y%m%d).log"

# Função para log
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

# Criar diretórios necessários
mkdir -p "/opt/assistpericias/releases"
mkdir -p "/opt/assistpericias/logs"

# Verificar se o arquivo de clientes existe
if [ ! -f "$CLIENTS_FILE" ]; then
  log "Arquivo de clientes não encontrado. Criando arquivo de exemplo..."
  mkdir -p "$(dirname "$CLIENTS_FILE")"
  echo "# Lista de clientes para distribuição de atualizações" > "$CLIENTS_FILE"
  echo "# Formato: hostname,username,porta_ssh" >> "$CLIENTS_FILE"
  echo "cliente1.example.com,admin,22" >> "$CLIENTS_FILE"
  echo "cliente2.example.com,admin,22" >> "$CLIENTS_FILE"
  log "Arquivo de clientes criado. Por favor, edite $CLIENTS_FILE com os dados reais dos clientes."
  exit 1
fi

# Criar pacote de atualização
log "Criando pacote de atualização versão $VERSION..."
if [ ! -f "$PACKAGE_FILE" ]; then
  cd /opt/assistpericias
  tar -czf "$PACKAGE_FILE" --exclude="node_modules" --exclude="data" --exclude="logs" --exclude="backups" --exclude="tmp" --exclude=".git" --exclude="releases" .
  if [ $? -ne 0 ]; then
    log "ERRO: Falha ao criar pacote de atualização."
    exit 1
  fi
  log "Pacote de atualização criado: $PACKAGE_FILE"
else
  log "Pacote de atualização já existe. Usando o existente."
fi

# Criar script de atualização remota
REMOTE_SCRIPT="/tmp/assistpericias_update.sh"
cat > "$REMOTE_SCRIPT" << EOF
#!/bin/bash

# Script de atualização remota do AssistPericias
# Versão: $VERSION

APP_DIR="/opt/assistpericias"
BACKUP_DIR="\$APP_DIR/backups/sistema"
TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
LOG_FILE="\$APP_DIR/logs/atualizacao_remota_\$TIMESTAMP.log"

# Função para log
log() {
  echo "\$(date +"%Y-%m-%d %H:%M:%S") - \$1" | tee -a "\$LOG_FILE"
}

# Criar diretórios necessários
mkdir -p "\$BACKUP_DIR"
mkdir -p "\$APP_DIR/logs"

log "Iniciando atualização remota para versão $VERSION"
log "Notas da versão: $RELEASE_NOTES"

# 1. Criar backup do sistema atual
log "Criando backup do sistema atual..."
BACKUP_FILE="\$BACKUP_DIR/sistema_antes_atualizacao_\$TIMESTAMP.tar.gz"
tar -czf "\$BACKUP_FILE" -C "\$APP_DIR" --exclude="node_modules" --exclude="logs" --exclude="backups" --exclude="tmp" .
if [ \$? -ne 0 ]; then
  log "ERRO: Falha ao criar backup. Abortando atualização."
  exit 1
fi
log "Backup criado: \$BACKUP_FILE"

# 2. Extrair pacote de atualização
log "Extraindo pacote de atualização..."
mkdir -p "\$APP_DIR/tmp/update_\$TIMESTAMP"
tar -xzf "/tmp/assistpericias-${VERSION}.tar.gz" -C "\$APP_DIR/tmp/update_\$TIMESTAMP"
if [ \$? -ne 0 ]; then
  log "ERRO: Falha ao extrair pacote de atualização. Abortando."
  rm -rf "\$APP_DIR/tmp/update_\$TIMESTAMP"
  exit 1
fi

# 3. Fazer backup dos arquivos que serão sobrescritos
log "Fazendo backup dos arquivos que serão atualizados..."
find "\$APP_DIR/tmp/update_\$TIMESTAMP" -type f | while read file; do
  rel_path=\${file#\$APP_DIR/tmp/update_\$TIMESTAMP/}
  if [ -f "\$APP_DIR/\$rel_path" ]; then
    mkdir -p "\$(dirname "\$APP_DIR/tmp/backup_\$TIMESTAMP/\$rel_path")"
    cp "\$APP_DIR/\$rel_path" "\$APP_DIR/tmp/backup_\$TIMESTAMP/\$rel_path"
  fi
done

# 4. Parar o serviço
log "Parando o serviço AssistPericias..."
pm2 stop assistpericias-web

# 5. Copiar arquivos atualizados
log "Copiando arquivos atualizados..."
cp -r "\$APP_DIR/tmp/update_\$TIMESTAMP"/* "\$APP_DIR/"

# 6. Executar migrações de banco de dados se necessário
if [ -f "\$APP_DIR/db_migrations.js" ]; then
  log "Executando migrações de banco de dados..."
  node "\$APP_DIR/db_migrations.js"
  if [ \$? -ne 0 ]; then
    log "ERRO: Falha nas migrações de banco de dados. Iniciando rollback..."
    cp -r "\$APP_DIR/tmp/backup_\$TIMESTAMP"/* "\$APP_DIR/"
    pm2 restart assistpericias-web
    log "Rollback concluído. O sistema foi restaurado."
    rm -rf "\$APP_DIR/tmp/update_\$TIMESTAMP" "\$APP_DIR/tmp/backup_\$TIMESTAMP"
    exit 1
  fi
fi

# 7. Atualizar dependências
log "Atualizando dependências..."
cd "\$APP_DIR" && npm install --production
if [ \$? -ne 0 ]; then
  log "AVISO: Houve problemas ao atualizar dependências, mas continuando mesmo assim..."
fi

# 8. Reiniciar o serviço
log "Reiniciando o serviço..."
pm2 restart assistpericias-web
sleep 5

# 9. Verificar se o serviço está respondendo
response=\$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ 2>/dev/null)
if [ "\$response" != "200" ] && [ "\$response" != "302" ]; then
  log "ERRO: Serviço não está respondendo após atualização (HTTP \$response). Iniciando rollback..."
  cp -r "\$APP_DIR/tmp/backup_\$TIMESTAMP"/* "\$APP_DIR/"
  pm2 restart assistpericias-web
  log "Rollback concluído. O sistema foi restaurado."
  rm -rf "\$APP_DIR/tmp/update_\$TIMESTAMP" "\$APP_DIR/tmp/backup_\$TIMESTAMP"
  exit 1
fi

# 10. Limpar arquivos temporários
log "Limpando arquivos temporários..."
rm -rf "\$APP_DIR/tmp/update_\$TIMESTAMP" "\$APP_DIR/tmp/backup_\$TIMESTAMP"

log "Atualização concluída com sucesso para versão $VERSION!"
exit 0
EOF

chmod +x "$REMOTE_SCRIPT"

# Distribuir atualização para cada cliente
log "Iniciando distribuição da atualização para clientes..."

while IFS=, read -r hostname username port || [[ -n "$hostname" ]]; do
  # Ignorar linhas de comentário
  [[ "$hostname" =~ ^#.*$ ]] && continue
  
  log "Processando cliente: $hostname"
  
  # Verificar se é possível conectar ao servidor
  ssh -p "$port" "$username@$hostname" "echo 'Conexão OK'" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    log "ERRO: Não foi possível conectar ao servidor $hostname. Pulando..."
    continue
  fi
  
  # Enviar pacote de atualização
  log "Enviando pacote de atualização para $hostname..."
  scp -P "$port" "$PACKAGE_FILE" "$username@$hostname:/tmp/assistpericias-${VERSION}.tar.gz"
  if [ $? -ne 0 ]; then
    log "ERRO: Falha ao enviar pacote para $hostname. Pulando..."
    continue
  fi
  
  # Enviar script de atualização
  log "Enviando script de atualização para $hostname..."
  scp -P "$port" "$REMOTE_SCRIPT" "$username@$hostname:/tmp/assistpericias_update.sh"
  if [ $? -ne 0 ]; then
    log "ERRO: Falha ao enviar script para $hostname. Pulando..."
    continue
  fi
  
  # Executar atualização remota
  log "Executando atualização em $hostname..."
  ssh -p "$port" "$username@$hostname" "chmod +x /tmp/assistpericias_update.sh && /tmp/assistpericias_update.sh"
  if [ $? -ne 0 ]; then
    log "ERRO: Falha durante a atualização em $hostname."
  else
    log "Atualização concluída com sucesso em $hostname!"
  fi
done < "$CLIENTS_FILE"

rm -f "$REMOTE_SCRIPT"
log "Distribuição de atualizações concluída!"
