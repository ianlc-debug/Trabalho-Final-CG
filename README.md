# 🏰 Castelo vs OVNIs 🛸

## Sobre o Jogo

**Castelo vs OVNIs** é um jogo do gênero **Tower Defense** desenvolvido utilizando a **Godot Engine**. O jogador deve defender seu castelo contra uma invasão de OVNIs que avançam em ondas sucessivas através de dois cenários temáticos: **Primavera** e **Inverno**.

Ao longo da partida, o jogador precisa construir e aprimorar estruturas defensivas para impedir que os inimigos alcancem a base. A estratégia de posicionamento, gerenciamento de recursos e evolução das construções é essencial para sobreviver às ondas e derrotar o chefe de cada fase.

---

## Objetivo

O objetivo do jogo é proteger o castelo contra as ondas de OVNIs e sobreviver até o final de cada fase.

O jogador vence ao:

* Resistir às 5 ondas de inimigos presentes no mapa;
* Derrotar o inimigo chefe da fase.

O jogador perde caso:

* A vida do castelo seja reduzida a zero;
* O chefe alcance a base do jogador.

---

## Fases

O jogo possui dois mapas jogáveis:

### Primavera

Primeira fase do jogo, onde o jogador enfrenta as primeiras ondas de OVNIs e aprende as mecânicas básicas de construção, evolução e gerenciamento de recursos.

### Inverno

Segunda fase do jogo, apresentando um desafio maior e exigindo estratégias mais eficientes para lidar com os inimigos.

Cada fase possui:

* 5 ondas de inimigos;
* Diferentes tipos de OVNIs;
* Um chefe na onda final.

---

## Construções

O jogador possui quatro tipos de construções disponíveis para defender o castelo.

### Canhão

Estrutura ofensiva com dano médio e alcance médio.

**Características:**

* Dano médio;
* Alcance médio;
* Taxa de disparo mediana.

### Balista

Estrutura de longo alcance que permite atacar inimigos rapidamente antes que eles se aproximem da base.

**Características:**

* Dabo baixo;
* Longo alcance;
* Taxa de disparo alta.

### Catapulta

Estrutura capaz de causar alto dano a longo alcance.

**Características:**

* Dano alto;
* Longo alcance;
* Taxa de disparo baixa.

### Mina de Ouro

Construção responsável pela geração de ouro ao longo da partida.

**Características:**

* Produção contínua de ouro;
* Pode ser evoluída para aumentar a geração de recursos.

---

## Sistema de Ouro

O ouro é o principal recurso do jogo e pode ser utilizado para:

* Construir novas estruturas;
* Evoluir torres defensivas;
* Evoluir minas de ouro;
* Fortalecer a defesa do castelo ao longo da partida.

O gerenciamento eficiente do ouro é fundamental para o sucesso do jogador.

---

## Sistema de Evolução

Todas as construções podem ser aprimoradas utilizando ouro.

Ao evoluir uma estrutura, seus atributos são melhorados, permitindo que ela se torne mais eficiente durante as ondas mais difíceis.

As melhorias podem incluir:

* Aumento de dano;
* Aumento de alcance;
* Maior eficiência geral;
* Maior produção de ouro (para as minas).

---

## Sistema de Venda

O jogador também pode vender qualquer construção já posicionada no mapa.

Podem ser vendidas:

* Torres defensivas;
* Minas de ouro.

Essa funcionalidade permite reorganizar a estratégia ao longo da partida e adaptar a defesa conforme as necessidades de cada onda.

---

## Inimigos

Durante as fases, o jogador enfrentará quatro tipos diferentes de OVNIs.

### OVNI Normal

Inimigo padrão com atributos equilibrados.

### OVNI Rápido

Possui alta velocidade de movimentação, tornando-se uma ameaça difícil de interceptar.

### OVNI Tank

Inimigo com grande quantidade de vida e alta resistência.

### OVNI Chefe (Boss)

O inimigo mais poderoso do jogo.

Possui atributos superiores aos demais inimigos e representa o maior desafio da fase.

Caso alcance a base do jogador, a partida termina imediatamente com derrota.

---

## Controles

O jogo utiliza exclusivamente o **mouse** para todas as interações.

Com ele, o jogador pode:

* Construir estruturas;
* Selecionar construções;
* Evoluir torres;
* Evoluir minas de ouro;
* Vender construções;
* Navegar pelos menus;
* Interagir com toda a interface do jogo.

Não é necessário utilizar o teclado durante a jogabilidade.

---

## Tecnologias Utilizadas

* Godot Engine
* GDScript

---

## Como Executar o Projeto

### Pré-requisitos

* Godot Engine instalada.

### Passos para execução

1. Clone o repositório:

```bash
git clone https://github.com/ianlc-debug/Trabalho-Final-CG.git
```

2. Abra a Godot Engine.

3. Clique em **Import**.

4. Selecione o arquivo `project.godot`.

5. Execute o projeto pressionando **F5** ou clicando em **Run Project**.

---

## Condições de Vitória

* Sobreviver às 5 ondas de cada fase;
* Impedir que os inimigos destruam o castelo;
* Derrotar o chefe da fase.

---

## Condições de Derrota

* A vida do castelo chegar a zero;
* O chefe alcançar a base do jogador.

---

## Estrutura do Projeto

```text
trabalho-final-cg/
├── Resources/
├── Scenes/
├── assets/
├── scripts/
├── .editorconfig
├── .gitattributes
├── cooldown_debug.log
├── icon.svg
├── icon.svg.import
├── main.tscn
├── node_3d.gd
├── node_3d.gd.uid
└── project.godot
```

---

## Equipe

* Antônio Matheus da Costa Queiroz
* Augusto Rodrigues Paz Gregório
* Davi Gomes Rocha
* Davi Moura Guedes
* Ian Lopes Costa
* José Arthur Gomes Azevedo
* Marcelo Henrique Teixeira de Souza Alves
