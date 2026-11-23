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
  final String? imageAssetPath;
  final String? imageCaption;
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
    this.imageAssetPath,
    this.imageCaption,
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
    subtitle: 'Acesso seguro à plataforma, perfil do usuário e encerramento de sessão',
    icon: Icons.lock_outline_rounded,
    routeTarget: '/login',
    routeKeywords: ['/login', '/', '/register', '/settings'],
    overview:
        'O acesso ao sistema Tecsys é protegido por autenticação segura via JSON Web Token (JWT). Novos operadores e engenheiros de planejamento podem criar suas contas corporativas diretamente pela interface e acessar o ambiente com suas credenciais. Já autenticado, o operador pode personalizar seu perfil e encerrar a sessão (logout) a qualquer momento pela tela de Configurações.',
    imageAssetPath: 'assets/images/manual/auth_register.png',
    imageCaption: 'Tela de Autenticação: Criação de conta corporativa e login no sistema',
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
      ManualStepItem(
        stepNumber: 4,
        title: 'Personalizar o Perfil',
        description:
            'Na tela de "Configurações" (menu lateral), atualize seu Nome de Exibição no cartão "Perfil do Usuário" e clique em "Salvar". O cabeçalho passa a exibir seu nome e um avatar com as iniciais, no lugar do rótulo genérico "Usuário".',
      ),
      ManualStepItem(
        stepNumber: 5,
        title: 'Alterar E-mail ou Senha',
        description:
            'Ainda em "Configurações", use o cartão "Segurança da Conta" para alterar o e-mail de acesso ou definir uma nova senha, sempre que necessário.',
      ),
      ManualStepItem(
        stepNumber: 6,
        title: 'Encerrar a Sessão (Logout)',
        description:
            'Clique em "Sair da conta" no menu lateral. O sistema pede confirmação, remove o token JWT armazenado localmente e redireciona para a tela de login.',
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
      ManualFieldItem(
        name: 'Nome de Exibição',
        description: 'Nome do operador exibido no cabeçalho e usado para gerar o avatar de iniciais, editável em "Configurações".',
        example: 'Ana Beatriz Souza',
      ),
      ManualFieldItem(
        name: 'Avatar',
        description: 'Ícone circular com as iniciais do Nome de Exibição.',
        rule: 'Gerado automaticamente a partir do nome; ainda não há suporte para envio de foto de perfil.',
      ),
    ],
    tips: [
      'A sessão permanece ativa com token JWT seguro durante o uso contínuo.',
      'Em caso de expiração do token por inatividade, o sistema redireciona com segurança para a tela de login.',
      'As alterações de nome, e-mail e senha feitas em "Configurações" são refletidas imediatamente em todas as telas, sem necessidade de logout.',
    ],
    warnings: [
      'Nunca compartilhe credenciais corporativas com outros operadores.',
      'O perfil padrão possui permissões de Administrador com acesso completo a simulações e dados da BDGD.',
      'A recuperação de senha pelo link "Esqueceu a senha?" ainda está em desenvolvimento. Caso esqueça a senha, solicite a um administrador que a redefina ou altere-a em "Configurações" enquanto a sessão estiver ativa.',
      'Encerrar a sessão invalida o token JWT local; será necessário autenticar novamente para acessar qualquer tela protegida.',
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
    imageAssetPath: 'assets/images/manual/bdgd_import.png',
    imageCaption: 'Tela de Importação da BDGD: Upload e listagem de bases processadas com status',
    steps: [
      ManualStepItem(
        stepNumber: 1,
        title: 'Selecionar o Arquivo da Concessionária',
        description:
            'Clique na área pontilhada de upload ou arraste o arquivo. Além do pacote compactado .zip da BDGD (ANEEL), também é possível importar ativos a partir de arquivos CSV, XLS/XLSX ou JSON vindos de outras fontes.',
      ),
      ManualStepItem(
        stepNumber: 2,
        title: 'Informar os Metadados da Base',
        description:
            'Selecione a Distribuidora e a Região Geográfica nos campos de seleção (listas fixas, sem digitação livre) e escolha a Data de Referência no seletor suspenso.',
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
        name: 'Arquivo de Ativos (CSV/XLS/JSON)',
        description: 'Formato alternativo para importar ativos vindos de fontes que não seguem o pacote oficial da BDGD.',
        example: 'ativos_rede_regional_leste.xlsx',
        rule: 'Deve conter ao menos os campos de identificador, tipo do ativo, latitude e longitude; linhas ou campos inválidos são apontados pelo sistema com a mensagem de erro correspondente.',
      ),
      ManualFieldItem(
        name: 'Distribuidora',
        description: 'Campo de seleção com a lista fixa de concessionárias de energia cadastradas no sistema.',
        example: 'CPFL Paulista',
        rule: 'Seleção obrigatória a partir da lista oficial; não aceita texto livre, evitando divergência de grafia entre bases.',
      ),
      ManualFieldItem(
        name: 'Região',
        description: 'Campo de seleção com a lista fixa das 5 grandes regiões do Brasil (Norte, Nordeste, Centro-Oeste, Sudeste, Sul).',
        example: 'Sudeste',
        rule: 'Seleção obrigatória a partir da lista oficial. É o mesmo valor usado para agrupar bases e organizar os cenários salvos por região.',
      ),
      ManualFieldItem(
        name: 'Data de Referência',
        description: 'Mês e ano oficial da versão da base da BDGD regulamentada.',
        example: '09/2026',
      ),
    ],
    tips: [
      'A tabela de bases importadas é organizada automaticamente por Região e Distribuidora, facilitando localizar a base desejada.',
      'Para mover uma base já importada para outra Distribuidora/Região, use o ícone de lápis ("Editar") na linha correspondente da tabela.',
      'Bases já importadas ficam salvas de forma permanente e podem ser utilizadas imediatamente no Wizard de Cenários.',
      'Use CSV, XLS/XLSX ou JSON quando os ativos vierem de um levantamento próprio ou de outra fonte que não seja o pacote oficial da BDGD; para a base regulatória completa da distribuidora, prefira sempre o .zip oficial.',
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
        'A Etapa 1 do Wizard de Planejamento de RF permite escolher a base BDGD de referência e delimitar geograficamente o perímetro de análise da simulação, por ponto central + raio ou por um polígono desenhado manualmente. O sistema extrai do banco PostGIS os ativos e estruturas existentes dentro da área de influência selecionada, restrita aos limites da BDGD escolhida.',
    imageAssetPath: 'assets/images/manual/area_delimitation.png',
    imageCaption: 'Etapa 1: Ponto central da subestação, raio circular de busca e mapa de ativos',
    steps: [
      ManualStepItem(
        stepNumber: 1,
        title: 'Selecionar a Base BDGD',
        description:
            'No cartão "Ponto Central da Simulação", selecione a Região e a Distribuidora para filtrar e escolher a BDGD importada que será usada como referência da simulação.',
      ),
      ManualStepItem(
        stepNumber: 2,
        title: 'Escolher o Modo de Delimitação da Área',
        description:
            'Escolha entre "Raio Circular" (ponto central + raio) ou "Polígono Manual" (desenho livre no mapa) para definir o perímetro de busca de ativos candidatos.',
      ),
      ManualStepItem(
        stepNumber: 3,
        title: 'Definir o Ponto Central (modo Raio Circular)',
        description:
            'Clique diretamente no mapa no local desejado ou preencha as coordenadas de Latitude e Longitude no painel de Ponto Central. O mapa é automaticamente enquadrado na área de cobertura da BDGD selecionada.',
      ),
      ManualStepItem(
        stepNumber: 4,
        title: 'Ajustar o Raio de Atuação (modo Raio Circular)',
        description:
            'Utilize o controle deslizante ou o campo de entrada para determinar o raio de busca ao redor do ponto central. O raio pode variar entre 0.5 km e o teto máximo sincronizado com a API (atualmente 8.0 km).',
      ),
      ManualStepItem(
        stepNumber: 5,
        title: 'Desenhar o Polígono (modo Polígono Manual)',
        description:
            'Toque no mapa para adicionar cada vértice do polígono (mínimo de 3 pontos). Arraste um vértice para ajustá-lo ou toque duas vezes nele para removê-lo.',
      ),
      ManualStepItem(
        stepNumber: 6,
        title: 'Selecionar os Tipos de Ativos Candidatos',
        description:
            'No cartão "Ativos Candidatos", marque ou desmarque os tipos de ativos da BDGD selecionada que serão avaliados para instalação de gateways. A lista exibe todos os tipos existentes na base (não apenas um conjunto fixo) com a quantidade de ativos de cada tipo dentro da área delimitada; use "Marcar todos"/"Desmarcar todos" para agilizar.',
      ),
      ManualStepItem(
        stepNumber: 7,
        title: 'Avançar para a Configuração de RF',
        description:
            'Verifique o resumo de área em km² e a estimativa de estruturas selecionadas. Quando a área e ao menos um tipo de ativo forem válidos, clique em "Avançar para Etapa 2".',
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
        description: 'Distância radial a partir do centro que delimita o polígono circular de busca (modo Raio Circular).',
        example: '3.5 km',
        rule: 'Valor positivo entre 0.5 km e o teto máximo informado pela API (atualmente 8.0 km).',
      ),
      ManualFieldItem(
        name: 'Polígono Manual',
        description: 'Conjunto de vértices desenhados pelo usuário no mapa, usado como alternativa ao ponto central + raio.',
        rule: 'Requer no mínimo 3 vértices para delimitar uma área válida.',
      ),
      ManualFieldItem(
        name: 'Tipos de Ativos Candidatos',
        description: 'Tipos de equipamentos da rede elétrica (dinâmicos, conforme a BDGD selecionada) incluídos no cálculo.',
        example: 'Postes, Transformadores MT/BT, Religadores e Chaves, Subestações, UCBT, UCMT, SSDMT, SSDBT, SSDAT, entre outros',
        rule: 'É necessário manter pelo menos um tipo selecionado para avançar.',
      ),
    ],
    tips: [
      'Você pode alternar a exibição da distância entre Quilômetros (km) e Metros (m) a qualquer momento.',
      'O mapa exibe em tempo real o círculo (ou polígono) translúcido representando exatamente a área geográfica coberta.',
      'A lista de tipos de ativos e suas quantidades é recalculada automaticamente conforme você ajusta a área (raio ou polígono).',
    ],
    warnings: [
      'Se o raio exceder o teto máximo da API, o sistema exibirá um alerta em vermelho e bloqueará o avanço para garantir a integridade de performance das consultas espaciais.',
      'O ponto central (ou os vértices do polígono) deve estar dentro da área de cobertura da BDGD selecionada; pontos fora desse limite são rejeitados com uma mensagem de erro.',
      'É necessário manter pelo menos um tipo de ativo selecionado para permitir a execução da simulação.',
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
    imageAssetPath: 'assets/images/manual/rf_config.png',
    imageCaption: 'Etapa 2: Parametrização de radiofrequência, potências e modelo de propagação',
    steps: [
      ManualStepItem(
        stepNumber: 1,
        title: 'Selecionar o Modelo de Propagação RF',
        description:
            'Escolha o modelo matemático que melhor representa o relevo e a ocupação do solo da região: Okumura-Hata Suburbano, 3GPP TR 38.901 Rural Macro ou ITM (Longley-Rice Relevo).',
      ),
      ManualStepItem(
        stepNumber: 2,
        title: 'Configurar Frequência e Potências',
        description:
            'Escolha um dos presets de Frequência de Operação (915 MHz, 433 MHz, 2.4 GHz ou ZigBee/920 MHz) ou informe um valor manual em MHz. Defina também a Potência de Transmissão do Gateway (dBm) e a Sensibilidade do Receptor (dBm).',
      ),
      ManualStepItem(
        stepNumber: 3,
        title: 'Ajustar Alturas de Antenas e Margem de Desvanecimento',
        description:
            'Informe a altura do Gateway (ex: 15 metros no topo de postes/torres), a altura do Receptor (ex: 3 metros em medidores) e a Margem de Desvanecimento (Fade Margin) em dB, que compensa perdas imprevistas de sinal.',
      ),
      ManualStepItem(
        stepNumber: 4,
        title: 'Definir Critérios de Otimização',
        description:
            'Estabeleça a Meta Mínima de Cobertura (%) e o Número Máximo de Gateways que o algoritmo poderá alocar. Opcionalmente, marque as caixas de prioridade de cobertura para Religadores, Transformadores e/ou Medidores.',
      ),
      ManualStepItem(
        stepNumber: 5,
        title: 'Executar o Cálculo do Cenário',
        description:
            'Clique no botão "Calcular Cenário". O sistema enviará os parâmetros para o serviço de simulação e processará a alocação ótima em tempo real, considerando o relevo do terreno no modelo ITM.',
      ),
    ],
    fields: [
      ManualFieldItem(
        name: 'Modelo de Propagação',
        description: 'Equação de atenuação eletromagnética aplicada sobre a distância e, no caso do ITM, sobre o perfil de elevação do terreno.',
        example: 'Okumura-Hata (Suburbano)',
        rule: 'Opções disponíveis: Okumura-Hata Suburbano, 3GPP TR 38.901 Rural Macro, ITM (Longley-Rice Relevo).',
      ),
      ManualFieldItem(
        name: 'Frequência de Operação',
        description: 'Faixa de frequência da portadora de telecomunicações. Pode ser escolhida entre presets comuns ou informada manualmente.',
        example: '915.0 MHz (presets: 433 MHz, 915 MHz, 2.4 GHz, ZigBee/920 MHz)',
        rule: 'Valor numérico positivo em MHz.',
      ),
      ManualFieldItem(
        name: 'Potência de Transmissão',
        description: 'Potência de saída do rádio transmissor na antena do Gateway.',
        example: '27.0 dBm (~500 mW)',
      ),
      ManualFieldItem(
        name: 'Sensibilidade do Receptor',
        description: 'Nível mínimo de sinal recebido capaz de decodificar o pacote sem erros.',
        example: '-120.0 dBm',
        rule: 'Valor numérico negativo em dBm.',
      ),
      ManualFieldItem(
        name: 'Altura do Gateway / Receptor',
        description: 'Elevação física da antena em relação ao nível do solo.',
        example: 'Gateway: 15.0 m | Receptor: 3.0 m',
      ),
      ManualFieldItem(
        name: 'Margem de Desvanecimento (Fade Margin)',
        description: 'Margem de segurança em dB somada ao link budget para compensar perdas imprevistas de sinal (chuva, vegetação, interferência).',
        example: '10.0 dB',
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
      ManualFieldItem(
        name: 'Prioridade de Tipos de Ativos',
        description: 'Caixas de seleção que dão prioridade de cobertura a Religadores, Transformadores e/ou Medidores no algoritmo de otimização.',
        rule: 'Opcional; se nenhuma for marcada, todos os tipos selecionados na Etapa 1 têm peso equivalente.',
      ),
    ],
    tips: [
      'O modelo ITM (Longley-Rice Relevo) é o mais indicado quando o terreno tem variações de altitude relevantes, pois considera o perfil de elevação real (SRTM) entre gateway e ativo.',
      'O modelo 3GPP TR 38.901 Rural Macro é recomendado para áreas rurais abertas, com poucas obstruções.',
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
        'A Etapa 3 consolida o resultado do algoritmo guloso de seleção de gateways (Greedy Set-Cover). A interface exibe os indicadores de eficácia (KPIs), o mapa geoespacial com as manchas de sinal calculadas de fato pela biblioteca de RF (considerando o relevo, quando aplicável) e a lista detalhada de gateways sugeridos. A partir desta tela também é possível salvar o cenário no histórico e exportar um relatório em PDF.',
    imageAssetPath: 'assets/images/manual/results_kpis.png',
    imageCaption: 'Etapa 3: Cobertura total alcançada, alocação de gateways e mancha de sinal RF no mapa',
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
        title: 'Consultar Detalhes de um Gateway',
        description:
            'Clique no marcador de um gateway no mapa para abrir um cartão com coordenadas (copiáveis), endereço/município quando disponível, altura da antena, potência de transmissão, quantidade de ativos vinculados, margem de desvanecimento e ativos em sombra. É possível também abrir a localização direto no Google Maps.',
      ),
      ManualStepItem(
        stepNumber: 5,
        title: 'Avaliar a Lista de Gateways Selecionados',
        description:
            'Role a tela para visualizar a lista com cada gateway proposto, suas coordenadas de latitude e longitude, quantidade de ativos atendidos e raio de cobertura em metros.',
      ),
      ManualStepItem(
        stepNumber: 6,
        title: 'Salvar o Cenário',
        description:
            'Clique em "Salvar Cenário", informe um Nome e a Região e confirme. O cenário fica disponível na tela de Histórico para consulta posterior.',
      ),
      ManualStepItem(
        stepNumber: 7,
        title: 'Exportar Relatório em PDF',
        description:
            'Clique em "Exportar relatório" para gerar um PDF com o mapa atual (camadas visíveis), os indicadores agregados e os parâmetros do cenário. Aguarde o estado de carregamento e o download do arquivo.',
      ),
      ManualStepItem(
        stepNumber: 8,
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
      'Você pode clicar nos pinos dos gateways no mapa para abrir o cartão de detalhes e destacar o raio de cobertura correspondente.',
    ],
    warnings: [
      'Se nenhum resultado estiver disponível, a tela exibe um aviso orientando a iniciar uma nova simulação a partir do Passo 1.',
      'O nome definido ao clicar em "Salvar Cenário" pode não aparecer corretamente na tela de Histórico (ajuste em andamento); se isso ocorrer, use a ação "Duplicar" no Histórico para criar uma cópia do cenário já com o nome desejado.',
    ],
  ),
  ManualSection(
    id: 'save-export',
    title: 'Histórico, Comparação e Relatórios de Cenários',
    subtitle: 'Consulta de cenários salvos por região, comparação lado a lado e exportação de relatórios',
    icon: Icons.save_alt_rounded,
    routeTarget: '/history',
    routeKeywords: ['/history'],
    overview:
        'Toda simulação calculada na Etapa 3 já é persistida automaticamente no banco de dados. A tela de Histórico lista esses cenários agrupados por região, permitindo reabri-los sem recalcular, compará-los lado a lado, duplicá-los como base de uma nova simulação ou excluí-los.',
    imageAssetPath: 'assets/images/manual/save_export.png',
    imageCaption: 'Histórico de Cenários: listagem por região, comparação e ações sobre simulações salvas',
    steps: [
      ManualStepItem(
        stepNumber: 1,
        title: 'Salvar um Cenário com Nome Personalizado',
        description:
            'Na tela de Resultado (Etapa 3), clique em "Salvar Cenário" e informe um Nome descritivo (ex: "Cenário Campinas Centro - 915 MHz - 6 Gateways") e a Região correspondente.',
      ),
      ManualStepItem(
        stepNumber: 2,
        title: 'Acessar o Histórico de Cenários',
        description:
            'No menu lateral, acesse "Histórico de Simulações" para visualizar os cenários salvos agrupados por Região, com busca por nome e filtro por região.',
      ),
      ManualStepItem(
        stepNumber: 3,
        title: 'Reabrir um Cenário sem Recalcular',
        description:
            'Clique em "Ver Resultado" em qualquer cenário da lista para reabrir a tela de Resultado com os dados já calculados, sem disparar uma nova simulação.',
      ),
      ManualStepItem(
        stepNumber: 4,
        title: 'Comparar Cenários Lado a Lado',
        description:
            'Selecione dois ou mais cenários na lista e clique em "Comparar Lado a Lado" para visualizar seus indicadores (cobertura, gateways, ativos conectados/em sombra) em uma janela comparativa.',
      ),
      ManualStepItem(
        stepNumber: 5,
        title: 'Duplicar ou Excluir um Cenário',
        description:
            'Use "Duplicar" para criar uma cópia do cenário com um novo nome (útil para testar variações de parâmetros) ou "Excluir" para removê-lo definitivamente, após confirmação.',
      ),
      ManualStepItem(
        stepNumber: 6,
        title: 'Exportar Relatório Técnico em PDF',
        description:
            'A partir da tela de Resultado, clique em "Exportar relatório" para gerar um PDF com o mapa, os indicadores agregados e os parâmetros do cenário, pronto para compartilhamento com parceiros e equipes de campo.',
      ),
    ],
    fields: [
      ManualFieldItem(
        name: 'Nome do Cenário',
        description: 'Rótulo identificador definido ao salvar, usado para organização e consulta posterior no Histórico.',
        example: 'Plano Diretor RF Campinas 2026',
      ),
      ManualFieldItem(
        name: 'Região',
        description: 'Uma das 5 grandes regiões do Brasil, associada ao cenário salvo; é o critério de agrupamento da listagem do Histórico.',
        example: 'Sudeste',
      ),
      ManualFieldItem(
        name: 'Formato de Exportação',
        description: 'Formato do relatório técnico gerado para compartilhamento.',
        example: 'Relatório em PDF (mapa + indicadores + parâmetros do cenário)',
      ),
      ManualFieldItem(
        name: 'Comparação de Cenários',
        description: 'Janela que exibe lado a lado os indicadores de dois ou mais cenários selecionados no Histórico.',
      ),
    ],
    tips: [
      'Salvar diferentes cenários para a mesma área permite comprovar para a diretoria técnica qual configuração oferece o melhor custo-benefício.',
      'Duplicar um cenário é a forma mais rápida de testar uma variação de parâmetros sem perder a simulação original.',
    ],
    warnings: [
      'Cenários salvos ficam vinculados à versão da base da BDGD em que foram calculados.',
      'O nome informado ao "Salvar Cenário" pode não refletir corretamente na listagem do Histórico (ajuste em andamento); confira o item na seção "Resultados e Cobertura" para o contorno recomendado.',
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
