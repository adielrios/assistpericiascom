#!/bin/bash

# Configurações
DOMAIN="assistpericias.com"
WWW_DOMAIN="www.assistpericias.com"
SERVER_IP="198.199.75.95"
PROJECT_DIR="/opt/assistpericias"
EMAIL="adiel.rios@abp.org.br"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}===== Configuração do Sistema Web para $DOMAIN =====${NC}"
echo -e "${YELLOW}Este script configurará todo o ambiente web para o domínio $DOMAIN${NC}"

# Função para verificar o sucesso de um comando
check_success() {
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ $1${NC}"
  else
    echo -e "${RED}✗ $1${NC}"
    exit 1
  fi
}

# 1. Instalar dependências necessárias
echo -e "${YELLOW}Instalando dependências...${NC}"
apt-get update
apt-get install -y curl jq dnsutils certbot python3-certbot-nginx apache2-utils
check_success "Instalação de dependências"

# 2. Criar diretório do projeto
echo -e "${YELLOW}Criando estrutura de diretórios...${NC}"
mkdir -p $PROJECT_DIR/{backend,frontend,nginx_conf,certbot/{conf,www}}
check_success "Criação de diretórios"

# 3. Verificar se o Docker e Docker Compose estão instalados
echo -e "${YELLOW}Verificando Docker e Docker Compose...${NC}"
if ! command -v docker &> /dev/null; then
  echo -e "${YELLOW}Docker não encontrado. Instalando...${NC}"
  apt-get install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io
  check_success "Instalação do Docker"
else
  echo -e "${GREEN}Docker já está instalado.${NC}"
fi

if ! command -v docker-compose &> /dev/null; then
  echo -e "${YELLOW}Docker Compose não encontrado. Instalando...${NC}"
  curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
  check_success "Instalação do Docker Compose"
else
  echo -e "${GREEN}Docker Compose já está instalado.${NC}"
fi

# 4. Criar arquivo .env
echo -e "${YELLOW}Criando arquivo .env...${NC}"
cat > $PROJECT_DIR/.env << ENVFILE
# Configurações do Banco de Dados
POSTGRES_SERVER=db
POSTGRES_USER=assistpericias_user
POSTGRES_PASSWORD=$(openssl rand -base64 12)
POSTGRES_DB=assistpericias

# Configurações da API
SECRET_KEY=$(openssl rand -base64 32)
API_URL=https://$DOMAIN/api/v1
BACKEND_CORS_ORIGINS=["http://localhost", "http://localhost:4200", "http://localhost:3000", "http://localhost:8080", "https://$DOMAIN"]

# Configurações de Email
MAIL_USERNAME=contato@$DOMAIN
MAIL_PASSWORD=senha_email_segura
MAIL_FROM=contato@$DOMAIN
MAIL_PORT=587
MAIL_SERVER=smtp.godaddy.com
MAIL_TLS=True
MAIL_SSL=False

# Configurações de Notificação
SMS_API_KEY=sua_chave_api_sms
PERITO_TELEFONE=seu_telefone

# Configurações de IA
OPENAI_API_KEY=sua_chave_api_openai

# Configurações do Ambiente
ENVIRONMENT=production
ENVFILE
check_success "Criação do arquivo .env"

# 5. Criar docker-compose.yml
echo -e "${YELLOW}Criando docker-compose.yml...${NC}"
cat > $PROJECT_DIR/docker-compose.yml << DOCKERCOMPOSE
version: '3.8'

services:
  db:
    image: postgres:13
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    env_file:
      - ./.env
    restart: always
    networks:
      - assistpericias-network

  nginx:
    image: nginx:1.19
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx_conf:/etc/nginx/conf.d
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    restart: always
    networks:
      - assistpericias-network

volumes:
  postgres_data:

networks:
  assistpericias-network:
    driver: bridge
DOCKERCOMPOSE
check_success "Criação do docker-compose.yml"

# 6. Configurar Nginx para servir página temporária e suportar Let's Encrypt
echo -e "${YELLOW}Configurando Nginx...${NC}"
cat > $PROJECT_DIR/nginx_conf/default.conf << NGINXCONF
server {
    listen 80;
    server_name $DOMAIN $WWW_DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        allow all;
    }
    
    location / {
        return 200 'AssistPericias - Site em construção. Em breve estaremos no ar!';
        add_header Content-Type text/plain;
    }
}
NGINXCONF
check_success "Configuração do Nginx"

# 7. Iniciar os containers Docker
echo -e "${YELLOW}Iniciando containers Docker...${NC}"
cd $PROJECT_DIR
docker-compose up -d
check_success "Inicialização dos containers"

# 8. Criar script de monitoramento de DNS para verificar propagação
echo -e "${YELLOW}Criando script de monitoramento DNS...${NC}"
cat > $PROJECT_DIR/monitor_dns.sh << 'MONITORSCRIPT'
#!/bin/bash

