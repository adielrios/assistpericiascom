const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.send(`
    <h1>Módulo de Calendário</h1>
    <p>Esta seção permite gerenciar sua agenda de perícias e compromissos.</p>
    <p>Funcionalidade em desenvolvimento.</p>
    <a href="/dashboard">Voltar para o Dashboard</a>
  `);
});

module.exports = router;
