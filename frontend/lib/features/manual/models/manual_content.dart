import 'package:flutter/material.dart';

class ManualStepItem {
  final int stepNumber;
  final String title;
  final String description;

  const ManualStepItem({
    required this.stepNumber,
    required this.title,
    required this.description,
  });
}

class ManualFieldItem {
  final String name;
  final String description;
  final String? example;
  final String? rule;

  const ManualFieldItem({
    required this.name,
    required this.description,
    this.example,
    this.rule,
  });
}

class ManualSection {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String routeTarget;
  final List<String> routeKeywords;
  final String overview;
  final List<ManualStepItem> steps;
  final List<ManualFieldItem> fields;
  final List<String> tips;
  final List<String> warnings;

  const ManualSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.routeTarget,
    required this.routeKeywords,
    required this.overview,
    required this.steps,
    required this.fields,
    required this.tips,
    required this.warnings,
  });
}

const List<ManualSection> kManualSections = [
  ManualSection(
    id: 'auth',
    title: 'Cadastro e Login',
    subtitle: 'Acesso seguro à plataforma e gerenciamento de perfil',
    icon: Icons.lock_outline_rounded,
    routeTarget: '/login',
    routeKeywords: ['/login', '/', '/register'],
    overview:
        'O acesso ao sistema Tecsys é protegido por autenticação segura via JSON Web Token (JWT). Novos operadores e engenheiros de planejamento podem criar suas contas corporativas diretamente pela interface e acessar o ambiente com suas credenciais.',
    steps: [
      ManualStepItem(
        stepNumber: 1,
        title: 'Acessar a Tela de Autenticação',
        description:
            'Ao abrir o sistema, a tela inicial exibe o painel de login. Caso ainda não possua conta, clique na aba "Criar conta" na parte superior do formulário.',
      ),
      ManualStepItem(
        stepNumber: 2,
        title: 'Preenchimento dos Dados Cadastrais',
        description:
            'Informe seu Nome Completo, E-mail Corporativo e defina uma Senha forte que cumpra os requisitos mínimos de segurança.',
      ),
      ManualStepItem(
        stepNumber: 3,
        title: 'Confirmação e Primeiro Acesso',
        description:
            'Após clicar em "Criar conta", o sistema cadastra seu usuário no banco de dados. Em seguida, alterne para a aba "Entrar" e digite seu e-mail e senha para iniciar a sessão.',
      ),
    ],
    fields: [
      ManualFieldItem(
        name: 'E-mail Corporativo',
        description: 'Endereço eletrônico utilizado como identificador exclusivo de acesso.',
        example: 'admin@tecsys.com',
        rule: 'Deve conter um formato de e-mail válido com arroba e domínio.',
      ),
      ManualFieldItem(
        name: 'Senha de Acesso',
        description: 'Chave criptografada para autenticação do operador.',
        example: 'Admin@123',
        rule: 'Mínimo de 8 caracteres, contendo pelo menos uma letra maiúscula, uma minúscula, um número e um caractere especial.',
      ),
      ManualFieldItem(
        name: 'Confirmar Senha',
        description: 'Validação de integridade na criação de novas contas.',
        rule: 'Deve ser rigorosamente idêntica ao campo de senha digitado acima.',
      ),
    ],
    tips: [
      'A sessão permanece ativa com token JWT seguro durante o uso contínuo.',
      'Em caso de expiração do token por inatividade, o sistema redireciona com segurança para a tela de login.',
    ],
    warnings: [
      'Nunca compartilhe credenciais corporativas com outros operadores.',
      'O perfil padrão possui permissões de Administrador com acesso completo a simulações e dados da BDGD.',
    ],
  ),
  ManualSection(
    id: 'bdgd-import',
    title: 'Importação de BDGD',
    subtitle: 'Carga e ingestão de ativos elétricos e bases geoespaciais',
    icon: Icons.cloud_upload_rounded,
    routeTarget: '/bdgd-import',
    routeKeywords: ['/bdgd-import'],
    overview:
        'A Base de Dados Georreferenciada das Distribuidoras (BDGD), regulamentada pela ANEEL, contém o mapeamento de todos os ativos da malha elétrica (transformadores, postes, subestações, medidores). O Tecsys processa esses dados através de um pipeline automatizado de ETL no n8n e armazena os dados espaciais no PostgreSQL com PostGIS.',
    steps: [
      ManualStepItem(
        stepNumber: 1,
        title: 'Selecionar o Arquivo da Concessionária',
        description:
            'Clique na área pontilhada de upload ou arraste o arquivo compactado no formato .zip fornecido pela distribuidora de energia.',
      ),
      ManualStepItem(
        stepNumber: 2,
        title: 'Informar os Metadados da Base',
        description:
            'Preencha o nome da Distribuidora (ex: CPFL, Enel, Neoenergia), a Região Geográfica correspondente e selecione a Data de Referência no seletor suspenso.',
      ),
      ManualStepItem(
        stepNumber: 3,
        title: 'Disparar a Ingestão e Processamento',
        description:
            'Clique no botão "Iniciar Importação". O backend aciona o fluxo de ETL no n8n, descompacta os arquivos, converte as geometrias para PostGIS e registra a base para simulações.',
      ),
      ManualStepItem(
        stepNumber: 4,
        title: 'Acompanhar Bases Cadastradas',
        description:
            'Consulte a tabela de bases importadas logo abaixo para verificar a quantidade de ativos inseridos, status de sincronização e histórico de cargas.',
      ),
    ],
    fields: [
      ManualFieldItem(
        name: 'Arquivo da BDGD (.zip)',
        description: 'Pacote comprimido contendo camadas geoespaciais e tabelas tabulares da ANEEL.',
        example: 'bdgd_campinas_2026.zip',
        rule: 'Apenas arquivos com extensão .zip contendo dados válidos são aceitos.',
      ),
      ManualFieldItem(
        name: 'Nome da Distribuidora',
        description: 'Identificação da concessionária de energia proprietária da rede.',
        example: 'CPFL Paulista',
        rule: 'Preenchimento obrigatório para isolamento e consulta de dados.',
      ),
      ManualFieldItem(
        name: 'Região Operacional',
        description: 'Área geográfica de concessão coberta pelo pacote de dados.',
        example: 'Campinas - SP',
      ),
      ManualFieldItem(
        name: 'Data de Referência',
        description: 'Mês e ano oficial da versão da base da BDGD regulamentada.',
        example: '09/2026',
      ),
    ],
    tips: [
      'O indicador no menu lateral mostra em tempo real se a BDGD está sincronizada com o banco PostGIS.',
      'Bases já importadas ficam salvas de forma permanente e podem ser utilizadas imediatamente no Wizard de Cenários.',
    ],
    warnings: [
      'Arquivos grandes da BDGD podem levar alguns segundos durante o processamento ETL no n8n. Aguarde a confirmação de conclusão.',
      'Certifique-se de que o arquivo .zip contém geometrias projetadas no padrão georreferenciado WGS84 (SRID 4326).',
    ],
  ),
  ManualSection(
    id: 'area-delimitation',
    title: 'Área de Atuação (Etapa 1)',
    subtitle: 'Definição do ponto central, raio de busca e filtro de ativos no mapa',
    icon: Icons.radar_rounded,
    routeTarget: '/scenario',
    routeKeywords: ['/scenario'],
    overview:
        'A Etapa 1 do Wizard de Planejamento de RF permite delimitar geograficamente o perímetro de análise da simulação. O sistema extrai do banco PostGIS os ativos e estruturas existentes dentro da área de influência selecionada.',
    steps: [
      ManualStepItem(
        stepNumber: 1,
        title: 'Definir o Ponto Central da Simulação',
        description:
            'Clique diretamente no mapa no local desejado ou preencha as coordenadas de Latitude e Longitude no painel de Ponto Central.',
      ),
      ManualStepItem(
        stepNumber: 2,
        title: 'Ajustar o Raio de Atuação',
        description:
            'Utilize o controle deslizante ou o campo de entrada para determinar o raio de busca ao redor do ponto central. O raio pode variar entre 0.5 km e o teto máximo de 8.0 km.',
      ),
      ManualStepItem(
        stepNumber: 3,
        title: 'Filtrar Classes de Ativos Elétricos',
        description:
            'No painel de Ativos Candidatos, marque ou desmarque as categorias de estruturas que serão avaliadas para instalação de gateways e que demandam conectividade (ex: Transformadores UNTRD, Postes e Subestações).',
      ),
      ManualStepItem(
        stepNumber: 4,
        title: 'Avançar para a Configuração de RF',
        description:
            'Verifique o resumo de área em km² e a estimativa de estruturas selecionadas. Quando o raio for válido, clique em "Avançar para Etapa 2".',
      ),
    ],
    fields: [
      ManualFieldItem(
        name: 'Latitude Central',
        description: 'Coordenada geográfica em graus decimais do centro da análise.',
        example: '-22.9068',
        rule: 'Deve ser uma latitude válida compreendida entre -90.0 e 90.0.',
      ),
      ManualFieldItem(
        name: 'Longitude Central',
        description: 'Coordenada geográfica em graus decimais do centro da análise.',
        example: '-47.0616',
        rule: 'Deve ser uma longitude válida compreendida entre -180.0 e 180.0.',
      ),
      ManualFieldItem(
        name: 'Raio de Busca',
        description: 'Distância radial a partir do centro que delimita o polígono circular de busca.',
        example: '3.5 km',
        rule: 'Valor positivo entre 0.5 km e no máximo 8.0 km por requisição.',
      ),
      ManualFieldItem(
        name: 'Classes de Ativos',
        description: 'Tipos de equipamentos da rede elétrica incluídos no cálculo.',
        example: 'UNTRD (Transformadores), Postes, Subestações',
      ),
    ],
    tips: [
      'Você pode alternar a exibição da distância entre Quilômetros (km) e Metros (m) a qualquer momento.',
      'O mapa exibe em tempo real o círculo azul translúcido representando exatamente a área geográfica coberta.',
    ],
    warnings: [
      'Se o raio exceder 8.0 km, o sistema exibirá um alerta em vermelho e bloqueará o avanço para garantir a integridade de performance das consultas espaciais.',
      'É necessário manter pelo menos uma classe de ativo selecionada para permitir a execução da simulação.',
    ],
  ),
  ManualSection(
    id: 'rf-config',
    title: 'Parâmetros de RF (Etapa 2)',
    subtitle: 'Ajuste de modelos de propagação eletromagnética e metas de otimização',
    icon: Icons.tune_rounded,
    routeTarget: '/scenario/rf',
    routeKeywords: ['/scenario/rf'],
    overview:
        'A Etapa 2 permite customizar os parâmetros físicos do enlace de rádio e os critérios de otimização. O backend utiliza esses dados para calcular o balanço de enlace (Link Budget), determinar o raio de propagação e alimentar o algoritmo de seleção ótima de gateways.',
    steps: [
      ManualStepItem(
        stepNumber: 1,
        title: 'Selecionar o Modelo de Propagação RF',
        description:
            'Escolha o modelo matemático que melhor representa o relevo e a ocupação do solo da região (Okumura-Hata Suburbano, Urbano, Espaço Livre, 3GPP Rural ou ITM Longley-Rice).',
      ),
      ManualStepItem(
        stepNumber: 2,
        title: 'Configurar Frequência e Potências',
        description:
            'Defina a Frequência de Operação (MHz), Potência de Transmissão (dBm) e a Sensibilidade do Receptor (dBm) dos equipamentos instalados em campo.',
      ),
      ManualStepItem(
        stepNumber: 3,
        title: 'Ajustar Alturas de Antenas',
        description:
            'Informe a altura média de fixação das antenas nos Gateways (ex: 15 metros no topo de postes/torres) e a altura dos dispositivos clientes (ex: 3 metros em medidores).',
      ),
      ManualStepItem(
        stepNumber: 4,
        title: 'Definir Critérios de Otimização',
        description:
            'Estabeleça a Meta Mínima de Cobertura (%) e o Número Máximo de Gateways que o algoritmo poderá alocar para solucionar o cenário.',
      ),
      ManualStepItem(
        stepNumber: 5,
        title: 'Executar o Cálculo do Cenário',
        description:
            'Clique no botão "Calcular Cenário". O sistema enviará os parâmetros para o serviço de simulação e processará a alocação ótima em tempo real.',
      ),
    ],
    fields: [
      ManualFieldItem(
        name: 'Modelo de Propagação',
        description: 'Equação de atenuação eletromagnética aplicada sobre a distância.',
        example: 'Okumura-Hata (Suburbano)',
        rule: 'Opções: Okumura-Hata Suburbano, Urbano, Espaço Livre (FSPL), 3GPP Rural Macro, ITM Longley-Rice.',
      ),
      ManualFieldItem(
        name: 'Frequência de Operação',
        description: 'Faixa de frequência da portadora de telecomunicações.',
        example: '915.0 MHz',
        rule: 'Valor numérico positivo em MHz (faixa típica ISM: 902-928 MHz).',
      ),
      ManualFieldItem(
        name: 'Potência de Transmissão',
        description: 'Potência de saída do rádio transmissor na antena.',
        example: '27.0 dBm (~500 mW)',
      ),
      ManualFieldItem(
        name: 'Sensibilidade do Receptor',
        description: 'Nível mínimo de sinal recebido capaz de decodificar o pacote sem erros.',
        example: '-120.0 dBm',
        rule: 'Valor numérico negativo em dBm.',
      ),
      ManualFieldItem(
        name: 'Altura do Gateway / Terminal',
        description: 'Elevação física da antena em relação ao nível do solo.',
        example: 'Gateway: 15.0 m | Dispositivo: 3.0 m',
      ),
      ManualFieldItem(
        name: 'Meta de Cobertura',
        description: 'Percentual desejado de ativos da rede a serem alcançados.',
        example: '90.0%',
        rule: 'Valor entre 1.0% e 100.0%.',
      ),
      ManualFieldItem(
        name: 'Limite Máximo de Gateways',
        description: 'Teto de unidades de gateways que podem ser selecionadas pelo algoritmo.',
        example: '10 unidades',
        rule: 'Inteiro positivo maior que zero.',
      ),
    ],
    tips: [
      'Ambientes urbanos densos exigem o modelo Okumura-Hata Urbano para compensar perdas de difração por edifícios.',
      'O modelo de Espaço Livre (FSPL) é recomendado para validações de linha de visada direta sem obstáculos.',
    ],
    warnings: [
      'Se o teto de gateways for muito baixo em relação à extensão da área, a meta de cobertura pode não ser atingida, gerando equipamentos em zona de sombra.',
      'Valores de frequência fora das faixas regulamentadas pela Anatel podem gerar cálculos incompatíveis com equipamentos reais.',
    ],
  ),
  ManualSection(
    id: 'results-kpis',
    title: 'Resultados e Cobertura (Etapa 3)',
    subtitle: 'Interpretação dos indicadores de qualidade, mapa e análise de sombra',
    icon: Icons.wifi_tethering_rounded,
    routeTarget: '/results',
    routeKeywords: ['/results'],
    overview:
        'A Etapa 3 consolida o resultado do algoritmo guloso de seleção de gateways (Greedy Set-Cover). A interface exibe os indicadores de eficácia (KPIs), o mapa geoespacial com as manchas de sinal e a lista detalhada de gateways sugeridos.',
    steps: [
      ManualStepItem(
        stepNumber: 1,
        title: 'Analisar os Indicadores Principais (KPIs)',
        description:
            'Verifique os 3 cartões no topo: Cobertura Total alcançada (%), Gateways Ótimos alocados e Ativos Conectados versus Ativos em Sombra.',
      ),
      ManualStepItem(
        stepNumber: 2,
        title: 'Explorar o Mapa Interativo de RF',
        description:
            'Navegue pelo mapa com zoom e arraste. Cada círculo roxo translúcido indica o raio de alcance de sinal calculado para um gateway instalado.',
      ),
      ManualStepItem(
        stepNumber: 3,
        title: 'Alternar Camadas Visuais do Mapa',
        description:
            'Utilize a barra de botões abaixo dos KPIs para ligar e desligar a mancha de Cobertura RF, os pinos de Gateways e o polígono da Área de Busca.',
      ),
      ManualStepItem(
        stepNumber: 4,
        title: 'Avaliar a Lista de Gateways Selecionados',
        description:
            'Role a tela para visualizar a lista com cada gateway proposto, suas coordenadas de latitude e longitude, quantidade de ativos atendidos e raio de cobertura em metros.',
      ),
      ManualStepItem(
        stepNumber: 5,
        title: 'Navegação e Recálculo',
        description:
            'Caso queira testar outros parâmetros ou ajustar o raio, clique no botão "Ajustar Parâmetros" ou navegue pelo Stepper no topo para voltar às etapas anteriores.',
      ),
    ],
    fields: [
      ManualFieldItem(
        name: 'Cobertura Total (%)',
        description: 'Percentual de ativos da concessionária atendidos dentro do raio de sinal útil.',
        example: '5.3% (ou até 100% conforme os parâmetros)',
        rule: 'Calculado pela fórmula: (Ativos Cobertos / Total de Ativos) x 100.',
      ),
      ManualFieldItem(
        name: 'Gateways Ótimos',
        description: 'Quantidade de estações de rádio posicionadas para maximizar a cobertura.',
        example: '6 unidades',
      ),
      ManualFieldItem(
        name: 'Ativos Conectados',
        description: 'Equipamentos da rede que possuem sinal de rádio dentro da sensibilidade limite.',
        example: '263 / 5000 ativos',
      ),
      ManualFieldItem(
        name: 'Ativos em Sombra (Shadow)',
        description: 'Equipamentos que ficaram fora da cobertura das antenas alocadas.',
        example: '4737 em sombra',
        rule: 'Equipamentos em sombra demandam mais gateways ou repetidores para serem integrados.',
      ),
    ],
    tips: [
      'A tela de resultados possui persistência automática contra F5 (recarregamento da página). Ao atualizar o navegador, sua simulação permanece salva e exibida.',
      'Você pode clicar nos pinos dos gateways no mapa para destacar o raio de cobertura correspondente.',
    ],
    warnings: [
      'Se nenhum resultado estiver disponível, a tela exibe um aviso orientando a iniciar uma nova simulação a partir do Passo 1.',
    ],
  ),
  ManualSection(
    id: 'save-export',
    title: 'Salvar e Exportar Cenários',
    subtitle: 'Persistência de histórico, relatórios técnicos e compartilhamento de dados',
    icon: Icons.save_alt_rounded,
    routeTarget: '/results',
    routeKeywords: ['/history', '/export', '/settings'],
    overview:
        'Funcionalidade planejada na evolução da plataforma para permitir que operadores salvem cenários de simulação no banco de dados, comparem diferentes configurações técnicas para a mesma região e exportem relatórios técnicos executivos.',
    steps: [
      ManualStepItem(
        stepNumber: 1,
        title: 'Nomear o Cenário de Simulação',
        description:
            'Ao finalizar o cálculo na Etapa 3, atribua um nome descritivo ao cenário (ex: "Cenário Campinas Centro - 915 MHz - 6 Gateways").',
      ),
      ManualStepItem(
        stepNumber: 2,
        title: 'Salvar no Histórico da Concessionária',
        description:
            'O sistema armazena todos os parâmetros de RF, coordenadas de gateways e indicadores alcançados associados à base da BDGD utilizada.',
      ),
      ManualStepItem(
        stepNumber: 3,
        title: 'Comparar Simulações Anteriores',
        description:
            'Acesse a tela de Histórico para comparar lado a lado o percentual de cobertura, investimento estimado e quantidade de gateways entre diferentes modelos.',
      ),
      ManualStepItem(
        stepNumber: 4,
        title: 'Exportar Relatório Técnico',
        description:
            'Gere um relatório consolidado com resumo dos KPIs, tabela de gateways e mapa para compartilhamento com parceiros e equipes de campo.',
      ),
    ],
    fields: [
      ManualFieldItem(
        name: 'Nome do Cenário',
        description: 'Rótulo identificador para organização e consulta posterior.',
        example: 'Plano Diretor RF Campinas 2026',
      ),
      ManualFieldItem(
        name: 'Formato de Exportação',
        description: 'Opções de arquivo para documentação externa.',
        example: 'Relatório Executivo PDF / Dados Tabulares CSV',
      ),
      ManualFieldItem(
        name: 'Histórico Comparativo',
        description: 'Tabela comparando indicadores de múltiplos cenários calculados.',
      ),
    ],
    tips: [
      'Salvar diferentes cenários para a mesma área permite comprovar para a diretoria técnica qual configuração oferece o melhor custo-benefício financeiro.',
    ],
    warnings: [
      'Cenários salvos ficam vinculados à versão da base da BDGD em que foram calculados.',
    ],
  ),
];

ManualSection getManualSectionForRoute(String route) {
  for (final section in kManualSections) {
    if (section.routeKeywords.contains(route)) {
      return section;
    }
  }
  return kManualSections.first;
}

ManualSection? findManualSectionById(String id) {
  for (final section in kManualSections) {
    if (section.id == id) {
      return section;
    }
  }
  return null;
}
