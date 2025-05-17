// Verificar autenticação
document.addEventListener('DOMContentLoaded', function() {
  const token = localStorage.getItem('token');
  
  if (!token) {
    window.location.href = '/';
    return;
  }
  
  fetch(`/api/auth/verify?token=${token}`)
    .then(response => {
      if (!response.ok) {
        throw new Error('Token inválido');
      }
      return response.json();
    })
    .catch(error => {
      console.error('Erro na autenticação:', error);
      localStorage.removeItem('token');
      window.location.href = '/';
    });
  
  // Configurar o botão de logout
  const logoutBtn = document.getElementById('logout-btn');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', function(e) {
      e.preventDefault();
      localStorage.removeItem('token');
      window.location.href = '/';
    });
  }
});

// Função utilitária para fazer requisições à API
function apiRequest(url, method = 'GET', data = null) {
  const token = localStorage.getItem('token');
  
  const options = {
    method,
    headers: {
      'Authorization': token,
      'Content-Type': 'application/json'
    }
  };
  
  if (data) {
    options.body = JSON.stringify(data);
  }
  
  return fetch(url, options)
    .then(response => {
      if (response.status === 401) {
        localStorage.removeItem('token');
        window.location.href = '/';
        throw new Error('Não autorizado');
      }
      
      if (!response.ok) {
        throw new Error('Erro na requisição');
      }
      
      if (response.status === 204) {
        return null;
      }
      
      return response.json();
    });
}
