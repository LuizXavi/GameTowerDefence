---
name: game-balance
description: Guia de análise e calibração matemática das curvas de HP, dano, custo de ouro, fragmentos e ritmo de waves usando simulação determinística.
---

# Skill: Game Balance Runbook

Instruções para calibrar as métricas de combate e economia no Neon Void.

## 1. Simulação Matemática em Python
O projeto conta com o simulador determinístico `NeonVoidGodot/tools/simulate_balance.py`.

Para executar a análise de curvas até a wave 50:
```powershell
.\neon.bat balance
```
Ou diretamente:
```powershell
python NeonVoidGodot/tools/simulate_balance.py
```

## 2. Princípios de Curva do Neon Void
- **HP dos Inimigos**: Escala com base em `wave ** 1.35` para inimigos comuns e multiplicadores dedicados para mini-bosses (5x) e bosses de marco (15x a 30x).
- **Ganho de Ouro**: Acelera através de combos e upgrades econômicos para permitir compra gradual dos slots de hangar (1 a 7).
- **Custo de Pesquisas**: Reduzido pelas pesquisas de *Eficiência de Fragmentos* no laboratório (-10%/nível).
- **Tempo de Pesquisa**: Acelerado pelo *Acelerador de Síntese* (-18%/nível) e *Matriz de Ressonância* (-8%/nível).
