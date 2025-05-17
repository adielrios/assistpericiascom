document.addEventListener('DOMContentLoaded', function() {
  const processosTable = 
document.getElementById('processos-table').getElementsByTagName('tbody')[0];
  const novoProcessoBtn = document.getElementById('novo-processo-btn');
  const modal = document.getElementById('processo-modal');
  const closeBtn = modal.querySelector('.close');
  const cancelBtn = document.getElementById('cancel-btn');
  const processoForm = document.getElementById('processo-form');
  const processoSearch = document.getElementById('processo-search');
  const processoFilter = document.getElementById('processo-filter');
  
  let processos = [];
  
  // Carregar processos
  function loadProcessos() {
    apiRequest('/api/processos')
      .then(data => {
        processos = data;
        renderProcessos();
      })
      .catch(error => console.error('Erro ao carregar processos:', 
error));
  }
  
  // Renderizar tabela de processos
  function renderProcessos() {
    processosTable.innerHTML = '';
    
    const filteredProcessos = processos.filter(p => {
      const searchTerm = processoSearch.value.toLowerCase();
      const statusFilter = processoFilter.value;
      
      // Aplicar filtro de busca
      const matchesSearch = 
p.numeroProcesso.toLowerCase().includes(searchTerm) || 
                            p.autor.toLowerCase().includes(searchTerm) || 
                            (p.reclamante && 
p.reclamante.toLowerCase().includes(searchTerm)) ||
                            p.reu.toLowerCase().includes(searchTerm) ||
                            (p.reclamada && 
p.reclamada.toLowerCase().includes(searchTerm));
      
      // Aplicar filtro de status
      const matchesStatus = statusFilter === 'todos' || p.status === 
statusFilter;
      
      return matchesSearch && matchesStatus;
    });
    
    if (filteredProcessos.length === 0) {
      const row = processosTable.insertRow();
      const cell = row.insertCell();
      cell.colSpan = 6;
      cell.textContent = 'Nenhum processo encontrado';
      cell.style.textAlign = 'center';
      return;
    }
    
    filteredProcessos.forEach(p => {
      const row = processosTable.insertRow();
      
      row.insertCell().textContent = p.numeroProcesso;
      row.insertCell().textContent = `${p.vara} - ${p.comarca}`;
      row.insertCell().textContent = p.autor || p.reclamante;
      row.insertCell().textContent = p.reu || p.reclamada;
      row.insertCell().textContent = p.status;
      
      const actionsCell = row.insertCell();
      
      const editBtn = document.createElement('button');
      editBtn.innerHTML = '✏️';
      editBtn.className = 'btn-action btn-edit';
      editBtn.title = 'Editar';
      editBtn.addEventListener('click', () => openEditModal(p));
      actionsCell.appendChild(editBtn);
      
      const deleteBtn = document.createElement('button');
      deleteBtn.innerHTML = '🗑️';
      deleteBtn.className = 'btn-action btn-delete';
      deleteBtn.title = 'Excluir';
      deleteBtn.addEventListener('click', () => deleteProcesso(p.id));
      actionsCell.appendChild(deleteBtn);
      
      const viewBtn = document.createElement('button');
      viewBtn.innerHTML = '👁️';
      viewBtn.className = 'btn-action';
      viewBtn.title = 'Visualizar';
      viewBtn.addEventListener('click', () => viewProcesso(p.id));
      actionsCell.appendChild(viewBtn);
    });
  }
  
  // Abrir modal para novo processo
  function openNewModal() {
    document.getElementById('modal-title').textContent = 'Novo Processo';
    processoForm.reset();
    document.getElementById('processo-id').value = '';
    modal.style.display = 'flex';
  }
  
  // Abrir modal para editar processo
  function openEditModal(processo) {
    document.getElementById('modal-title').textContent = 'Editar 
Processo';
    document.getElementById('processo-id').value = processo.id;
    document.getElementById('numeroProcesso').value = 
processo.numeroProcesso;
    document.getElementById('tribunal').value = processo.tribunal;
    document.getElementById('vara').value = processo.vara;
    document.getElementById('comarca').value = processo.comarca;
    document.getElementById('autor').value = processo.autor || 
processo.reclamante || '';
    document.getElementById('reu').value = processo.reu || 
processo.reclamada || '';
    document.getElementById('status').value = processo.status;
    
    modal.style.display = 'flex';
  }
  
  // Fechar modal
  function closeModal() {
    modal.style.display = 'none';
  }
  
  // Salvar processo
  function saveProcesso(e) {
    e.preventDefault();
    
    const id = document.getElementById('processo-id').value;
    const novoProcesso = {
      numeroProcesso: document.getElementById('numeroProcesso').value,
      tribunal: document.getElementById('tribunal').value,
      vara: document.getElementById('vara').value,
      comarca: document.getElementById('comarca').value,
      autor: document.getElementById('autor').value,
      reu: document.getElementById('reu').value,
      status: document.getElementById('status').value
    };
    
    if (id) {
      // Atualizar processo existente
      apiRequest(`/api/processos/${id}`, 'PUT', novoProcesso)
        .then(() => {
          loadProcessos();
          closeModal();
        })
        .catch(error => console.error('Erro ao atualizar processo:', 
error));
    } else {
      // Criar novo processo
      apiRequest('/api/processos', 'POST', novoProcesso)
        .then(() => {
          loadProcessos();
          closeModal();
        })
        .catch(error => console.error('Erro ao criar processo:', error));
    }
  }
  
  // Excluir processo
  function deleteProcesso(id) {
    if (confirm('Tem certeza que deseja excluir este processo?')) {
      apiRequest(`/api/processos/${id}`, 'DELETE')
        .then(() => loadProcessos())
        .catch(error => console.error('Erro ao excluir processo:', 
error));
    }
  }
  
  // Visualizar detalhes do processo
  function viewProcesso(id) {
    const processo = processos.find(p => p.id === id);
    if (processo) {
      alert(`Detalhes do Processo:\n
Número: ${processo.numeroProcesso}
Tribunal: ${processo.tribunal.toUpperCase()}
Vara: ${processo.vara}
Comarca: ${processo.comarca}
Autor/Reclamante: ${processo.autor || processo.reclamante}
Réu/Reclamada: ${processo.reu || processo.reclamada}
Status: ${processo.status}
Última Verificação: ${new 
Date(processo.ultimaVerificacao).toLocaleDateString('pt-BR')}`);
    }
  }
  
  // Event Listeners
  novoProcessoBtn.addEventListener('click', openNewModal);
  closeBtn.addEventListener('click', closeModal);
  cancelBtn.addEventListener('click', closeModal);
  processoForm.addEventListener('submit', saveProcesso);
  
  processoSearch.addEventListener('input', renderProcessos);
  processoFilter.addEventListener('change', renderProcessos);
  
  // Inicializar
  loadProcessos();
});
