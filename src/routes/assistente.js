const express = require('express');
const router = express.Router();
const assistente = require('../services/assistente/oscar');

router.post('/perguntar', async (req, res) => {
  try {
    const { pergunta } = req.body;
    
    if (!pergunta) {
      return res.status(400).json({ erro: 'Pergunta não fornecida' });
    }
    
    const resposta = await assistente.processarPergunta(pergunta);
    res.json({ resposta });
  } catch (error) {
    console.error('Erro ao processar pergunta:', error);
    res.status(500).json({ erro: 'Erro ao processar pergunta: ' + error.message });
  }
});

router.get('/status', (req, res) => {
  try {
    const status = {
      nome: assistente.nome,
      ativo: assistente.ativo,
      mensagemBemVindo: assistente.mensagemBemVindo
    };
    
    res.json(status);
  } catch (error) {
    console.error('Erro ao obter status do assistente:', error);
    res.status(500).json({ erro: 'Erro ao obter status do assistente: ' + error.message });
  }
});

module.exports = router;
