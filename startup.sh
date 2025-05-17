#!/bin/bash
# Script de inicialização do AssistPericias
echo "Iniciando sistema AssistPericias..."
# Diretório do sistema
APP_DIR="/opt/assistpericias"
cd $APP_DIR
# Verificar se todos os diretórios existem
echo "Verificando diretórios..."
mkdir -p data/tokens
mkdir -p data/logs
mkdir -p public
# Verificar se o arquivo de token de exemplo existe
if [ ! -f "data/tokens/12345.json" ]; then
  echo "Criando token de exemplo..."
  cat > data/tokens/12345.json << 'END'
{
  "user": {
    "id": 1,
    "nome": "Dr. Adiel Carneiro Rios",
    "email": "adiel@assistpericias.com.br",
    "role": "admin"
  },
  "expiresAt": 4070908800000
}
END
fi
# Verificar se o arquivo de dados de processos existe
if [ ! -f "data/processos.json" ]; then
  echo "Criando dados de exemplo para processos..."
  cat > data/processos.json << 'END'
[
  {
    "id": 1,
    "numeroProcesso": "0001234-56.2025.8.26.0100",
    "tribunal": "tjsp",
    "vara": "2ª Vara Cível",
    "comarca": "São Paulo",
    "autor": "Maria da Silva",
    "reu": "Seguradora ABC",
    "ultimaVerificacao": "2025-04-01T00:00:00.000Z",
    "status": "Ativo"
  },
  {
    "id": 2,
    "numeroProcesso": "0002345-67.2025.5.02.0001",
    "tribunal": "trt",
    "vara": "5ª Vara do Trabalho",
    "comarca": "São Paulo",
    "reclamante": "João Oliveira",
    "reclamada": "Empresa XYZ Ltda",
    "ultimaVerificacao": "2025-04-01T00:00:00.000Z",
    "status": "Ativo"
  }
]
END
fi
# Verificar se o arquivo de dados de perícias existe
if [ ! -f "data/pericias.json" ]; then
  echo "Criando dados de exemplo para perícias..."
  cat > data/pericias.json << 'END'
[
  {
    "id": 1,
    "processoId": 1,
    "paciente": "Maria da Silva",
    "data": "2025-05-15",
    "hora": "14:30",
    "local": "Consultório - Av. Paulista, 1000",
    "status": "Agendada",
    "tipo": "Ortopédica"
  },
  {
    "id": 2,
    "processoId": 2,
    "paciente": "João Oliveira",
    "data": "2025-05-20",
    "hora": "10:00",
    "local": "Consultório - Av. Paulista, 1000",
    "status": "Agendada",
    "tipo": "Psiquiátrica"
  }
]
END
fi
# Verificar se o arquivo de dados de usuários existe
if [ ! -f "data/usuarios.json" ]; then
  echo "Criando dados de exemplo para usuários..."
  cat > data/usuarios.json << 'END'
[
  {
    "id": 1,
    "nome": "Dr. Adiel Carneiro Rios",
    "email": "adiel@assistpericias.com.br",
    "role": "admin"
  }
]
END
fi
# Verificar se o PM2 está instalado e iniciar o serviço
if command -v pm2 &> /dev/null; then
  echo "Iniciando o serviço com PM2..."
  pm2 start src/startWebPanel.js --name assistpericias-web
  pm2 save
else
  echo "PM2 não encontrado, instalando..."
  npm install -g pm2
  pm2 start src/startWebPanel.js --name assistpericias-web
  pm2 save
  # Configurar o PM2 para iniciar com o sistema
  pm2 startup
fi
echo "Sistema AssistPericias iniciado com sucesso!"
echo "Acesse http://localhost:3000 e use o token '12345' para login."
