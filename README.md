## 💻 Aprendizagem por Projetos Integrados (API) - 5DSM | 2026-2

Projeto do curso de **Desenvolvimento de Software Multiplataforma da Fatec São José dos Campos**, em parceria com a **Tecsys**, desenvolvido com Scrum e o ciclo CDIO - Conceber, Desenvolver, Implementar e Operar.

> **Status do projeto:** Em desenvolvimento

<span id="sumario">

<div align="center">
  <a href="#projeto">Sobre o Projeto</a> |
  <a href="#requisitos-funcionais">Requisitos Funcionais</a> |
  <a href="#requisitos-nao-funcionais">Requisitos Não Funcionais</a> |
  <a href="#backlog-do-produto">Backlog do Produto</a> |
  <a href="#dor-dod">DoR e DoD</a> |
  <a href="#sprints">Sprints</a> |
  <a href="#tecnologias">Tecnologias</a> |
  <a href="#instalacao">Guia de Instalação</a> |
  <a href="#equipe">Equipe</a>
</div>

<br>

<span id="projeto">

## 📋 Sobre o projeto

Empresas de distribuição de energia elétrica utilizam sensores e dispositivos de comunicação instalados ao longo de suas redes para monitorar ativos e identificar eventos relevantes para a operação. Algumas dessas aplicações dependem de uma infraestrutura própria de radiofrequência, composta por gateways instalados em pontos estratégicos para cobrir os dispositivos distribuídos em uma região.

A solução consiste em desenvolver uma aplicação multiplataforma que utilizará informações geográficas de ativos da rede elétrica, obtidas de bases públicas (BDGD), em conjunto com parâmetros de cobertura de radiofrequência, para apoiar o planejamento dessa infraestrutura.

Dado um conjunto de pontos que precisam de cobertura e um conjunto potencialmente grande de locais candidatos à instalação de gateways, o sistema deverá avaliar e propor configurações eficientes. A solução também deverá visualizar os pontos de interesse, as posições propostas para os gateways e a cobertura obtida, permitindo comparar diferentes cenários e parâmetros de planejamento.

<br>

<span id="requisitos-funcionais">

## 📚 Requisitos Funcionais

| ID | Descrição |
|---|---|
| **RF01** | Importar dados georreferenciados de ativos da rede elétrica, incluindo dados da BDGD. |
| **RF02** | Permitir a definição dos pontos que necessitam de cobertura. |
| **RF03** | Permitir a definição dos locais candidatos à instalação de gateways, como postes e subestações. |
| **RF04** | Configurar os principais parâmetros técnicos e critérios de cobertura de radiofrequência. |
| **RF05** | Processar os dados e propor configurações eficientes para a implantação de gateways. |
| **RF06** | Visualizar em mapa os pontos de interesse, os gateways propostos e suas áreas de cobertura. |
| **RF07** | Permitir a criação, execução e comparação de diferentes cenários de planejamento. |
| **RF08** | Apresentar indicadores de qualidade, incluindo percentual de pontos cobertos e quantidade de gateways utilizados. |

<br>

<span id="requisitos-nao-funcionais">

## 📚 Requisitos Não Funcionais

| ID | Descrição |
|---|---|
| **RNF01** | Disponibilizar um manual de instalação no repositório Git. |
| **RNF02** | Disponibilizar um manual do usuário. |
| **RNF03** | Oferecer uma interface para visualização geográfica dos pontos analisados e dos resultados do planejamento. |
| **RNF04** | Processar conjuntos extensos de dados geográficos sem depender da análise exaustiva de todas as combinações possíveis. |
| **RNF05** | Permitir a parametrização dos principais critérios da análise para avaliar diferentes cenários. |
| **RNF06** | Ser reutilizável com dados de diferentes áreas geográficas ou distribuidoras, sem ficar restrita a um único conjunto de dados. |

<br>

<span id="backlog-do-produto">

## 🎯 Backlog do Produto

| ID | Prioridade | User Story | Sprint |
|---|---|---|---|
| **US01** | Alta | Como usuário, quero importar as BDGDs, para poder realizar simulações em determinada região. | 1 |
| **US02** | Alta | Como usuário, quero definir a area do cenário no mapa a meta mínima de cobertura e o número máximo de gateways antes de rodar um cenário, para garantir que a simulação respeite os limites e objetivos definidos. | 1 |
| **US03** | Alta | Como usuário, quero visualizar os ativos elétricos combinados com a RF em um mapa, para poder visualizar quantos ativos a RF está cobrindo. | 1 |
| **US04** | Alta | Como usuário, quero ver indicadores de qualidade (% de cobertura por tipo de ativo, nº de gateways, custo, tempo de processamento) ao final de um cenário, para avaliar a qualidade e a viabilidade da simulação. | 1 |
| **US05** | Média | Como usuário, quero salvar e revisitar cenários anteriores organizados por região, para comparar resultados e reaproveitar simulações já realizadas. | 2 |
| **US06** | Média | Como usuário, quero exportar os resultados de um cenário (mapa + indicadores) em um relatório, para compartilhar com o parceiro. | 2 |
| **US07** | Baixa | Como usuário, quero acessar um manual do sistema, para entender como utilizar as principais funcionalidades. | 3 |

