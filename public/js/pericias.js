document.addEventListener('DOMContentLoaded', function() {
  const periciasTable = 
document.getElementById('pericias-table').getElementsByTagName('tbody')[0];
  const novaPericiaBtn = document.getElementById('nova-pericia-btn');
  const modal = document.getElementById('pericia-modal');
  const closeBtn = modal.querySelector('.close');
  const cancelBtn = document.getElementById('cancel-btn');
  const periciaForm = document.getElementById('pericia-form');
  const periciaSearch = document.getElementById('pericia-search');
  const periciaFilter = document.getElementById('pericia-filter');
  const processoSelect = document.getElementById('processoId');
  
  let pericias = [];
  let processos = [];
  
  // Carregar perícias
  function loadPericias() {
    apiRequest('/api/pericias')
      .then(data => {
        pericias = data;
        renderPericias();
      })
      .catch(error => console.error('Erro ao carregar perícias:', error));
  }
  
  // Carregar processos para o select
  function loadProcessos() {
    apiRequest('/api/processos')
      .then(data => {
        processos = data;
        
        // Limpar select
        processoSelect.innerHTML = '';
        
        // Adicionar opção padrão
        const defaultOption = document.createElement('option');
        defaultOption.value = '';
        defaultOption.textContent = 'Selecione um processo';
        processoSelect.appendChild(defaultOption);
        
        // Adicionar opções de processos
        processos.forEach(p => {
          const option = document.createElement('option');
          option.value = p.id;
          option.textContent = `${p.numeroProcesso} - ${p.autor || 
p.reclamante}`;
          processoSelect.appendChild(option);
        });
      })
      .catch(error => console.error('Erro ao carregar processos:', 
error));
  }
  
  // Renderizar tabela de perícias
  function renderPericias() {
    periciasTable.innerHTML = '';
    
    const filteredPericias = pericias.filter(p => {
      const searchTerm = periciaSearch.value.toLowerCase();
      const statusFilter = periciaFilter.value;
      
      // Aplicar filtro de busca
      const matchesSearch = p.paciente.toLowerCase().includes(searchTerm);
      
      // Aplicar filtro de status
      const matchesStatus = statusFilter === 'todos' || p.status === 
statusFilter;
      
      return matchesSearch && matchesStatus;
    });
    
    if (filteredPericias.length === 0) {
      const row = periciasTable.insertRow();
      const cell = row.insertCell();
      cell.colSpan = 6; // Erro corrigido aqui
      cell.textContent = 'Nenhuma perícia encontrada';
      cell.style.textAlign = 'center';
      return;
    }
    
    filteredPericias.forEach(p => {
      const row = periciasTable.insertRow();
      
      row.insertCell().textContent = p.paciente;
      row.insertCell().textContent = `${formatDate(p.data)} às ${p.hora}`;
      row.insertCell().textContent = p.local;
      row.insertCell().textContent = p.tipo;
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
      deleteBtn.addEventListener('click', () => deletePericia(p.id));
      actionsCell.appendChild(deleteBtn);
      
      const reportBtn = document.createElement('button');
      reportBtn.innerHTML = '📄';
      reportBtn.className = 'btn-action';
      reportBtn.title = 'Gerar Laudo';
      reportBtn.addEventListener('click', () => generateReport(p.id));
      actionsCell.appendChild(reportBtn);
    });
  }
  
  // Formatar data
  function formatDate(dateString) {
    const [year, month, day] = dateString.split('-');
    return `${day}/${month}/${year}`;
  }
  
  // Abrir modal para nova perícia
  function openNewModal() {
    document.getElementById('modal-title').textContent = 'Nova Perícia';
    periciaForm.reset();
    document.getElementById('pericia-id').value = '';
    
    // Definir data mínima como hoje
    const today = new Date().toISOString().split('T')[0];
    document.getElementById('data').min = today;
    
    modal.style.display = 'flex';
  }
  
  // Abrir modal para editar perícia
  function openEditModal(pericia) {
    document.getElementById('modal-title').textContent = 'Editar Perícia';
    document.getElementById('pericia-id').value = pericia.id;
    document.getElementById('processoId').value = pericia.processoId;
    document.getElementById('paciente').value = pericia.paciente;
    document.getElementById('data').value = pericia.data;
    document.getElementById('hora').value = pericia.hora;
    document.getElementById('local').value = pericia.local;
    document.getElementById('tipo').value = pericia.tipo;
    document.getElementById('status').value = pericia.status;
    
    modal.style.display = 'flex';
  }
  
  // Fechar modal
  function closeModal() {
    modal.style.display = 'none';
  }
  
  // Salvar perícia
  function savePericia(e) {
    e.preventDefault();
    
    const id = document.getElementById('pericia-id').value;
    const novaPericia = {
      processoId: parseInt(document.getElementById('processoId').value),
      paciente: document.getElementById('paciente').value,
      data: document.getElementById('data').value,
      hora: document.getElementById('hora').value,
      local: document.getElementById('local').value,
      tipo: document.getElementById('tipo').value,
      status: document.getElementById('status').value
    };
    
    if (id) {
      // Atualizar perícia existente
      apiRequest(`/api/pericias/${id}`, 'PUT', novaPericia)
        .then(() => {
          loadPericias();
          closeModal();
        })
        .catch(error => console.error('Erro ao atualizar perícia:', 
error));
    } else {
      // Criar nova perícia
      apiRequest('/api/pericias', 'POST', novaPericia)
        .then(() => {
          loadPericias();
          closeModal();
        })
        .catch(error => console.error('Erro ao criar perícia:', error));
    }
  }
  
  // Excluir perícia
  function deletePericia(id) {
    if (confirm('Tem certeza que deseja excluir esta perícia?')) {
      apiRequest(`/api/pericias/${id}`, 'DELETE')
        .then(() => loadPericias())
        .catch(error => console.error('Erro ao excluir perícia:', error));
    }
  }
  
  // Gerar laudo
  function generateReport(id) {
    const pericia = pericias.find(p => p.id === id);
    if (pericia) {
      alert('Funcionalidade para gerar laudo será implementada em breve');
    }
  }
  
  // Event Listeners
  novaPericiaBtn.addEventListener('click', openNewModal);
  closeBtn.addEventListener('click', closeModal);
  cancelBtn.addEventListener('click', closeModal);
  periciaForm.addEventListener('submit', savePericia);
  
  periciaSearch.addEventListener('input', renderPericias);
  periciaFilter.addEventListener('change', renderPericias);
  
  // Inicializar
  loadProcessos();
  loadPericias();
});
