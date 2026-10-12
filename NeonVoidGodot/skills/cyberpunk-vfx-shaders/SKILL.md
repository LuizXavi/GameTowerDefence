---
name: cyberpunk-vfx-shaders
description: Criação de shaders 2D, scanlines, vinheta, aberração cromática e síntese de áudio procedural
---

# Cyberpunk VFX & Shaders Skill

## Diretrizes de Efeitos Visuais
1. **Paleta de Cores Neon Cyberpunk**:
   - Rosa Neon: `#ff2bd6`
   - Ciano Elétrico: `#22e6ff`
   - Verde Radioativo: `#b6ff2e`
   - Âmbar Solar: `#ffb02e`
   - Vermelho Laser: `#ff3355`
2. **Shaders de Pós-Processamento**:
   - Efeito CRT com scanlines sutis em `SCREEN_UV`.
   - Aberração cromática reativa a impacto ou ativação de habilidade Nova.
3. **Áudio Procedural**:
   - `SoundManager`: Síntese dinâmica de ondas senoidais e ruído com decaimento exponencial direto em `AudioStreamWAV`.
