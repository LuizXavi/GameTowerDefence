#!/usr/bin/env python3
import sys
import math

def simulate_growth(base_cost, mult, target_level):
    print(f"--- Simulação de Escala de Custo (Base: {base_cost}, Fator: {mult}) ---")
    current_cost = base_cost
    total_spent = 0
    for lvl in range(1, target_level + 1):
        total_spent += current_cost
        if lvl <= 5 or lvl % 10 == 0 or lvl == target_level:
            print(f"Nível {lvl:3d}: Custo = {current_cost:12.2e} | Gasto Acumulado = {total_spent:12.2e}")
        current_cost *= mult

if __name__ == "__main__":
    if len(sys.argv) >= 4:
        simulate_growth(float(sys.argv[1]), float(sys.argv[2]), int(sys.argv[3]))
    else:
        # Exemplo padrão para módulos do Neon Void
        simulate_growth(10, 1.35, 30)
