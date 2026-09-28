# Sprint 1: 07/09/2026 - 27/09/2026

O projeto baseia-se no desenvolvimento de uma aplicação multiplataforma que utilizará informações geográficas de ativos da rede elétrica, obtidas de bases públicas (BDGD), em conjunto com parâmetros de cobertura de radiofrequência, para apoiar o planejamento dessa infraestrutura.
<br>Dado um conjunto de pontos que precisam de cobertura e um conjunto potencialmente grande de locais candidatos à instalação de gateways, o sistema deverá avaliar e propor configurações eficientes.

<br>

## 🎯 Objetivos da Sprint
A primeira sprint foi dedicada ao desenvolvimento das páginas principais do sistema. Além disso, foi implementado o módulo de autenticação e login funcional com suporte a JWT, assegurando o controle de acesso dos usuários. Para viabilizar a entrada e a preparação das informações, entregou-se a funcionalidade de importação de arquivos no formato .zip e a configuração completa da pipeline de ETL (Extração, Transformação e Carga).

### Backlog da Sprint

| ID  | Requisito | Prioridade | User Story | Story Points |
|-----|-----------|------------|------------|--------------|
| US1 | RF01 | Alta | Como usuário, quero importar as BDGDs, para poder realizar simulações em determinada região. | 8 |
| US2 | RF02, RF03 | Alta | Como usuário, quero definir um ponto central e um raio de atuação dentro da área da BDGD importada, para delimitar a área de busca onde o sistema vai avaliar candidatos a gateway e calcular a cobertura de RF de cada um. | 8 |
| US3 | RF02, RF03 | Alta | Como usuário, quero definir a meta mínima de cobertura e o número máximo de gateways antes de rodar um cenário, para garantir que a simulação respeite os limites e objetivos definidos. | 8 |
| US4 | RF04 | Alta | Como usuário, quero ajustar os parâmetros de propagação de RF (frequência, potência de transmissão, sensibilidade do receptor, altura do gateway e altura do dispositivo) antes de rodar um cenário, para que a simulação reflita as características reais do enlace de rádio. | 5 |
| US5 | RF06 | Alta | Como usuário, quero visualizar os ativos elétricos combinados com a RF em um mapa, para poder visualizar quantos ativos a RF está cobrindo. | 8 |
| US6 | RF08 | Alta | Como usuário, quero ver indicadores de qualidade (% de cobertura por tipo de ativo, nº de gateways, custo, tempo de processamento) ao final de um cenário, para avaliar a qualidade e a viabilidade da simulação. | 3 |

<br>

## ☑️ Entrega

Veja a entrega da primeira sprint a seguir:

<a href='https://youtu.be/1CPARC5iv88'>Vídeo do Projeto</a>

<br>

## 📈 Métricas do Time

O acompanhamento de atividades, se encontra na imagem adiante, que contém o gráfico Burndown gerado pela equipe, onde o eixo X são os dias trabalhados na sprint e os valores do eixo Y representam as entregas e esforços realizados com o passar do tempo, incluindo as atividades desenvolvidas e seus responsáveis.

<img width="1550" height="756" alt="Burndown Chart Sprint 1" src="https://github.com/user-attachments/assets/ad12d236-8882-47c0-a076-db6169c649e1" />

---
