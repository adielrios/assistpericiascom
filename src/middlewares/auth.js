const fs = require('fs-extra');
const path = require('path');

// Middleware para verificar autenticação
const verificarAutenticacao = (req, res, next) => {
  // Verificar se é uma rota pública
  const rotasPublicas = ['/login', '/api/auth/validate', '/favicon.ico'];
  if (rotasPublicas.includes(req.path) || req.path.startsWith('/public/')) {
    return next();
  }

  // Se não for uma requisição API, verificar cookie ou localStorage via redirecionamento
  if (!req.path.startsWith('/api/') && req.method === 'GET') {
    return res.redirect('/login');
  }

  // Para APIs, verificar o token no cabeçalho
  const token = req.headers.authorization;
  if (!token) {
    return res.status(401).json({ message: 'Token não fornecido' });
  }

  const tokenDir = path.join(__dirname, '../../data/tokens');
  const tokenPath = path.join(tokenDir, `${token}.json`);
  
  if (fs.existsSync(tokenPath)) {
    try {
      const tokenData = fs.readJsonSync(tokenPath);
      if (tokenData.expiresAt > Date.now()) {
        req.user = tokenData.user;
        return next();
      } else {
        return res.status(401).json({ message: 'Token expirado' });
      }
    } catch (error) {
      console.error('Erro ao ler arquivo de token:', error);
      return res.status(500).json({ message: 'Erro interno do servidor' });
    }
  } else {
    return res.status(401).json({ message: 'Token inválido' });
  }
};

module.exports = verificarAutenticacao;
