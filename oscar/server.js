const express = require('express');
const path = require('path');

const app = express();
const port = process.env.PORT || 3000;

// Middleware para logs
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Servir arquivos estáticos
app.use(express.static(path.join(__dirname, 'public')));

// Rota principal
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Rota de saúde
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

// Iniciar servidor
app.listen(port, () => {
  console.log(`OSCAR está escutando na porta ${port}`);
});