<br>

<span id="dor-dod">

## ✅ DoR e DoD
### DoR Definition of Ready
Uma tarefa é considerada **pronta para ser iniciada** quando:
- História bem definida e escrita no formato: “Como [tipo de usuário], quero [funcionalidade], para [benefício]”.
- Dados de teste definidos.
- Mockups ou fluxos UX disponíveis.
- Regras de negócio claras.
- Estimada pela equipe (Story Points definidos).
- Critérios de aceitação definidos.

### DoD Definition of Done
Uma tarefa é considerada **pronta** quando:
- Código revisado e integrado.
- Testes unitários aprovados.
- Critérios de aceitação atendidos.
- Regras de negócio respeitadas.
- Documentação atualizada.
- Interface implementada conforme mockups.

<br>

<span id="sprints">

## 📅 Sprints

| Sprint | Previsão | Status | Relatório | Vídeo do Projeto |
|---|---|---|---|---|
| 1 | 07/09/2026 - 27/09/2026 | Em andamento | Ver Relatório | Ver Vídeo |
| 2 | 05/10/2026 - 25/10/2026 | Em breve | Ver Relatório | Ver Vídeo |
| 3 | 02/11/2026 - 22/11/2026 | Em breve | Ver Relatório | Ver Vídeo |

<br>

<span id="tecnologias">

## 🔧 Tecnologias

As seguintes ferramentas, linguagens, bibliotecas e tecnologias foram usadas na construção do projeto:

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Tailwind](https://img.shields.io/badge/tailwindcss-%2338B2AC.svg?style=for-the-badge&logo=tailwind-css&logoColor=white)
![Java](https://img.shields.io/badge/java-%23ED8B00.svg?style=for-the-badge&logo=openjdk&logoColor=white)
![Spring](https://img.shields.io/badge/spring-%236DB33F.svg?style=for-the-badge&logo=spring&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-000?style=for-the-badge&logo=postgresql)
![AWS](https://img.shields.io/badge/AWS-000.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Git](https://img.shields.io/badge/Git-20232A?style=for-the-badge&logo=git&logoColor=F05032)
![Jira](https://img.shields.io/badge/Jira-20232A?style=for-the-badge&logo=jira&logoColor=0052CC)
![Figma](https://img.shields.io/badge/Figma-20232A?style=for-the-badge&logo=figma&logoColor=F24E1E)

<br>

<span id="instalacao">

## ⬇ Guia de Instalação

Este guia oferece instruções detalhadas sobre como baixar, configurar e executar este projeto em sua máquina local.

### Pré-requisitos
- **VSCode**: Editor de código para visualização e edição do projeto. [Baixe o VSCode](https://code.visualstudio.com/download)
- **PostgreSQL**: Banco de dados para armazenar informações necessárias ao sistema. [Baixe o PostgreSQL](https://www.postgresql.org/download/)

<span id="equipe">

## 👤 Equipe

| Função | Nome | LinkedIn | GitHub |
|---|---|---|---|
| Product Owner | Gabriel Calebe De Oliveira Medeiros | [LinkedIn](https://www.linkedin.com/in/gabriel-medeiros-516ab3325/) | [GitHub](https://github.com/gbmedeiros00) |
| Scrum Master | Ana Júlia Gaspar Brito | [LinkedIn](https://www.linkedin.com/in/anajgaspar/) | [GitHub](https://github.com/anajgaspar) |
| Team Member | Ana Beatriz da Silva Coelho | [LinkedIn](https://www.linkedin.com/in/abeatrizcoelho/) | [GitHub](https://github.com/abeatrizdscoelho) |
| Team Member | Emmanuel Jun de Noronha Yokoyama | [LinkedIn](https://www.linkedin.com/in/emmanuelyokoyama/) | [GitHub](https://github.com/EmmanuelJYokoyama) |
| Team Member | Issami Umeoka | [Linkedin](https://www.linkedin.com/in/issami-umeoka-786716226/) | [GitHub](https://github.com/IssamiU) |
| Team Member | Otávio Vianna Lima | [Linkedin](https://www.linkedin.com/in/ot%C3%A1vio-vianna-lima-1b26a932a?utm_source=share_via&utm_content=profile&utm_medium=member_ios) | [GitHub](https://github.com/tuzzooz) |
| Team Member | Pedro Henrique Martins | [Linkedin](https://www.linkedin.com/in/pedrohmartinsss) | [GitHub](https://github.com/pedro-h-martins) |
| Team Member | Tatiane Oliveira | [LinkedIn](https://www.linkedin.com/in/tatiane-oliveira-332155377/) | [GitHub](https://github.com/TatianeOliveira8) |
| Team Member | Tiago dos Santos Freitas | [Linkedin](http://linkedin.com/in/tiago-freitas-74730b2a9) | [GitHub](https://github.com/tiagow2) |

<br>

→ <a href="#sumario"> Voltar ao topo </a>
