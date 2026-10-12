# Fluxo de trabalho dos agentes

## 1. Coordenar

O coordenador cria uma tarefa a partir de `TASK_TEMPLATE.md`, define o comportamento observável, nomeia os responsáveis e identifica arquivos compartilhados. O trabalho só começa após esclarecer os contratos entre as áreas.

## 2. Implementar em paralelo

Trilhas que podem ocorrer juntas:

- Gameplay trabalha em regras e testes de lógica.
- UI prepara a apresentação contra uma interface de dados combinada.
- Efeitos prepara sinais e feedback visual/sonoro.
- Persistência trabalha no schema e em fixtures temporárias.

Não faça edições simultâneas em `main.gd` sem dividir funções ou regiões com clareza.

## 3. Integrar

O coordenador:

1. Confere as interfaces entre arquivos.
2. Resolve conflitos preservando a fonte autoritativa.
3. Importa o projeto no Godot.
4. Executa testes de lógica.
5. Executa testes gráficos.
6. Inspeciona capturas.

## 4. Revisar

O agente de qualidade relata:

- comportamento esperado;
- resultado observado;
- passos de reprodução;
- arquivo ou sistema provável;
- evidência visual quando necessário;
- gravidade.

Qualidade não altera regras para fazer um teste passar. Falhas voltam ao agente responsável.

## 5. Entregar

O coordenador registra:

- o que mudou;
- por que mudou;
- testes executados;
- compatibilidade do save;
- riscos ou limitações.

## Matriz de dependências

| Mudança | Gameplay | UI | Efeitos | Persistência | Qualidade |
|---|---:|---:|---:|---:|---:|
| Novo inimigo | principal | indicador opcional | principal | — | obrigatório |
| Novo upgrade de partida | principal | principal | apoio | — | obrigatório |
| Metaprogressão | apoio | principal | apoio | principal | obrigatório |
| Novo boss | principal | apoio | principal | — | obrigatório |
| Menu novo | — | principal | apoio | conforme dados | obrigatório |
| Alteração de schema | apoio | conforme exibição | — | principal | obrigatório |

## Escalonamento

Pare e devolva ao coordenador quando:

- a tarefa exige alterar uma fórmula não mencionada;
- dois agentes precisam editar a mesma função;
- um save antigo seria descartado;
- a solução muda a identidade visual;
- os critérios de aceite se contradizem;
- o teste falha por um comportamento fora do escopo.

