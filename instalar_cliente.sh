#!/bin/bash

# Script para instalação automática do AssistPericias em novos clientes
# Versão: 1.0 - 08/05/2025

VERSION="1.0.5"
PACKAGE_FILE="/opt/assistpericias/releases/assistpericias-${VERSION}.tar.gz"
CONFIG_FILE="/opt/assistpericias/config/install_config.json"
LOG_FILE="/opt/assistpericias/logs/instalacao_$(date +%Y%m%d).log"

# Função para log
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

# Verificar parâmetros
if [ $# -lt 3 ]; then
  echo "Uso: $0 <hostname> <username> <porta_ssh> [opcoes]"
  echo "Opções:"
  echo "  --token=TOKEN      Token de acesso personalizado (opcional)"
  echo "  --email=EMAIL      Email para notificações (opcional)"
  echo "  --nome=NOME        Nome do médico (opcional)"
  exit 1
fi

HOSTNAME="$1"
USERNAME="$2"
PORT="$3"
shift 3

# Processar opções
TOKEN="12345"  # Token padrão
EMAIL="adiel@assistpericias.com.br"  # Email padrão
NOME="Dr. Adiel Carneiro Rios"  # Nome padrão

for i in "$@"; do
  case $i in
    --token=*)
      TOKEN="${i#*=}"
      ;;
    --email=*)
      EMAIL="${i#*=}"
      ;;
    --nome=*)
      NOME="${i#*=}"
      ;;
    *)
      echo "Opção desconhecida: $i"
      exit 1
      ;;
  esac
done

# Criar diretórios necessários
mkdir -p "/opt/assistpericias/releases"
mkdir -p "/opt/assistpericias/logs"

# Verificar se o pacote existe
if [ ! -f "$PACKAGE_FILE" ]; then
  log "Pacote de instalação não encontrado. Criando pacote..."
  cd /opt/assistpericias
  tar -czf "$PACKAGE_FILE" --exclude="node_modules" --exclude="data" --exclude="logs" --exclude="backups" --exclude="tmp" --exclude=".git" --exclude="releases" .
  if [ $? -ne 0 ]; then
    log "ERRO: Falha ao criar pacote de instalação."
    exit 1
  fi
  log "Pacote de instalação criado: $PACKAGE_FILE"
fi

# Criar script de instalação remota
INSTALL_SCRIPT="/tmp/assistpericias_install.sh"
cat > "$INSTALL_SCRIPT" << EOF
#!/bin/bash

# Script de instalação remota do AssistPericias
# Versão: $VERSION

APP_DIR="/opt/assistpericias"
LOG_DIR="\$APP_DIR/logs"
LOG_FILE="\$LOG_DIR/instalacao_\$(date +%Y%m%d_%H%M%S).log"

# Função para log
log() {
  echo "\$(date +"%Y-%m-%d %H:%M:%S") - \$1" | tee -a "\$LOG_FILE"
}

# Verificar se está rodando como root
if [ "\$(id -u)" -ne 0 ]; then
  echo "Este script deve ser executado como root."
  exit 1
fi

# Criar diretórios necessários
mkdir -p "\$APP_DIR"
mkdir -p "\$LOG_DIR"

log "Iniciando instalação do AssistPericias versão $VERSION"

# 1. Verificar dependências
log "Verificando dependências do sistema..."
DEPS=("nodejs" "npm" "curl" "git")
INSTALAR=""

for dep in "\${DEPS[@]}"; do
  if ! command -v \$dep &> /dev/null; then
    INSTALAR="\$INSTALAR \$dep"
  fi
done

if [ -n "\$INSTALAR" ]; then
  log "Instalando dependências:\$INSTALAR"
  apt-get update
  apt-get install -y \$INSTALAR
  if [ \$? -ne 0 ]; then
    log "ERRO: Falha ao instalar dependências. Abortando."
    exit 1
  fi
fi

