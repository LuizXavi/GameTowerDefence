---
name: neon-void-modules-expansion
description: Guia de arquitetura, implementação e balanceamento de novos módulos de torre (ex: Sísmica, Feixe Contínuo, Minas) e interações elementais.
---

# Expansão de Módulos de Torre — Neon Void

Use esta skill para criar novos módulos de torre e reações em cadeia no Neon Void.

## Requisitos de Implementação de um Novo Módulo
1. **ID Estável:** Definir um identificador único minúsculo (ex: `pulse`, `laser`, `mine`) em `TOWER_MODULE_IDS`.
2. **Descoberta e Custo:**
   - Adicionar em `ScoreStore.MODULE_WAVES` a wave mínima de aparição no laboratório.
   - Adicionar em `ScoreStore.MODULE_COSTS` a família de fragmento e quantidade requerida.
3. **Comportamento em Combate (`VoidState.auto_attack`):**
   - Definir lógica de alcance, cadência, penetração ou efeitos de status (ex: lentidão, stun, corrente).
   - Efeitos que afetam múltiplos alvos devem respeitar alvos intangíveis (`ghosted`).
4. **Apresentação Audiovisual (`arena.gd` e `main.gd`):**
   - Atribuir uma cor e geometria visual única no cano da torreta e no rastro do projétil/laser.
   - Incluir dados de descrição e nome em `MODULE_INFO` em `main.gd`.
5. **Persistência Retrocompatível:**
   - Se adicionado a `ScoreStore.tower_modules`, garantir que a migração de save mantenha o novo módulo como `false` para jogadores existentes até que o descubram/pesquisem.
