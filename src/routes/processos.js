const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.send(`
    <h1>Módulo de Processos</h1>
    <p>Esta seção permite gerenciar todos os processos judiciais.</p>
    <p>Funcionalidade em desenvolvimento.</p>
    <a href="/dashboard">Voltar para o Dashboard</a>
  `);
});

router.get('/api/listar', (req, res) => {
  // Implementar lógica para listar processos
  res.json({ message: 'API para listar processos' });
});

module.exports = router;
