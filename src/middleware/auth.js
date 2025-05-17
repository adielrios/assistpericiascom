const fs = require('fs');
const path = require('path');

const TOKENS_DIR = path.join(__dirname, '../../data/tokens');

function authenticate(req, res, next) {
  const token = req.headers.authorization || req.query.token;
  
  if (!token) {
    return res.status(401).json({ error: 'Token não fornecido' });
  }
  
  const tokenPath = path.join(TOKENS_DIR, `${token}.json`);
  
  try {
    if (!fs.existsSync(tokenPath)) {
      return res.status(401).json({ error: 'Token inválido' });
    }
    
    const tokenData = JSON.parse(fs.readFileSync(tokenPath, 'utf8'));
    const now = Date.now();
    
    if (tokenData.expiresAt < now) {
      return res.status(401).json({ error: 'Token expirado' });
    }
    
    req.user = tokenData.user;
    next();
  } catch (error) {
    console.error('Erro na autenticação:', error);
    res.status(500).json({ error: 'Erro na autenticação' });
  }
}

module.exports = { authenticate };
