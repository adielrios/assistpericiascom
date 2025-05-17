const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.send(`
    <h1>Módulo de Analytics</h1>
    <p>Esta seção fornece análises e estatísticas sobre suas atividades periciais.</p>
    <p>Funcionalidade em desenvolvimento.</p>
    <a href="/dashboard">Voltar para o Dashboard</a>
  `);
});

module.exports = router;
