#!/bin/bash
# Script de configuração para o repositório AssistPericias

# Configurar o repositório remoto
git remote add origin https://github.com/adielrios/assistpericiascom.git || echo "Remoto já configurado ou erro na configuração"
echo "Repositório remoto configurado ou já existente."

# Verificar a configuração
git remote -v

# Sincronizar com o repositório remoto
echo "Sincronizando com o repositório remoto..."
git pull origin master || echo "Não foi possível baixar do repositório remoto. Continuando..."

# Adicionar alterações pendentes
echo "Adicionando alterações pendentes..."
git add logs/last_monitor_check

# Commit das alterações pendentes
echo "Fazendo commit das alterações..."
git commit -m "Atualização do monitor de logs" || echo "Nada para commitar ou erro no commit."

# Enviar alterações locais para o repositório remoto
echo "Enviando alterações locais para o repositório remoto..."
git push origin master && echo "Alterações enviadas com sucesso." || echo "Não foi possível enviar as alterações. Verifique as credenciais e permissões."

# Mostrar status atual
echo "Status atual do repositório:"
git status

echo "Configuração concluída!"
echo "Para enviar futuras alterações, use: git push origin master"
echo "Para baixar futuras alterações, use: git pull origin master"
