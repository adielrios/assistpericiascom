const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.send(`
    <h1>Módulo de Perícias</h1>
    <p>Esta seção permite gerenciar todas as suas perícias médicas.</p>
    <p>Funcionalidade em desenvolvimento.</p>
    <a href="/dashboard">Voltar para o Dashboard</a>
  `);
});

router.get('/api/listar', (req, res) => {
  // Implementar lógica para listar perícias
  res.json({ message: 'API para listar perícias' });
});

module.exports = router;
