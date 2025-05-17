#!/bin/bash

# Script para atualizar o banco de dados
DB_DIR="/opt/assistpericias/data"
BACKUP_DIR="$DB_DIR/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Criar diretório de backups
mkdir -p $BACKUP_DIR

# Fazer backup dos arquivos de dados
echo "Fazendo backup dos arquivos de dados..."
for file in "$DB_DIR"/*.json; do
  if [ -f "$file" ]; then
    filename=$(basename -- "$file")
    cp "$file" "$BACKUP_DIR/${filename%.json}_$TIMESTAMP.json"
    echo "Backup criado: $BACKUP_DIR/${filename%.json}_$TIMESTAMP.json"
  fi
done

# Verificar integridade dos arquivos JSON
echo "Verificando integridade dos arquivos JSON..."
for file in "$DB_DIR"/*.json; do
  if [ -f "$file" ]; then
    if ! jq . "$file" > /dev/null 2>&1; then
      echo "ERRO: Arquivo $file está corrompido. Restaurando backup..."
      filename=$(basename -- "$file")
      latest_backup=$(ls -t "$BACKUP_DIR/${filename%.json}"_*.json | head -1)
      if [ -f "$latest_backup" ]; then
        cp "$latest_backup" "$file"
        echo "Arquivo restaurado de $latest_backup"
      else
        echo "ERRO: Não foi possível encontrar um backup para $filename"
      fi
    else
      echo "Arquivo $file está íntegro."
    fi
  fi
done

echo "Atualização do banco de dados concluída!"
