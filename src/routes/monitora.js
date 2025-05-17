const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.send(`
    <h1>Módulo de Monitoramento</h1>
    <p>Esta seção permite monitorar o andamento de processos e perícias.</p>
    <p>Funcionalidade em desenvolvimento.</p>
    <a href="/dashboard">Voltar para o Dashboard</a>
  `);
});

module.exports = router;
