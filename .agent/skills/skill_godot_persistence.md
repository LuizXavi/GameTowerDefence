# SKILL: Persistência de Dados e Migração (SaveStore)

## Manipulação Segura de Estado
1. **Separação Estado vs. Visão:** A lógica de pontuação e atributos pertence aos dados (`SaveStore` ou `VoidState`), não aos nós visuais.
2. **Versionamento de Schema:** Toda vez que a estrutura do save (JSON) mudar, adicione um novo bloco condicional no método `migrate(data: Dictionary)` incrementando o `SCHEMA_VERSION` sequencialmente.
3. **Validação Estrita:** Antes de carregar ou salvar, passe os dados pela função `valid(data: Variant) -> bool` para garantir que valores corrompidos ou tipos errados (ex: `null` em vez de `int`) não travem o jogo.
4. **Tipagem Pós-JSON:** O Godot lê números em JSON como `float`. Faça o cast explícito `int(value)` ao transferir os dados do dicionário carregado para arrays estritamente tipados como `Array[int]`.