# Verificar versão do Node.js
NODE_VERSION=\$(node -v | cut -d'v' -f2)
NODE_MAJOR=\$(echo \$NODE_VERSION | cut -d'.' -f1)
if [ "\$NODE_MAJOR" -lt 14 ]; then
  log "Versão do Node.js (\$NODE_VERSION) é antiga. Instalando versão mais recente..."
  curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
  apt-get install -y nodejs
  if [ \$? -ne 0 ]; then
    log "ERRO: Falha ao atualizar o Node.js. Abortando."
    exit 1
  fi
fi

# Instalar PM2 globalmente
log "Instalando PM2..."
npm install -g pm2
if [ \$? -ne 0 ]; then
  log "ERRO: Falha ao instalar PM2. Abortando."
  exit 1
fi

# 2. Extrair pacote
log "Extraindo pacote de instalação..."
tar -xzf "/tmp/assistpericias-${VERSION}.tar.gz" -C "\$APP_DIR"
if [ \$? -ne 0 ]; then
  log "ERRO: Falha ao extrair pacote. Abortando."
  exit 1
fi

# 3. Configurar diretórios e permissões
log "Configurando diretórios e permissões..."
mkdir -p "\$APP_DIR/data/tokens"
mkdir -p "\$APP_DIR/data/backups"
mkdir -p "\$APP_DIR/tmp"
mkdir -p "\$APP_DIR/config"
chmod -R 755 "\$APP_DIR"

# 4. Criar token de acesso
log "Criando token de acesso..."
cat > "\$APP_DIR/data/tokens/$TOKEN.json" << 'TOKENEOF'
{
  "token": "$TOKEN",
  "user": {
    "id": 1,
    "nome": "$NOME",
    "email": "$EMAIL",
    "role": "admin",
    "crm": "138355"
  },
  "createdAt": $(date +%s000),
  "expiresAt": 4070908800000
}
TOKENEOF

# 5. Instalar dependências do projeto
log "Instalando dependências do projeto..."
cd "\$APP_DIR" && npm install --production
if [ \$? -ne 0 ]; then
  log "AVISO: Problemas ao instalar dependências, mas continuando mesmo assim..."
fi

# 6. Configurar inicialização automática
log "Configurando inicialização automática..."
pm2 start "\$APP_DIR/src/startWebPanel.js" --name assistpericias-web
pm2 save
pm2 startup | tail -n 1 > startup_command.sh
chmod +x startup_command.sh
./startup_command.sh
rm startup_command.sh

# 7. Configurar nginx (se disponível)
if command -v nginx &> /dev/null; then
  log "Configurando nginx como proxy reverso..."
  NGINX_CONF="/etc/nginx/sites-available/assistpericias"
  
  cat > "\$NGINX_CONF" << 'NGINXEOF'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
NGINXEOF

  ln -sf "\$NGINX_CONF" "/etc/nginx/sites-enabled/assistpericias"
  systemctl restart nginx
fi

# 8. Configurar firewall (se ufw estiver disponível)
if command -v ufw &> /dev/null; then
  log "Configurando firewall..."
  ufw allow 3000/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
fi

# 9. Criar dados de exemplo
log "Criando dados de exemplo..."
cat > "\$APP_DIR/data/usuarios.json" << 'EOF'
[
  {
    "id": 1,
    "nome": "$NOME",
    "email": "$EMAIL",
    "role": "admin",
    "crm": "138355"
  }
]
EOF

cat > "\$APP_DIR/data/pericias.json" << 'EOF'
[
  {
    "id": 1,
    "processoId": 1,
    "paciente": "João Silva",
    "data": "2025-05-10",
    "hora": "14:30",
    "local": "Consultório - Av. Paulista, 1000",
    "status": "Agendada",
    "tipo": "Ortopédica"
  },
  {
    "id": 2,
    "processoId": 2,
    "paciente": "Maria Oliveira",
    "data": "2025-05-15",
    "hora": "10:00",
    "local": "Consultório - Av. Paulista, 1000",
    "status": "Agendada",
    "tipo": "Psiquiátrica"
  }
]
EOF

