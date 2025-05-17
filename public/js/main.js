// Verificar se há um token no localStorage
document.addEventListener('DOMContentLoaded', function() {
  const token = localStorage.getItem('token');
  
  if (token) {
    // Verificar se o token é válido
    fetch(`/api/auth/verify?token=${token}`)
      .then(response => {
        if (response.ok) {
          return response.json();
        } else {
          throw new Error('Token inválido');
        }
      })
      .then(data => {
        showDashboard(data.user);
        loadDashboardData();
      })
      .catch(error => {
        console.error('Erro na verificação do token:', error);
        localStorage.removeItem('token');
      });
  }
  
  // Configurar o formulário de login
  const loginForm = document.getElementById('login-form');
  if (loginForm) {
    loginForm.addEventListener('submit', function(e) {
      e.preventDefault();
      const tokenInput = document.getElementById('token');
      const token = tokenInput.value.trim();
      
      if (token) {
        fetch(`/api/auth/verify?token=${token}`)
          .then(response => {
            if (response.ok) {
              return response.json();
            } else {
              throw new Error('Token inválido');
            }
          })
          .then(data => {
            localStorage.setItem('token', token);
            showDashboard(data.user);
            loadDashboardData();
          })
          .catch(error => {
            alert('Token inválido. Por favor, tente novamente.');
            console.error('Erro no login:', error);
          });
      }
    });
  }
  
  // Configurar o botão de logout
  const logoutBtn = document.getElementById('logout-btn');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', function(e) {
      e.preventDefault();
      localStorage.removeItem('token');
      window.location.reload();
    });
  }
});

function showDashboard(user) {
  document.getElementById('login-container').style.display = 'none';
  document.getElementById('dashboard').style.display = 'block';
  
  // Mostrar informações do usuário
  const userNameElement = document.getElementById('user-name');
  if (userNameElement && user) {
    userNameElement.textContent = user.nome;
  }
}

function loadDashboardData() {
  const token = localStorage.getItem('token');
  
  // Carregar processos ativos
  fetch('/api/processos', {
    headers: {
      'Authorization': token
    }
  })
    .then(response => response.json())
    .then(data => {
      const processosAtivos = data.filter(p => p.status === 
'Ativo').length;
      document.getElementById('processos-ativos').textContent = 
processosAtivos;
    })
    .catch(error => console.error('Erro ao carregar processos:', error));
  
  // Carregar perícias agendadas
  fetch('/api/pericias', {
    headers: {
      'Authorization': token
    }
  })
    .then(response => response.json())
    .then(data => {
      const periciasAgendadas = data.filter(p => p.status === 
'Agendada').length;
      document.getElementById('pericias-agendadas').textContent = 
periciasAgendadas;
    })
    .catch(error => console.error('Erro ao carregar perícias:', error));
}
