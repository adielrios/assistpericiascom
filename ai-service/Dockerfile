FROM python:3.9-slim

WORKDIR /app

# Instalar dependências do sistema, incluindo LLVM e Z3
RUN apt-get update && apt-get install -y \
    build-essential \
    llvm \
    llvm-dev \
    clang \
    libz3-dev \
    && rm -rf /var/lib/apt/lists/*

# Instalar dependências Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código
COPY . .

# Expor porta
EXPOSE 5000

# Comando de inicialização
CMD ["python", "main.py"]
