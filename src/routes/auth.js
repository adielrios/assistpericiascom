const express = require('express');
const fs = require('fs');
const path = require('path');
const router = express.Router();

const TOKENS_DIR = path.join(__dirname, '../../data/tokens');

// Verificar token
router.get('/verify', (req, res) => {
  const token = req.query.token;
  
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
    
    res.json({ user: tokenData.user });
  } catch (error) {
    console.error('Erro na verificação do token:', error);
    res.status(500).json({ error: 'Erro na verificação do token' });
  }
});

module.exports = router;
