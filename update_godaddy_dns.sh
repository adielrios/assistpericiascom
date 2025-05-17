#!/bin/bash

# Credenciais da API GoDaddy
API_KEY="h29JPbh5ZEov_5dncBZdNCqpjUc8MpaKTie"
API_SECRET="8WjZ7pwTcf7MZhHmRTpA3T"
DOMAIN="assistpericias.com"
IP_ADDRESS="198.199.75.95"

# Headers para autenticação
HEADERS="Authorization: sso-key ${API_KEY}:${API_SECRET}"

echo "===== Atualizando registros DNS para ${DOMAIN} ====="
echo "Apontando para IP: ${IP_ADDRESS}"

# Função para atualizar registro A
update_a_record() {
  local name=$1
  echo "Atualizando registro A para ${name}..."
  
  # Preparar payload JSON
  PAYLOAD="[{\"data\": \"${IP_ADDRESS}\", \"ttl\": 600, \"name\": \"${name}\", \"type\": \"A\"}]"
  
  # Enviar requisição para atualizar o registro
  RESPONSE=$(curl -s -X PUT -H "Content-Type: application/json" -H "${HEADERS}" \
             -d "${PAYLOAD}" \
             "https://api.godaddy.com/v1/domains/${DOMAIN}/records/A/${name}")
  
  # Verificar se houve algum erro
  if [ -n "$RESPONSE" ]; then
    echo "Resposta: $RESPONSE"
    if [[ "$RESPONSE" == *"error"* ]]; then
      echo "Erro ao atualizar registro ${name}"
    else
      echo "Registro ${name} atualizado!"
    fi
  else
    echo "Registro ${name} atualizado com sucesso!"
  fi
}

# Obter registros atuais para comparação
echo "Consultando registros atuais..."
CURRENT_ROOT=$(curl -s -X GET -H "${HEADERS}" \
               "https://api.godaddy.com/v1/domains/${DOMAIN}/records/A/@")
CURRENT_WWW=$(curl -s -X GET -H "${HEADERS}" \
              "https://api.godaddy.com/v1/domains/${DOMAIN}/records/A/www")

echo "Registro @ atual: $CURRENT_ROOT"
echo "Registro www atual: $CURRENT_WWW"

# Atualizar registro A para o domínio raiz (@)
update_a_record "@"

# Atualizar registro A para www
update_a_record "www"

# Verificar as atualizações
echo "Verificando atualizações..."
sleep 2

NEW_ROOT=$(curl -s -X GET -H "${HEADERS}" \
           "https://api.godaddy.com/v1/domains/${DOMAIN}/records/A/@")
NEW_WWW=$(curl -s -X GET -H "${HEADERS}" \
          "https://api.godaddy.com/v1/domains/${DOMAIN}/records/A/www")

echo "Novo registro @ configurado: $NEW_ROOT"
echo "Novo registro www configurado: $NEW_WWW"

echo "Atualização de registros DNS concluída!"
echo "As alterações podem levar de minutos a horas para se propagar."
