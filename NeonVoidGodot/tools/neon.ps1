# ==============================================================================
# Neon Void — Master Automation Engine (Godot 4.7)
# ==============================================================================
param (
    [Parameter(Position=0)]
    [string]$Action = "menu",
    [switch]$SkipUi
)

$ErrorActionPreference = "Stop"

$GodotBin = "C:\Users\hultr\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
if (-not (Test-Path $GodotBin)) {
    $GodotGui = "C:\Users\hultr\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
    if (Test-Path $GodotGui) {
        $GodotBin = $GodotGui
    } else {
        Write-Error "Godot binario nao encontrado em: $GodotBin"
        exit 1
    }
}

$RepoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$ProjectPath = (Resolve-Path "$PSScriptRoot\..").Path
$ToolsDir = "$ProjectPath\tools"

function Print-Banner {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "         NEON VOID // MASTER AUTOMATION ENGINE            " -ForegroundColor Magenta
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " Godot 4.7 | Multi-Agent Architecture | Cyberpunk TD      " -ForegroundColor DarkGray
    Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
}

function Run-Clean {
    Write-Host "[CLEAN] Limpando arquivos temporarios e caches residuais..." -ForegroundColor Yellow
    $CleanCount = 0
    Get-ChildItem -Path $RepoRoot -Recurse -Include *.tmp, *.bak, *.log -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item -Force $_.FullName
        $CleanCount++
    }
    $OrphanUpdate = "$ProjectPath\addons\.godot_ai_update"
    if (Test-Path $OrphanUpdate) {
        Remove-Item -Recurse -Force $OrphanUpdate
        $CleanCount++
    }
    Write-Host "[CLEAN] Concluido: $CleanCount item(ns) limpo(s)." -ForegroundColor Green
}

function Run-Validate {
    Print-Banner
    Write-Host "[1/3] Importacao Headless do Godot..." -ForegroundColor Yellow
    & $GodotBin --headless --path $ProjectPath --editor --import --quit
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Falha na importacao do Godot (ExitCode: $LASTEXITCODE)"
        exit $LASTEXITCODE
    }

    Write-Host "[2/3] Testes Logicos de Gameplay & Saves (test_game.gd)..." -ForegroundColor Yellow
    & $GodotBin --headless --path $ProjectPath --script res://tests/test_game.gd
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Falha nos testes logicos (ExitCode: $LASTEXITCODE)"
        exit $LASTEXITCODE
    }

    if (-not $SkipUi) {
        Write-Host "[3/3] Testes Graficos, Modais e Layout (test_ui.gd)..." -ForegroundColor Yellow
        & $GodotBin --path $ProjectPath --script res://tests/test_ui.gd -- --test-mode
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Falha nos testes de UI (ExitCode: $LASTEXITCODE)"
            exit $LASTEXITCODE
        }
    } else {
        Write-Host "[3/3] Teste grafico ignorado (-SkipUi)." -ForegroundColor DarkGray
    }

    Write-Host "=== SUCESSO: Todos os testes passaram e o projeto esta integro! ===" -ForegroundColor Green
}

function Run-TestLogic {
    Write-Host "[TEST-LOGIC] Executando testes deterministicos de combate/saves..." -ForegroundColor Yellow
    & $GodotBin --headless --path $ProjectPath --script res://tests/test_game.gd
}

function Run-TestUi {
    Write-Host "[TEST-UI] Executando suíte de testes de interface..." -ForegroundColor Yellow
    & $GodotBin --path $ProjectPath --script res://tests/test_ui.gd -- --test-mode
}

function Run-Play {
    Write-Host "[PLAY] Iniciando Neon Void no Godot..." -ForegroundColor Cyan
    Start-Process -FilePath $GodotBin -ArgumentList "--path `"$ProjectPath`""
}

function Run-Balance {
    Write-Host "[BALANCE] Executando simulador de curvas matematicas (Python)..." -ForegroundColor Yellow
    $SimScript = "$ToolsDir\simulate_balance.py"
    if (Test-Path $SimScript) {
        python $SimScript
    } else {
        Write-Warning "Arquivo simulate_balance.py nao encontrado."
    }
}

function Run-Monitor {
    Write-Host "[MONITOR] Abrindo Escritorio Virtual dos Agentes..." -ForegroundColor Cyan
    $MonitorHtml = "$ToolsDir\agent_monitor.html"
    Start-Process $MonitorHtml
}

function Run-Status {
    Print-Banner
    Write-Host ">> STATUS DO REPOSITORIO:" -ForegroundColor Yellow
    git -C $RepoRoot status -s
    Write-Host ""
    Write-Host ">> ULTIMOS COMMITS:" -ForegroundColor Yellow
    git -C $RepoRoot log -n 3 --oneline
    Write-Host ""
    Write-Host ">> AGENTES CADASTRADOS:" -ForegroundColor Yellow
    Get-ChildItem -Directory "$RepoRoot\.agents\agents" | ForEach-Object {
        Write-Host " - $($_.Name)" -ForegroundColor Cyan
    }
}

function Run-Sync {
    Print-Banner
    Run-Clean
    Run-Validate
    Write-Host "[SYNC] Projeto validado e pronto para versionamento." -ForegroundColor Green
}

switch ($Action.ToLower()) {
    "validate"   { Run-Validate }
    "play"       { Run-Play }
    "run"        { Run-Play }
    "test-logic" { Run-TestLogic }
    "test-ui"    { Run-TestUi }
    "balance"    { Run-Balance }
    "clean"      { Run-Clean }
    "status"     { Run-Status }
    "sync"       { Run-Sync }
    "monitor"    { Run-Monitor }
    "menu" {
        Print-Banner
        Write-Host "Escolha uma opcao:" -ForegroundColor Yellow
        Write-Host " 1. Validar projeto completo (Testes Logicos + UI)"
        Write-Host " 2. Iniciar Jogo (Godot)"
        Write-Host " 3. Testes Logicos Apenas (Headless)"
        Write-Host " 4. Testes de UI Apenas"
        Write-Host " 5. Simular Balanceamento (Python)"
        Write-Host " 6. Limpar Arquivos Temporarios"
        Write-Host " 7. Status do Projeto & Agentes"
        Write-Host " 8. Abrir Escritorio Virtual dos Agentes"
        Write-Host " 0. Sair"
        Write-Host ""
        $Choice = Read-Host "Digite o numero da opcao desejada"
        switch ($Choice) {
            "1" { Run-Validate }
            "2" { Run-Play }
            "3" { Run-TestLogic }
            "4" { Run-TestUi }
            "5" { Run-Balance }
            "6" { Run-Clean }
            "7" { Run-Status }
            "8" { Run-Monitor }
            default { Write-Host "Saindo..." }
        }
    }
    default {
        Write-Host "Acao desconhecida: $Action" -ForegroundColor Red
        Write-Host "Uso: neon.bat [validate|play|test-logic|test-ui|balance|clean|status|sync|monitor]"
    }
}
