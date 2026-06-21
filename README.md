# 🏰 Castelo vs OVNIs

## Sobre o Jogo

**Castelo vs OVNIs** é um jogo do gênero **Tower Defense** desenvolvido na Godot Engine. O jogador assume a missão de proteger seu castelo contra uma invasão de OVNIs que avançam em ondas sucessivas por diferentes cenários.

O jogo possui duas fases temáticas:

* 🌸 Primavera
* ❄️ Inverno

Em cada fase, o jogador deve sobreviver a 5 ondas de inimigos, utilizando suas construções defensivas de forma estratégica para impedir que os OVNIs alcancem o castelo.

---

## Objetivo

O objetivo do jogador é defender o castelo durante todas as ondas de ataque presentes em cada mapa.

O jogador vence ao resistir às 5 ondas de inimigos e derrotar o chefe da fase.

O jogador perde caso:

* A vida do castelo seja reduzida a zero;
* O chefe consiga alcançar a base do jogador.

---

## Mecânicas do Jogo

Durante a partida, o jogador pode construir estruturas defensivas e econômicas para fortalecer sua defesa.

Cada estrutura possui características próprias, como **dano**, **alcance** e **função estratégica**, exigindo que o jogador escolha cuidadosamente onde e quando posicioná-las.

Além disso, as construções podem ser **evoluídas utilizando ouro**, aumentando sua eficiência ao longo da partida.

### Sistema de Ouro

O ouro é um recurso essencial para o progresso do jogador. Ele pode ser utilizado para:

* Construir novas estruturas;
* Evoluir torres defensivas;
* Evoluir minas de ouro;
* Fortalecer a defesa do castelo ao longo das ondas.

---

## Construções Disponíveis

### 🔫 Canhão

Torre de dano elevado e alcance médio, ideal para causar grandes quantidades de dano em inimigos individuais.

### 🏹 Balista

Possui longo alcance e boa precisão, sendo eficiente para atacar inimigos antes que se aproximem da base.

### 💣 Catapulta

Estrutura capaz de causar dano em área, tornando-se eficaz contra grupos de inimigos.

### ⛏️ Mina de Ouro

Responsável pela geração de ouro durante a partida. Pode ser evoluída para aumentar a produção de recursos e acelerar o desenvolvimento da defesa.

---

## Sistema de Evolução

Todas as estruturas do jogo podem ser aprimoradas através do uso de ouro.

Ao evoluir uma construção, o jogador obtém vantagens como:

* Maior dano;
* Maior alcance;
* Melhor desempenho geral;
* Aumento da produção de ouro (no caso das minas).

Esse sistema permite adaptar a estratégia conforme a dificuldade crescente das ondas.

---

## Inimigos

O jogador enfrentará quatro tipos de OVNIs durante a partida.

### 👽 OVNI Normal

Inimigo padrão com atributos equilibrados.

### ⚡ OVNI Rápido

Possui grande velocidade de movimentação, tornando-se uma ameaça difícil de interceptar.

### 🛡️ OVNI Tank

Inimigo resistente com alta quantidade de vida, exigindo maior poder de fogo para ser derrotado.

### 👑 OVNI Chefe (Boss)

O inimigo mais poderoso do jogo. Apresenta atributos superiores aos demais e representa o maior desafio de cada fase. Caso alcance a base do jogador, a partida é encerrada com derrota imediata.

---

## Fases

### 🌸 Primavera

Primeira fase do jogo, introduzindo as mecânicas básicas e os diferentes tipos de construções.

### ❄️ Inverno

Segunda fase do jogo, com dificuldade ampliada e desafios mais complexos para o jogador.

---

## Tecnologias Utilizadas

* Godot Engine
* GDScript

---

## Como Executar

### Pré-requisitos

* Godot Engine instalada

### Passos

1. Clone o repositório:

```bash
git clone https://github.com/seu-usuario/castelo-vs-ovnis.git
```

2. Abra a Godot Engine.

3. Importe o arquivo `project.godot`.

4. Execute o projeto pressionando **F5**.

---

## Condições de Vitória

* Sobreviver às 5 ondas de inimigos da fase.
* Impedir que os inimigos destruam o castelo.
* Derrotar o chefe da fase.

## Condições de Derrota

* A vida do castelo chegar a zero.
* O chefe alcançar a base do jogador.

---

## Equipe

* Nome dos integrantes

---

## Licença

Projeto desenvolvido para fins acadêmicos e educacionais.
