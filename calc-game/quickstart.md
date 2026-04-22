# hcCalc - Manual do Usuário e Documentação

Bem-vindo ao **hcCalc**, uma calculadora poderosa e personalizável desenvolvida em Love2D, projetada especialmente para consoles portáteis focados em jogos retrô e sistemas FOSS (Free and Open Source Software). Este aplicativo transforma seu console em uma ferramenta utilitária robusta, utilizando o layout padrão de controles (estilo PS1) para uma navegação fluida, dispensando o uso de mouse e teclado.

---

## 🎮 Controles e Navegação

A interface do hcCalc foi construída para ser operada inteiramente através de um gamepad. Use o D-Pad ou o Analógico Esquerdo para navegar pela interface como se estivesse selecionando itens em um jogo.

| Botão / Comando | Ação no hcCalc |
| :--- | :--- |
| **D-Pad / Analógico Esq.** | Move o cursor pela grade de botões da calculadora. |
| **Botão A** | Pressiona a tecla atualmente selecionada na tela. |
| **Botão B** | Funciona como *Backspace*, apagando o último dígito inserido. |
| **Botão X** | Funciona como *ANS*, copiando o resultado da última expressão para o registro atual. |
| **Botão Y** | Atalho rápido para a tecla `=`, avaliando a expressão imediatamente. |
| **L1 (Left Shoulder)** | Alterna para o **próximo** modo/layout de calculadora. |
| **L2 (Left Trigger)** | Alterna para o modo/layout **anterior**. |
| **R1 (Right Shoulder)** | Move a casa decimal (ponto flutuante) para a **esquerda**. |
| **R2 (Right Trigger)** | Move a casa decimal (ponto flutuante) para a **direita**. |

---

## 🧮 Modos da Calculadora

O hcCalc possui três perfis de interface, acessíveis alternando os botões de ombro (L1/L2). O modo atual é exibido no topo da tela.

1. **Normal (`norm`):** Contém as operações matemáticas do dia a dia. Inclui números de 0 a 9, operações básicas (+, -, *, ÷), inversão de sinal (±) e parênteses.
2. **Científica (`sci`):** Focada em operações matemáticas avançadas. Inclui funções trigonométricas (seno, cosseno, tangente e suas inversas), logaritmos, fatoriais, constantes matemáticas (π, e), exponenciação e raízes.
3. **Programador (`comp`):** Destinada a operações lógicas e conversão de bases numéricas (Binário, Octal, Decimal, Hexadecimal). Inclui operações bit a bit como AND, OR, NOT, XOR e deslocamento de bits (« e »).

---

## 💡 Conceitos Principais e Regras de Operação

Para tirar o máximo proveito do hcCalc, é importante entender como o mecanismo interno avalia as suas expressões. O aplicativo utiliza **Notação Infixa**, o que significa que você digita as expressões da mesma forma que as escreve no papel.

### 1. Limpando a Tela (C vs AC)
* **Botão C (Clear):** Limpa apenas o registro atual (o número que você está digitando no momento).
* **Botão AC (All Clear):** Limpa toda a tela, zerando o registro e apagando todo o buffer do histórico de expressões. Se você pressionar `C` duas vezes seguidas, ele atuará como `AC`.

### 2. Multiplicação Implícita
Você não precisa digitar o símbolo de multiplicação `*` toda vez que usar parênteses ou funções. O hcCalc insere a multiplicação automaticamente nos seguintes casos:
* Um número seguido de parênteses: `5(2)` é lido como `5 * (2)`.
* Um parêntese fechado ou fatorial seguido de número: `(3)2` vira `(3) * 2`.
* Um número antes de uma função científica: `3sin(30)` é avaliado como `3 * sin(30)`.

### 3. Raízes e Fatoriais
* **Raiz Enésima (√):** O símbolo de raiz no hcCalc **não** assume a raiz quadrada por padrão. Você deve sempre fornecer o índice da raiz à esquerda e o radicando à direita. Para calcular a raiz quadrada de 4, você deve digitar `2√4`.
* **Fatorial (!):** O fatorial é uma operação pós-fixada. Ele deve sempre vir após um número ou parêntese fechado (ex: `5!`).

### 4. Modo Programador e Bases Numéricas
Ao utilizar o modo `comp`, as regras de inserção de números mudam com base no sistema selecionado:
* Os botões numéricos só estarão ativos se o número existir na base atual (ex: na base Binária, apenas `0` e `1` funcionam).
* Se a base Hexadecimal (`HEX`) estiver ativa, botões e atalhos específicos atuarão como as letras de `A` a `F`.
* Em operações lógicas, o número `1` é o análogo para *Verdadeiro* (True) e o número `0` para *Falso* (False).

---

## 📝 Exemplo de Uso Prático

**Objetivo:** Calcular a expressão $3 + 5 \times \sin(90)$
1. No modo `norm`, pressione **3**, depois **+**, depois **5**.
2. Pressione **L1** para trocar para o modo `sci`.
3. Pressione a tecla **sin**. *(Opcional: A calculadora já entenderá a multiplicação implícita e adicionará o `*` e o `(` para você)*.
4. Digite **90** e feche o parêntese **)**.
5. Pressione o botão **Y** do seu gamepad ou navegue até a tecla **=** e aperte **A** para ver o resultado.