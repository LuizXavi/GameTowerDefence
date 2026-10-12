---
name: incremental-math-balancer
description: Modelagem matemática e curvas de progressão exponencial para jogos idle e tower defense
---

# Incremental Math Balancer Skill

## Curvas de Crescimento
1. **Vida dos Inimigos**:
   - Fórmula: \( HP(w) = HP_{base} \times (1.14)^w + w \times 12 \)
   - Chefes: Multiplicador de \( 4.5\times \) a cada onda múltipla de 5.
2. **Custo de Upgrades**:
   - Fórmula: \( Cost(lvl) = Cost_{base} \times (Rate)^{lvl} \)
   - Taxas ideais:
     - Clique: 1.58
     - Torre Automática: 1.68
     - Núcleo Crítico: 1.80
     - Escudo: 1.72
3. **Formatação de Escala**:
   - Utilize a classe `NumberFormat` para valores acima de 1.000:
     - K (mil), M (milhão), B (bilhão), T (trilhão), Qa, Qi.
