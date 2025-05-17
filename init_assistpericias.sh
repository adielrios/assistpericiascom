#!/bin/bash

# Script de inicialização automática do AssistPericias
# Versão: 2.0

# Definir variáveis
APP_DIR="$(pwd)"
LOG_FILE="$APP_DIR/logs/startup_$(date +%Y%m%d_%H%M%S).log"
DB_DIR="$APP_DIR/data"
CONFIG_DIR="$APP_DIR/config"

# Criar diretórios necessários
mkdir -p $APP_DIR/logs
mkdir -p $DB_DIR
mkdir -p $CONFIG_DIR

# Iniciar log
echo "$(date): Iniciando processo de inicialização do AssistPericias" | tee -a $LOG_FILE

# Verificar dependências
echo "$(date): Verificando dependências..." | tee -a $LOG_FILE
DEPS=("node" "npm" "pm2")
for dep in "${DEPS[@]}"; do
  if ! command -v $dep &> /dev/null; then
    echo "$(date): ERRO - Dependência não encontrada: $dep" | tee -a $LOG_FILE
    if [ "$dep" = "pm2" ]; then
      echo "$(date): Instalando PM2..." | tee -a $LOG_FILE
      npm install -g pm2
    else
      echo "$(date): Dependência crítica não encontrada: $dep. Por favor, instale e execute novamente." | tee -a $LOG_FILE
      exit 1
    fi
  fi
done

# Instalar dependências do projeto (se necessário)
echo "$(date): Verificando dependências do projeto..." | tee -a $LOG_FILE
if [ ! -d "$APP_DIR/node_modules" ]; then
  echo "$(date): Instalando dependências do projeto..." | tee -a $LOG_FILE
  cd $APP_DIR && npm install
fi

# Verificar arquivos de dados
echo "$(date): Verificando arquivos de dados..." | tee -a $LOG_FILE
DATA_FILES=("usuarios.json" "pericias.json" "processos.json" "tokens/12345.json")
for file in "${DATA_FILES[@]}"; do
  if [ ! -f "$DB_DIR/$file" ]; then
    echo "$(date): AVISO - Arquivo de dados não encontrado: $file" | tee -a $LOG_FILE
  else
    echo "$(date): Arquivo de dados verificado: $file" | tee -a $LOG_FILE
  fi
done

# Verificar integridade do sistema
echo "$(date): Verificando integridade do sistema..." | tee -a $LOG_FILE
if [ ! -f "$APP_DIR/src/startWebPanel.js" ]; then
  echo "$(date): ERRO - Arquivo principal não encontrado. O sistema pode não funcionar corretamente." | tee -a $LOG_FILE
else
  echo "$(date): Arquivo principal encontrado." | tee -a $LOG_FILE
fi

# Iniciar o serviço
echo "$(date): Iniciando o serviço AssistPericias..." | tee -a $LOG_FILE
cd $APP_DIR
pm2 describe assistpericias-web > /dev/null
if [ $? -eq 0 ]; then
  echo "$(date): Reiniciando serviço existente..." | tee -a $LOG_FILE
  pm2 restart assistpericias-web
else
  echo "$(date): Iniciando novo serviço..." | tee -a $LOG_FILE
  pm2 start src/startWebPanel.js --name assistpericias-web
fi
pm2 save

# Configurar inicialização automática para ambientes suportados
echo "$(date): Configurando inicialização automática..." | tee -a $LOG_FILE
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux
  pm2 startup | tail -n 1 > startup_command.sh
  chmod +x startup_command.sh
  ./startup_command.sh
  rm startup_command.sh
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  pm2 startup | tail -n 1 > startup_command.sh
  chmod +x startup_command.sh
  ./startup_command.sh
  rm startup_command.sh
  
  # Adicional para macOS: criar arquivo de inicialização do LaunchAgent
  LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
  mkdir -p "$LAUNCH_AGENT_DIR"
  
  cat > "$LAUNCH_AGENT_DIR/com.assistpericias.startup.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.assistpericias.startup</string>
    <key>ProgramArguments</key>
    <array>
        <string>sh</string>
        <string>-c</string>
        <string>cd $APP_DIR && ./init_assistpericias.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>StandardErrorPath</key>
    <string>$APP_DIR/logs/launchagent-error.log</string>
    <key>StandardOutPath</key>
    <string>$APP_DIR/logs/launchagent-out.log</string>
</dict>
</plist>
EOF
  
  # Carregar o LaunchAgent
  launchctl load "$LAUNCH_AGENT_DIR/com.assistpericias.startup.plist"
  echo "$(date): LaunchAgent para macOS configurado." | tee -a $LOG_FILE
fi

# Verificar status
echo "$(date): Verificando status do serviço..." | tee -a $LOG_FILE
pm2 status

# Configurar verificação diária
echo "$(date): Configurando verificação diária de integridade..." | tee -a $LOG_FILE
cat > $APP_DIR/healthcheck.sh << 'EOF'
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
EOF

chmod +x $APP_DIR/healthcheck.sh

# Adicionar verificação diária ao crontab para ambientes suportados
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux
  (crontab -l 2>/dev/null; echo "0 2 * * * $APP_DIR/healthcheck.sh") | crontab -
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  CRON_FILE="$APP_DIR/temp_crontab"
  crontab -l > "$CRON_FILE" 2>/dev/null || echo "" > "$CRON_FILE"
  
  # Verificar se a entrada já existe
  if ! grep -q "$APP_DIR/healthcheck.sh" "$CRON_FILE"; then
    echo "0 2 * * * $APP_DIR/healthcheck.sh" >> "$CRON_FILE"
    crontab "$CRON_FILE"
  fi
  
  rm "$CRON_FILE"
fi

echo "$(date): Sistema AssistPericias iniciado com sucesso!" | tee -a $LOG_FILE
echo "$(date): Acesse http://localhost:3000 e use o token '12345' para login." | tee -a $LOG_FILE
