#!/usr/bin/env python3
"""
Simulador de Balanceamento Matemático — Neon Void
Analisa as curvas de escala de HP dos inimigos vs. Dano de Clique e DPS das Torretas ao longo das waves.
"""

def enemy_hp(wave, kind_base, play_time=0):
    scale_hp = 1 + (wave - 1) * 0.55 + pow(wave - 1, 1.55) * 0.09 + play_time * 0.008
    return round(kind_base * scale_hp)

def main():
    print("=" * 65)
    print("  SIMULAÇÃO DE ESCALA DE HP E DANO POR WAVE (NEON VOID)")
    print("=" * 65)
    print(f"{'Wave':<6} | {'Quadrado':<10} | {'Triângulo':<10} | {'Hexágono':<10} | {'Boss':<12}")
    print("-" * 65)

    waves = [1, 5, 10, 15, 20, 25, 30, 40, 50]
    for w in waves:
        sq = enemy_hp(w, 6)
        tri = enemy_hp(w, 4)
        hex_hp = enemy_hp(w, 22)
        boss_base = 160 * (1 + w * 0.06)
        boss = enemy_hp(w, boss_base) if w % 5 == 0 else "-"
        print(f"{w:<6} | {sq:<10} | {tri:<10} | {hex_hp:<10} | {str(boss):<12}")

    print("=" * 65)
    print("Recomendação:")
    print("- Assegurar que os custos de upgrades in-run permitam DPS compatível até wave 25.")
    print("- Na wave 30+, o escalonamento exponencial de pow(wave-1, 1.55) requer múltiplos slots de torre.")

if __name__ == "__main__":
    main()
