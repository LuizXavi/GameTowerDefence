# Script de Validação Automatizada — Neon Void (Godot 4.7)
param (
    [switch]$SkipUi
)

$ErrorActionPreference = "Stop"
$GodotBin = "C:\Users\hultr\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
$ProjectPath = (Resolve-Path "$PSScriptRoot\..").Path

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Neon Void — Validação de Projeto      " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n[1/3] Importação Headless..." -ForegroundColor Yellow
& $GodotBin --headless --path $ProjectPath --editor --import --quit
if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha na importação do projeto Godot (ExitCode: $LASTEXITCODE)"
}

Write-Host "`n[2/3] Executando Suíte Lógica (tests/test_game.gd)..." -ForegroundColor Yellow
& $GodotBin --headless --path $ProjectPath --script res://tests/test_game.gd
if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha nos testes de lógica (ExitCode: $LASTEXITCODE)"
}

if (-not $SkipUi) {
    Write-Host "`n[3/3] Executando Suíte Gráfica e UI (tests/test_ui.gd)..." -ForegroundColor Yellow
    & $GodotBin --path $ProjectPath --script res://tests/test_ui.gd -- --test-mode
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Falha nos testes gráficos de UI (ExitCode: $LASTEXITCODE)"
    }
} else {
    Write-Host "`n[3/3] Teste gráfico ignorado (-SkipUi especificado)." -ForegroundColor DarkGray
}

Write-Host "`n>>> SUCESSO: Todos os testes passaram e o projeto está íntegro! <<<" -ForegroundColor Green
