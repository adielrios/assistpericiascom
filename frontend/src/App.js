import React, { useState, useEffect } from 'react';

function App() {
  const [status, setStatus] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('http://localhost:8000/api/status')
      .then(response => response.json())
      .then(data => {
        setStatus(data);
        setLoading(false);
      })
      .catch(error => {
        console.error('Erro ao buscar status:', error);
        setLoading(false);
      });
  }, []);

  return (
    <div className="App">
      <header className="App-header">
        <h1>Assist Pericias</h1>
        <p>Sistema Inteligente para Perícias</p>
      </header>
      <main>
        <section>
          <h2>Status do Sistema</h2>
          {loading ? (
            <p>Carregando...</p>
          ) : status ? (
            <div>
              <p><strong>Status:</strong> {status.status}</p>
              <p><strong>Versão:</strong> {status.versao}</p>
              <p><strong>Mensagem:</strong> {status.message}</p>
            </div>
          ) : (
            <p>Não foi possível obter o status do sistema.</p>
          )}
        </section>
      </main>
      <footer>
        <p>&copy; 2025 Assist Pericias</p>
      </footer>
    </div>
  );
}

export default App;