DOMAIN="assistpericias.com"
TARGET_IP="198.199.75.95"
MAX_CHECKS=60
DELAY=60  # 60 segundos entre verificações

echo "Monitorando propagação DNS para $DOMAIN..."
echo "Aguardando que o domínio aponte para $TARGET_IP"
echo "Verificando a cada $DELAY segundos (máximo de $MAX_CHECKS verificações)"

for ((i=1; i<=MAX_CHECKS; i++)); do
  echo -n "Verificação $i/$MAX_CHECKS: "
  CURRENT_IP=$(dig +short $DOMAIN)
  
  echo "$DOMAIN -> $CURRENT_IP"
  
  if [[ "$CURRENT_IP" == "$TARGET_IP" ]]; then
    echo "✓ DNS propagado! $DOMAIN agora aponta para $TARGET_IP"
    echo "Verificando www.$DOMAIN..."
    
    WWW_IP=$(dig +short www.$DOMAIN)
    if [[ "$WWW_IP" == "$TARGET_IP" ]]; then
      echo "✓ www.$DOMAIN também aponta para $TARGET_IP"
      echo "Propagação DNS concluída com sucesso!"
      exit 0
    else
      echo "www.$DOMAIN ainda não está apontando para $TARGET_IP, continuando verificação..."
    fi
  else
    echo "Ainda não propagado, aguardando $DELAY segundos..."
  fi
  
  sleep $DELAY
done

echo "Tempo máximo de verificação atingido. A propagação DNS pode levar mais tempo."
echo "Execute este script novamente mais tarde para verificar o status."
exit 1
MONITORSCRIPT
chmod +x $PROJECT_DIR/monitor_dns.sh
check_success "Script de monitoramento DNS"

# 9. Criar script de obtenção de SSL
echo -e "${YELLOW}Criando script para obtenção de SSL...${NC}"
cat > $PROJECT_DIR/setup_ssl.sh << SSLSCRIPT
#!/bin/bash

DOMAIN="$DOMAIN"
WWW_DOMAIN="$WWW_DOMAIN"
EMAIL="$EMAIL"
PROJECT_DIR="$PROJECT_DIR"

echo "===== Configuração de SSL para \$DOMAIN ====="

# Parar o Nginx temporariamente
echo "Parando Nginx para liberar a porta 80..."
cd \$PROJECT_DIR
docker-compose stop nginx

# Obter certificado SSL
echo "Obtendo certificado SSL com Certbot..."
certbot certonly --standalone -d \$DOMAIN -d \$WWW_DOMAIN --email \$EMAIL --agree-tos --non-interactive

# Verificar se o certificado foi obtido com sucesso
if [ \$? -eq 0 ]; then
  echo "Certificado SSL obtido com sucesso!"
  
  # Atualizar configuração do Nginx para usar SSL
  echo "Configurando Nginx para usar SSL..."
  cat > \$PROJECT_DIR/nginx_conf/default.conf << 'NGINXSSLCONF'
server {
    listen 80;
    server_name $DOMAIN $WWW_DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        allow all;
    }
    
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name $DOMAIN $WWW_DOMAIN;
    
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # Configurações SSL recomendadas
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;
    
    # HSTS (recomendado, mas comentado)
    # add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
    
    location / {
        return 200 'AssistPericias - Site em construção. Em breve estaremos no ar! (HTTPS)';
        add_header Content-Type text/plain;
    }
}
NGINXSSLCONF
  
  # Iniciar o Nginx novamente
  echo "Iniciando Nginx com a nova configuração..."
  docker-compose start nginx
  
  # Configurar renovação automática do certificado
  echo "0 0,12 * * * root certbot renew --quiet --post-hook 'docker-compose -f $PROJECT_DIR/docker-compose.yml restart nginx'" > /etc/cron.d/certbot-renewal
  
  echo "Configuração SSL concluída com sucesso!"
else
  echo "Erro ao obter certificado SSL."
  echo "Reiniciando Nginx com configuração antiga..."
  docker-compose start nginx
  echo "Verifique se os domínios $DOMAIN e $WWW_DOMAIN estão apontando corretamente para este servidor."
fi
SSLSCRIPT
chmod +x $PROJECT_DIR/setup_ssl.sh
check_success "Script de configuração SSL"

# 10. Criar script de implantação de backend e frontend
echo -e "${YELLOW}Criando script de implantação completa...${NC}"
cat > $PROJECT_DIR/deploy_full_system.sh << 'DEPLOYSCRIPT'
#!/bin/bash

PROJECT_DIR="/opt/assistpericias"
DOMAIN="assistpericias.com"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}===== Implantação Completa do AssistPericias =====${NC}"

# Criar estrutura de backend
echo -e "${YELLOW}Configurando backend...${NC}"
mkdir -p $PROJECT_DIR/backend/app/{api/v1,core,db,models,schemas,services}

# Dockerfile do backend
cat > $PROJECT_DIR/backend/Dockerfile << EOF
FROM python:3.9

WORKDIR /app

COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app/

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
