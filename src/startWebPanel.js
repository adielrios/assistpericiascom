const express = require('express');
const path = require('path');
const fs = require('fs-extra');
const cors = require('cors');
const auth = require('./middlewares/auth');

// Inicializar a aplicação Express
const app = express();

// Configurar middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors());
app.use(express.static(path.join(__dirname, '..', 'public')));

// Importar rotas
// Estas importações serão feitas dinamicamente para não quebrar em caso de arquivo não existente
function tryRequire(modulePath) {
  try {
    return require(modulePath);
  } catch (error) {
    console.error(`Aviso: Módulo ${modulePath} não encontrado.`);
    return express.Router();
  }
}

// Importar rotas principais
const periciasRouter = tryRequire('./routes/pericias');
const calendarRouter = tryRequire('./routes/calendar');
const analyticsRouter = tryRequire('./routes/analytics');
const reportsRouter = tryRequire('./routes/reports');
const laudosRouter = tryRequire('./routes/laudos');
const processosRouter = tryRequire('./routes/processos');
const monitoraRouter = tryRequire('./routes/monitora');
const dashboardMonitorRouter = tryRequire('./routes/dashboard_monitor');
const verificadorRouter = tryRequire('./routes/verificador_processos');
const laudoAnalyzerRouter = tryRequire('./routes/laudo_analyzer');
const assistenteRouter = tryRequire('./routes/assistente');
const exportacaoRouter = tryRequire('./routes/exportacao');

// Usar rotas
app.use('/pericias', periciasRouter);
app.use('/calendar', calendarRouter);
app.use('/analytics', analyticsRouter);
app.use('/reports', reportsRouter);
app.use('/laudos', laudosRouter);
app.use('/processos', processosRouter);
app.use('/monitora', monitoraRouter);
app.use('/dashboard_monitor', dashboardMonitorRouter);
app.use('/verificador', verificadorRouter);
app.use('/laudo_analyzer', laudoAnalyzerRouter);
app.use('/assistente', assistenteRouter);
app.use('/exportacao', exportacaoRouter);

// Carregar configurações do sistema
let configSistema = {};
try {
  configSistema = fs.readJsonSync(path.join(__dirname, '../config/sistema.json'));
  console.log(`Configurações do sistema carregadas. Versão: ${configSistema.versao}`);
} catch (error) {
  console.error('Erro ao carregar configurações do sistema:', error.message);
}

// Rota principal - redireciona para login
app.get('/', (req, res) => {
  res.redirect('/login');
});

// Rota de login
app.get('/login', (req, res) => {
  res.send(`
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AssistPericias - Login</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #f5f5f5;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
    }
    .login-container {
      background-color: white;
      padding: 30px;
      border-radius: 5px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
      width: 90%;
      max-width: 400px;
    }
    h1 {
      text-align: center;
      color: #333;
    }
    input {
      width: 100%;
      padding: 10px;
      margin: 10px 0;
      border: 1px solid #ddd;
      border-radius: 4px;
      box-sizing: border-box;
    }
    button {
      width: 100%;
      padding: 10px;
      background-color: #4CAF50;
      color: white;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-size: 16px;
    }
    button:hover {
      background-color: #45a049;
    }
    .error {
      color: red;
      text-align: center;
      margin-top: 10px;
    }
    .logo {
      text-align: center;
      margin-bottom: 20px;
    }
    .logo img {
      max-width: 80%;
      height: auto;
    }
    .version {
      text-align: center;
      font-size: 12px;
      color: #999;
      margin-top: 20px;
    }
  </style>
</head>
<body>
  <div class="login-container">
    <div class="logo">
      <h1>AssistPericias</h1>
    </div>
    <form id="loginForm">
      <input type="text" id="token" placeholder="Insira seu token de acesso" required>
      <button type="submit">Entrar</button>
      <div id="errorMessage" class="error"></div>
    </form>
    <div class="version">Versão ${configSistema.versao || '2.0.0'} - Maio 2025</div>
  </div>
  <script>
    document.getElementById('loginForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      const token = document.getElementById('token').value.trim();
      
      try {
        const response = await fetch('/api/auth/validate', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ token })
        });
        
        const data = await response.json();
        
        if (response.ok) {
          localStorage.setItem('token', token);
          localStorage.setItem('userName', data.user.nome);
          window.location.href = '/dashboard';
        } else {
          document.getElementById('errorMessage').textContent = data.message || 'Token inválido';
        }
      } catch (error) {
        document.getElementById('errorMessage').textContent = 'Erro ao tentar autenticar. Tente novamente.';
      }
    });
  </script>
</body>
</html>
  `);
});

