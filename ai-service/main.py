from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import json
import logging
import traceback

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

# Inicializar app
app = Flask(__name__)
CORS(app)

# Verificar dependências
try:
    import z3
    import llvmlite.binding as llvm
    from numba import jit
    
    # Inicializar LLVM
    llvm.initialize()
    llvm.initialize_native_target()
    llvm.initialize_native_asmprinter()
    
    logger.info(f"Z3 version: {z3.get_version_string()}")
    logger.info(f"LLVM version: {llvm.get_version()}")
    
    z3_available = True
    llvm_available = True
except ImportError as e:
    logger.error(f"Erro ao carregar Z3 ou LLVM: {e}")
    z3_available = False
    llvm_available = False

@app.route("/", methods=["GET"])
def home():
    return jsonify({"message": "AssistPericias AI Service"})

@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "healthy",
        "z3_available": z3_available,
        "llvm_available": llvm_available
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
