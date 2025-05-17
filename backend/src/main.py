#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Assist Pericias - Sistema de Assistência para Perícias com IA
"""

import os
import sys
import logging
from flask import Flask, jsonify
from flask_cors import CORS

# Configurar logging
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

def create_app():
    """Cria e configura a aplicação Flask"""
    app = Flask(__name__)
    CORS(app)  # Habilitar CORS para todas as rotas
    
    @app.route('/api/status')
    def status():
        """Rota para verificar o status da API"""
        return jsonify({
            "status": "online",
            "versao": "1.0.0",
            "message": "API do Assist Pericias está funcionando corretamente"
        })
    
    return app

def main():
    """Função principal da aplicação"""
    logger.info("Iniciando Assist Pericias Backend")
    
    # Criar e executar a aplicação Flask
    app = create_app()
    app.run(host='0.0.0.0', port=8000)
    
    return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        logger.info("Programa interrompido pelo usuário")
        sys.exit(0)
    except Exception as e:
        logger.exception(f"Erro não tratado: {e}")
        sys.exit(1)
