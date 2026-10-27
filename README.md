# Sprint 2: 05/10/2026 - 25/10/2026

O projeto baseia-se no desenvolvimento de uma aplicação multiplataforma que utilizará informações geográficas de ativos da rede elétrica, obtidas de bases públicas (BDGD), em conjunto com parâmetros de cobertura de radiofrequência, para apoiar o planejamento dessa infraestrutura.
<br>Dado um conjunto de pontos que precisam de cobertura e um conjunto potencialmente grande de locais candidatos à instalação de gateways, o sistema deverá avaliar e propor configurações eficientes.

<br>

## 🎯 Objetivos da Sprint
A segunda sprint foi dedicada ao desenvolvimento de APIs essenciais para o ecossistema de simulações, incluindo a criação de rotas para cenários salvos por região e geração de relatórios, além da integração da exportação de relatórios diretamente na tela de resultados. Também focamos em melhorias de robustez e performance no tratamento de dados, implementando o suporte a múltiplos formatos de arquivos na importação (CSV, XLS e JSON), a otimização e agrupamento de BDGDs, e a otimização de renderização dos ativos no mapa.

### Backlog da Sprint

| ID  | Requisito | Prioridade | User Story | Story Points |
|-----|-----------|------------|------------|--------------|
| US1 | RF01 | Alta | Como usuário, quero importar as BDGDs, para poder realizar simulações em determinada região. | 8 |
| US2 | RF02, RF03 | Alta | Como usuário, quero definir um ponto central e um raio de atuação dentro da área da BDGD importada, para delimitar a área de busca onde o sistema vai avaliar candidatos a gateway e calcular a cobertura de RF de cada um. | 8 |
| US3 | RF06 | Alta | Como usuário, quero visualizar os ativos elétricos combinados com a RF em um mapa, para poder visualizar quantos ativos a RF está cobrindo. | 8 |
| US4 | RF06, RNF06 | Média | Como usuário, quero salvar e revisitar cenários anteriores organizados por região, para comparar resultados e reaproveitar simulações já realizadas. | 5 |
| US5 | RF07 | Média | Como usuário, quero exportar os resultados de um cenário (mapa + indicadores) em um relatório, para compartilhar com o parceiro. | 5 |
| US6 | RNF02 | Baixa | Como usuário, quero acessar um manual do sistema, para entender como utilizar as principais funcionalidades. | 3 |

<br>

## ☑️ Entrega

Veja a entrega da segunda sprint a seguir:

<a href='https://youtu.be/7XUs_1N08q8'>Vídeo do Projeto</a>

<br>

## 📈 Métricas do Time

O acompanhamento de atividades, se encontra na imagem adiante, que contém o gráfico Burndown gerado pela equipe, onde o eixo X são os dias trabalhados na sprint e os valores do eixo Y representam as entregas e esforços realizados com o passar do tempo, incluindo as atividades desenvolvidas e seus responsáveis.

<img width="1550" height="756" alt="Burndown Chart Sprint 2" src="https://github.com/user-attachments/assets/13f30639-34d9-4dc0-9e50-d69cb7bd1ea8" />

---