cat > "\$APP_DIR/data/processos.json" << 'EOF'
[
  {
    "id": 1,
    "numeroProcesso": "0001234-56.2025.8.26.0100",
    "tribunal": "tjsp",
    "vara": "2ª Vara Cível",
    "comarca": "São Paulo",
    "autor": "João Silva",
    "reu": "Seguradora XYZ",
    "ultimaVerificacao": "2025-04-01T00:00:00.000Z",
    "status": "Ativo"
  },
  {
    "id": 2,
    "numeroProcesso": "0002345-67.2025.8.26.0100",
    "tribunal": "tjsp",
    "vara": "3ª Vara Cível",
    "comarca": "São Paulo",
    "autor": "Maria Oliveira",
    "reu": "Seguradora ABC",
    "ultimaVerificacao": "2025-04-05T00:00:00.000Z",
    "status": "Ativo"
  }
]
EOF

# 10. Verificar instalação
log "Verificando instalação..."
sleep 5
response=\$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ 2>/dev/null)
if [ "\$response" != "200" ] && [ "\$response" != "302" ]; then
  log "AVISO: Serviço não está respondendo como esperado (HTTP \$response). Tentando reiniciar..."
  pm2 restart assistpericias-web
else
  log "Serviço está respondendo corretamente!"
fi

# 11. Limpeza final
log "Realizando limpeza final..."
rm -f "/tmp/assistpericias-${VERSION}.tar.gz"
rm -f "/tmp/assistpericias_install.sh"

log "Instalação concluída com sucesso!"
log "Acesse http://localhost:3000 e use o token '$TOKEN' para login."
EOF

chmod +x "$INSTALL_SCRIPT"

# Iniciar a instalação remota
log "Iniciando instalação remota em $HOSTNAME..."

# Verificar se é possível conectar ao servidor
ssh -p "$PORT" "$USERNAME@$HOSTNAME" "echo 'Conexão OK'" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  log "ERRO: Não foi possível conectar ao servidor $HOSTNAME."
  exit 1
fi

# Enviar pacote de instalação
log "Enviando pacote de instalação para $HOSTNAME..."
scp -P "$PORT" "$PACKAGE_FILE" "$USERNAME@$HOSTNAME:/tmp/assistpericias-${VERSION}.tar.gz"
if [ $? -ne 0 ]; then
  log "ERRO: Falha ao enviar pacote para $HOSTNAME."
  exit 1
fi

# Enviar script de instalação
log "Enviando script de instalação para $HOSTNAME..."
scp -P "$PORT" "$INSTALL_SCRIPT" "$USERNAME@$HOSTNAME:/tmp/assistpericias_install.sh"
if [ $? -ne 0 ]; then
  log "ERRO: Falha ao enviar script para $HOSTNAME."
  exit 1
fi

# Executar instalação remota
log "Executando instalação em $HOSTNAME..."
ssh -p "$PORT" "$USERNAME@$HOSTNAME" "sudo bash /tmp/assistpericias_install.sh"
if [ $? -ne 0 ]; then
  log "ERRO: Falha durante a instalação em $HOSTNAME."
  exit 1
fi

# Adicionar cliente à lista de clientes (se não existir)
log "Adicionando cliente à lista de distribuição..."
CLIENTS_FILE="/opt/assistpericias/config/clients.txt"
mkdir -p "$(dirname "$CLIENTS_FILE")"

if [ ! -f "$CLIENTS_FILE" ]; then
  echo "# Lista de clientes para distribuição de atualizações" > "$CLIENTS_FILE"
  echo "# Formato: hostname,username,porta_ssh" >> "$CLIENTS_FILE"
fi

if ! grep -q "$HOSTNAME,$USERNAME,$PORT" "$CLIENTS_FILE"; then
  echo "$HOSTNAME,$USERNAME,$PORT" >> "$CLIENTS_FILE"
fi

log "Instalação em $HOSTNAME concluída com sucesso!"
log "Cliente adicionado à lista de distribuição para futuras atualizações."

rm -f "$INSTALL_SCRIPT"
