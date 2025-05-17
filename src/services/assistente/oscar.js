/**
 * Serviço do Assistente Virtual Oscar
 * Versão: 1.0 - 08/05/2025
 */

const fs = require('fs-extra');
const path = require('path');

class AssistenteVirtual {
  constructor() {
    this.config = fs.readJsonSync(path.join(__dirname, '../../../config/sistema.json'));
    this.nome = this.config.assistenteVirtual.nome;
    this.ativo = this.config.assistenteVirtual.ativo;
    this.mensagemBemVindo = this.config.assistenteVirtual.mensagemBemVindo;
    
    // Base de conhecimento do assistente
    this.conhecimento = {
      "perícia": [
        "A perícia médica é um procedimento de avaliação técnica realizado por médico designado.",
        "Após a perícia, o perito elabora um laudo com suas conclusões.",
        "O médico perito deve ser imparcial em sua avaliação."
      ],
      "laudo": [
        "O laudo pericial deve ser claro, objetivo e fundamentado.",
        "É importante responder a todos os quesitos formulados pelo juízo e pelas partes.",
        "O laudo deve conter a identificação do periciando, histórico, exame físico, conclusão e respostas aos quesitos."
      ],
      "processo": [
        "Os processos judiciais envolvendo perícias seguem ritos específicos.",
        "É importante verificar os prazos processuais para entrega do laudo.",
        "As partes podem apresentar quesitos suplementares após a entrega do laudo."
      ],
      "agenda": [
        "É recomendável manter uma agenda organizada das perícias.",
        "Priorize perícias com prazos mais curtos para entrega do laudo.",
        "Reserve tempo adequado para cada exame pericial."
      ]
    };
  }
  
  /**
   * Processa uma pergunta e retorna uma resposta
   * @param {string} pergunta - Pergunta do usuário
   * @return {Promise<string>} Resposta do assistente
   */
  async processarPergunta(pergunta) {
    if (!this.ativo) {
      return "Assistente virtual desativado. Por favor, ative nas configurações.";
    }
    
    pergunta = pergunta.toLowerCase();
    
    // Verificar saudações
    if (this.verificarSaudacao(pergunta)) {
      return this.gerarSaudacao();
    }
    
    // Buscar resposta na base de conhecimento
    const resposta = this.buscarResposta(pergunta);
    if (resposta) {
      return resposta;
    }
    
    // Verificar comandos especiais
    if (pergunta.includes("agendar") || pergunta.includes("marcar")) {
      return this.processarAgendamento(pergunta);
    }
    
    if (pergunta.includes("lembrar") || pergunta.includes("lembrete")) {
      return this.processarLembrete(pergunta);
    }
    
    if (pergunta.includes("status") || pergunta.includes("andamento")) {
      return this.verificarStatus(pergunta);
    }
    
    // Resposta padrão
    return "Desculpe, não entendi sua pergunta. Posso ajudar com informações sobre perícias, laudos, processos ou agendamentos.";
  }
  
  /**
   * Verifica se a pergunta é uma saudação
   * @param {string} pergunta - Pergunta do usuário
   * @return {boolean} Se é uma saudação
   */
  verificarSaudacao(pergunta) {
    const saudacoes = ["olá", "ola", "oi", "bom dia", "boa tarde", "boa noite", "e aí", "ei", "hey", "hi"];
    return saudacoes.some(s => pergunta.includes(s));
  }
  
  /**
   * Gera uma saudação baseada no horário atual
   * @return {string} Saudação personalizada
   */
  gerarSaudacao() {
    const hora = new Date().getHours();
    let periodo = "";
    
    if (hora < 12) {
      periodo = "bom dia";
    } else if (hora < 18) {
      periodo = "boa tarde";
    } else {
      periodo = "boa noite";
    }
    
    return ;
  }
  
  /**
   * Busca resposta na base de conhecimento
   * @param {string} pergunta - Pergunta do usuário
   * @return {string|null} Resposta encontrada ou null
   */
  buscarResposta(pergunta) {
    // Identificar tópicos na pergunta
    const topicos = Object.keys(this.conhecimento);
    let topicoEncontrado = null;
    
    for (const topico of topicos) {
      if (pergunta.includes(topico)) {
        topicoEncontrado = topico;
        break;
      }
    }
    
    if (topicoEncontrado) {
      // Selecionar uma resposta aleatória do tópico
      const respostas = this.conhecimento[topicoEncontrado];
      const indice = Math.floor(Math.random() * respostas.length);
      return respostas[indice];
    }
    
    return null;
  }
  
  /**
   * Processa comandos de agendamento
   * @param {string} pergunta - Comando do usuário
   * @return {string} Resposta do assistente
   */
  processarAgendamento(pergunta) {
    return "Para agendar uma nova perícia, acesse a seção 'Perícias' no menu lateral e clique em 'Nova Perícia'. Lá você poderá preencher todos os dados necessários.";
  }
  
  /**
   * Processa comandos de lembrete
   * @param {string} pergunta - Comando do usuário
   * @return {string} Resposta do assistente
   */
  processarLembrete(pergunta) {
    return "Para criar um lembrete, acesse a seção 'Calendário' no menu lateral. Lá você pode adicionar eventos e configurar notificações para não perder prazos importantes.";
  }
  
  /**
   * Verifica status de processos ou perícias
   * @param {string} pergunta - Comando do usuário
   * @return {string} Resposta do assistente
   */
  verificarStatus(pergunta) {
    if (pergunta.includes("perícia") || pergunta.includes("pericia")) {
      return "Para verificar o status das perícias, acesse a seção 'Perícias' no menu lateral. Lá você terá uma visão geral de todas as perícias agendadas, realizadas e pendentes.";
    }
    
    if (pergunta.includes("processo")) {
      return "Para verificar o andamento dos processos, acesse a seção 'Processos' no menu lateral ou use o 'Verificador de Processos' para consultar informações atualizadas diretamente dos tribunais.";
    }
    
    if (pergunta.includes("laudo")) {
      return "Para verificar o status dos laudos, acesse a seção 'Laudos' no menu lateral. Lá você pode filtrar por status como 'Em elaboração', 'Finalizado' ou 'Enviado'.";
    }
    
    return "Para verificar o status de perícias, processos ou laudos, utilize as respectivas seções no menu lateral.";
  }
}

module.exports = new AssistenteVirtual();
