#!/bin/bash

echo "Verificando e instalando módulos necessários..."
MODULES=("express" "nodemailer" "axios" "node-cron" "fs-extra" "chart.js" "path")

for module in "${MODULES[@]}"; do
  if ! npm list | grep -q $module; then
    echo "Instalando módulo $module..."
    npm install $module --save
  else
    echo "Módulo $module já está instalado."
  fi
done

echo "Verificação concluída!"