// API para validação de token
app.post('/api/auth/validate', (req, res) => {
  const { token } = req.body;
  
  if (!token) {
    return res.status(400).json({ message: 'Token não fornecido' });
  }
  
  const tokenDir = path.join(__dirname, '..', 'data', 'tokens');
  const tokenPath = path.join(tokenDir, `${token}.json`);
  
  if (fs.existsSync(tokenPath)) {
    try {
      const tokenData = fs.readJsonSync(tokenPath);
      if (tokenData.expiresAt > Date.now()) {
        return res.json({ success: true, user: tokenData.user });
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
});

// Dashboard
app.get('/dashboard', (req, res) => {
  const saudacao = getSaudacao();
  res.send(`
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AssistPericias - Dashboard</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 0;
      padding: 0;
      background-color: #f4f6f9;
    }
    .header {
      background-color: #4CAF50;
      color: white;
      padding: 15px 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .sidebar {
      width: 250px;
      background-color: #343a40;
      color: white;
      height: calc(100vh - 60px);
      position: fixed;
      padding-top: 20px;
    }
    .sidebar-menu {
      list-style: none;
      padding: 0;
    }
    .sidebar-menu li {
      padding: 10px 20px;
      border-left: 3px solid transparent;
    }
    .sidebar-menu li:hover {
      background-color: #2c3136;
      border-left-color: #4CAF50;
      cursor: pointer;
    }
    .content {
      margin-left: 250px;
      padding: 20px;
    }
    .dashboard-card {
      background-color: white;
      border-radius: 5px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.05);
      padding: 20px;
      margin-bottom: 20px;
    }
    .dashboard-title {
      border-bottom: 1px solid #eee;
      padding-bottom: 10px;
      margin-top: 0;
    }
    .btn {
      padding: 8px 16px;
      background-color: #4CAF50;
      color: white;
      border: none;
      border-radius: 4px;
      cursor: pointer;
    }
    .user-info {
      display: flex;
      align-items: center;
    }
    .stats-container {
      display: flex;
      justify-content: space-between;
      flex-wrap: wrap;
      margin-bottom: 20px;
    }
    .stat-card {
      background-color: white;
      border-radius: 5px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.05);
      padding: 20px;
      flex: 1;
      margin: 0 10px;
      text-align: center;
    }
    .stat-number {
      font-size: 24px;
      font-weight: bold;
      margin: 10px 0;
    }
    .assistant-container {
      position: fixed;
      bottom: 20px;
      right: 20px;
      width: 300px;
      background-color: white;
      border-radius: 5px;
      box-shadow: 0 2px 15px rgba(0,0,0,0.1);
      overflow: hidden;
      transition: height 0.3s ease;
      z-index: 1000;
    }
    .assistant-header {
      background-color: #4CAF50;
      color: white;
      padding: 10px 15px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      cursor: pointer;
    }
    .assistant-body {
      height: 300px;
      display: flex;
      flex-direction: column;
    }
    .assistant-messages {
      flex: 1;
      overflow-y: auto;
      padding: 10px;
    }
    .assistant-input {
      border-top: 1px solid #eee;
      padding: 10px;
      display: flex;
    }
    .assistant-input input {
      flex: 1;
      padding: 8px;
      border: 1px solid #ddd;
      border-radius: 4px;
      margin-right: 5px;
    }
    .assistant-input button {
      background-color: #4CAF50;
      color: white;
      border: none;
      padding: 8px 12px;
      border-radius: 4px;
      cursor: pointer;
    }
    .message {
      margin-bottom: 10px;
      max-width: 80%;
    }
    .message-user {
      align-self: flex-end;
      background-color: #e7f7e7;
      padding: 8px 12px;
      border-radius: 15px 15px 0 15px;
      margin-left: auto;
    }
    .message-assistant {
      align-self: flex-start;
      background-color: #f1f1f1;
      padding: 8px 12px;
      border-radius: 15px 15px 15px 0;
    }
    .assistant-toggle {
      width: 24px;
      height: 24px;
      cursor: pointer;
    }
    .hidden {
      display: none;
    }
  </style>
</head>
<body>
  <div class="header">
    <h2>AssistPericias</h2>
    <div class="user-info">
      <span id="userName"></span>
      <button class="btn" onclick="logout()" style="margin-left: 15px;">Sair</button>
    </div>
  </div>
  
  <div class="sidebar">
    <ul class="sidebar-menu">
      <li class="active">Dashboard</li>
      <li onclick="window.location.href='/pericias'">Perícias</li>
      <li onclick="window.location.href='/processos'">Processos</li>
      <li onclick="window.location.href='/monitora'">Monitoramento</li>
      <li onclick="window.location.href='/dashboard_monitor'">Monitor do Sistema</li>
      <li onclick="window.location.href='/calendar'">Calendário</li>
      <li onclick="window.location.href='/reports'">Relatórios</li>
      <li onclick="window.location.href='/analytics'">Análises</li>
      <li onclick="window.location.href='/laudos'">Laudos</li>
      <li onclick="window.location.href='/laudo_analyzer'">Análise de Laudos</li>
      <li onclick="window.location.href='/verificador'">Verificador de Processos</li>
      <li onclick="window.location.href='/exportacao'">Exportação Avançada</li>
    </ul>
  </div>
  
  <div class="content">
    <h2>Dashboard</h2>
    
    <div class="dashboard-card">
      <h3 class="dashboard-title">${saudacao}</h3>
      <p>Bem-vindo ao AssistPericias, seu sistema de gerenciamento de perícias médicas.</p>
    </div>
    
    <div class="stats-container">
      <div class="stat-card">
        <h3>Perícias Pendentes</h3>
        <div class="stat-number">3</div>
      </div>
      <div class="stat-card">
        <h3>Processos Ativos</h3>
        <div class="stat-number">12</div>
      </div>
      <div class="stat-card">
        <h3>Laudos Emitidos</h3>
        <div class="stat-number">8</div>
      </div>
      <div class="stat-card">
        <h3>Alertas</h3>
        <div class="stat-number">2</div>
      </div>
    </div>
    
    <div class="dashboard-card">
      <h3 class="dashboard-title">Próximas Perícias</h3>
      <table style="width: 100%; border-collapse: collapse;">
        <thead>
          <tr>
            <th style="text-align: left; padding: 8px; border-bottom: 1px solid #ddd;">Data</th>
            <th style="text-align: left; padding: 8px; border-bottom: 1px solid #ddd;">Paciente</th>
            <th style="text-align: left; padding: 8px; border-bottom: 1px solid #ddd;">Processo</th>
            <th style="text-align: left; padding: 8px; border-bottom: 1px solid #ddd;">Status</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td style="padding: 8px; border-bottom: 1px solid #ddd;">10/05/2025</td>
            <td style="padding: 8px; border-bottom: 1px solid #ddd;">João Silva</td>
            <td style="padding: 8px; border-bottom: 1px solid #ddd;">0001234-56.2025.8.26.0100</td>
            <td style="padding: 8px; border-bottom: 1px solid #ddd;">Agendada</td>
          </tr>
          <tr>
            <td style="padding: 8px; border-bottom: 1px solid #ddd;">15/05/2025</td>
            <td style="padding: 8px; border-bottom: 1px solid #ddd;">Maria Oliveira</td>
            <td style="padding: 8px; border-bottom: 1px solid #ddd;">0002345-67.2025.8.26.0100</td>
            <td style="padding: 8px; border-bottom: 1px solid #ddd;">Confirmada</td>
          </tr>
          <tr>
            <td style="padding: 8px; border-bottom: 1px solid #ddd;">20/05/2025</td>
            <td style="padding: 8px; border-bottom: 1px solid #ddd;">Pedro Santos</td>
            <td style="padding: 8px; border-bottom: 1px solid #ddd;">0003456-78.2025.8.26.0100</td>
            <td style="padding: 8px; border-bottom: 1px solid #ddd;">Pendente</td>
          </tr>
        </tbody>
      </table>
      <div style="margin-top: 15px;">
        <button class="btn" onclick="window.location.href='/pericias'">Ver Todas</button>
      </div>
    </div>
    
    <div class="dashboard-card">
      <h3 class="dashboard-title">Alertas Recentes</h3>
      <ul style="padding-left: 20px;">
        <li style="margin-bottom: 10px;">Novo processo adicionado: 0004567-89.2025.8.26.0100</li>
        <li style="margin-bottom: 10px;">Lembrete: Prazo para envio de laudo expira em 5 dias</li>
      </ul>
    </div>
  </div>
  
  <!-- Assistente Virtual -->
  <div class="assistant-container" id="assistantContainer">
    <div class="assistant-header" onclick="toggleAssistant()">
      <span>Assistente ${configSistema.assistenteVirtual?.nome || 'Oscar'}</span>
      <span class="assistant-toggle" id="assistantToggle">▼</span>
    </div>
    <div class="assistant-body" id="assistantBody">
      <div class="assistant-messages" id="assistantMessages">
        <div class="message message-assistant">
          ${configSistema.assistenteVirtual?.mensagemBemVindo || 'Olá, sou Oscar, seu assistente virtual! Como posso ajudar hoje?'}
        </div>
      </div>
      <div class="assistant-input">
        <input type="text" id="assistantInput" placeholder="Digite sua pergunta...">
        <button onclick="sendQuestion()">Enviar</button>
      </div>
    </div>
  </div>
  
  <script>
    // Variáveis globais
    let assistantVisible = false;
    
    document.addEventListener('DOMContentLoaded', () => {
      const token = localStorage.getItem('token');
      if (!token) {
        window.location.href = '/login';
        return;
      }
      
      // Carregar nome do usuário
      const userName = localStorage.getItem('userName');
      if (userName) {
        document.getElementById('userName').textContent = userName;
      } else {
        validateToken(token);
      }
      
      // Inicializar assistente
      initAssistant();
      
      // Configurar envio de mensagem com Enter
      document.getElementById('assistantInput').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
          sendQuestion();
        }
      });
    });
    
    function validateToken(token) {
      fetch('/api/auth/validate', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ token })
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          document.getElementById('userName').textContent = data.user.nome;
          localStorage.setItem('userName', data.user.nome);
        } else {
          logout();
        }
      })
      .catch(() => {
        logout();
      });
    }
    
    function initAssistant() {
      // Verificar e definir visibilidade do assistente
      const shouldBeVisible = localStorage.getItem('assistantVisible') === 'true';
      toggleAssistant(shouldBeVisible);
      
      // Carregar histórico de mensagens
      const history = localStorage.getItem('assistantHistory');
      if (history) {
        document.getElementById('assistantMessages').innerHTML = history;
      }
      
      // Verificar status do assistente
      fetch('/assistente/status', {
        headers: {
          'Authorization': localStorage.getItem('token')
        }
      })
      .then(response => response.json())
      .then(status => {
        // Atualizar nome do assistente
        document.querySelector('.assistant-header span').textContent = 'Assistente ' + status.nome;
      })
      .catch(error => {
        console.error('Erro ao verificar status do assistente:', error);
      });
    }
    
    function toggleAssistant(forcedState) {
      const body = document.getElementById('assistantBody');
      const toggle = document.getElementById('assistantToggle');
      
      // Se forcedState for definido, use-o, caso contrário, alterne
      assistantVisible = (forcedState !== undefined) ? forcedState : !assistantVisible;
      
      if (assistantVisible) {
        body.style.display = 'flex';
        toggle.textContent = '▼';
      } else {
        body.style.display = 'none';
        toggle.textContent = '▲';
      }
      
      localStorage.setItem('assistantVisible', assistantVisible);
    }
    
    function sendQuestion() {
      const input = document.getElementById('assistantInput');
      const question = input.value.trim();
      
      if (!question) return;
      
      // Limpar input
      input.value = '';
      
      // Adicionar pergunta à conversa
      const messages = document.getElementById('assistantMessages');
      messages.innerHTML += `<div class="message message-user">${question}</div>`;
      
      // Salvar mensagens
      localStorage.setItem('assistantHistory', messages.innerHTML);
      
      // Rolar para o final
      messages.scrollTop = messages.scrollHeight;
      
      // Enviar pergunta ao servidor
      fetch('/assistente/perguntar', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': localStorage.getItem('token')
        },
        body: JSON.stringify({ pergunta: question })
      })
      .then(response => response.json())
      .then(data => {
        // Adicionar resposta à conversa
        messages.innerHTML += `<div class="message message-assistant">${data.resposta}</div>`;
        
        // Salvar mensagens
        localStorage.setItem('assistantHistory', messages.innerHTML);
        
        // Rolar para o final
        messages.scrollTop = messages.scrollHeight;
      })
      .catch(error => {
        console.error('Erro ao processar pergunta:', error);
        messages.innerHTML += `<div class="message message-assistant">Desculpe, ocorreu um erro ao processar sua pergunta. Por favor, tente novamente.</div>`;
        
        // Salvar mensagens
        localStorage.setItem('assistantHistory', messages.innerHTML);
        
        // Rolar para o final
        messages.scrollTop = messages.scrollHeight;
      });
    }
    
    function logout() {
      localStorage.removeItem('token');
      localStorage.removeItem('userName');
      window.location.href = '/login';
    }
  </script>
</body>
</html>
  `);
});

// Função auxiliar para obter saudação com base na hora
function getSaudacao() {
  const hora = new Date().getHours();
  let saudacao;
  
  if (hora < 12) {
    saudacao = "Bom dia";
  } else if (hora < 18) {
    saudacao = "Boa tarde";
  } else {
    saudacao = "Boa noite";
  }
  
  return saudacao;
}

// Iniciar o servidor
const port = process.env.PORT || 3000;
app.listen(port, '0.0.0.0', () => {
  console.log(`Sistema AssistPericias iniciado`);
  console.log(`Sistema AssistPericias iniciado na porta ${port}`);
  console.log(`Acesse http://localhost:${port}`);
});
