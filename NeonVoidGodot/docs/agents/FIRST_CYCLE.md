# Primeiro ciclo recomendado — variedade e metaprogressão

> Estado atual: a fundação da metaprogressão foi concluída com drops de peças, quatro pesquisas, schema 2 e Laboratório. As tarefas restantes deste ciclo devem reutilizar `docs/RESEARCH_SYSTEM.md` e ampliar o sistema existente.

## Objetivo

Dar mais decisões à partida e criar um motivo para jogar novamente.

## Entregas

1. Dois novos inimigos com comportamentos distintos.
2. Um boss com duas fases.
3. Escolha entre três melhorias ao completar determinadas ondas.
4. Fragmentos permanentes concedidos no game over.
5. Pequena árvore de melhorias permanentes.
6. Tela de estatísticas da partida.
7. Feedback ampliado para críticos e transição do boss.

## Distribuição

### Gameplay

- Extrair definições para Resources.
- Implementar os inimigos e o boss.
- Definir escolhas entre ondas.
- Calcular fragmentos no encerramento da partida.

### UI

- Criar modal de escolha sem permitir que inimigos avancem.
- Criar árvore de metaprogressão.
- Criar relatório da partida.

### Efeitos

- Criar leitura visual dos novos inimigos.
- Criar transição clara entre fases do boss.
- Diferenciar crítico comum de crítico destrutivo.

### Persistência

- Migrar schema 1 para schema 2.
- Guardar fragmentos, compras permanentes e IDs.
- Criar fixtures de migração e recuperação.

### Qualidade

- Testar partida completa até o boss.
- Validar uma única concessão de fragmentos.
- Testar migração, corrupção e backup.
- Verificar layouts e foco nos novos modais.

## Dependências

```text
Recursos de dados
   ├── novos inimigos ── efeitos ── teste visual
   ├── boss em fases ─── efeitos ── teste de combate
   └── upgrades entre ondas ── UI ── teste de pausa/foco

Fragmentos ── schema 2 ── árvore permanente ── teste de migração
```

## Gates

- Gate 1: contratos e Resources aprovados.
- Gate 2: gameplay testável sem UI final.
- Gate 3: UI e efeitos integrados.
- Gate 4: migração e fluxo completo aprovados.

