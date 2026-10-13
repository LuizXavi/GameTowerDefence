---
name: godot-testing
description: Procedimentos de execução, depuração e criação de testes automatizados lógicos e de interface gráfica no Godot 4.7 para Neon Void.
---

# Skill: Godot Testing Runbook

Este runbook instrui como rodar, criar e depurar testes no Neon Void.

## Como Executar

### 1. Validação Completa (Lógica + UI)
Execute via terminal:
```powershell
.\neon.bat validate
```

### 2. Apenas Testes Lógicos (Headless, ultrarrápido)
```powershell
.\neon.bat test-logic
```
Comando equivalente:
```powershell
& "C:\Users\hultr\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --path NeonVoidGodot --script res://tests/test_game.gd
```

### 3. Apenas Testes Gráficos de UI
```powershell
.\neon.bat test-ui
```
Comando equivalente:
```powershell
& "C:\Users\hultr\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path NeonVoidGodot --script res://tests/test_ui.gd -- --test-mode
```

## Como Adicionar Novos Testes

- **Em `test_game.gd`**:
  Use a função auxiliar `check(condição, "Descrição do teste")`.
  Ao criar saves de teste em disco, sempre limpe os arquivos `.tmp` e `.bak` gerados no final.
- **Em `test_ui.gd`**:
  Use `expect(condição, "Descrição do teste")` e helpers como `await click(position)` e `await key(KEY_ESCAPE)`.
