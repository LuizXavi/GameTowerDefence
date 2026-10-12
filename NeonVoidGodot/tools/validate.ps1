# Validacao Automatizada do Neon Void (Godot 4.7)
param (
    [switch]$SkipUi
)

$GodotBin = "C:\Users\hultr\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
$ProjectPath = (Resolve-Path "$PSScriptRoot\..").Path

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Neon Void - Validacao de Projeto      " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "[1/3] Importacao Headless..." -ForegroundColor Yellow
& $GodotBin --headless --path $ProjectPath --editor --import --quit
if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha na importacao do Godot (ExitCode: $LASTEXITCODE)"
    exit $LASTEXITCODE
}

Write-Host "[2/3] Executando Testes Logicos (test_game.gd)..." -ForegroundColor Yellow
& $GodotBin --headless --path $ProjectPath --script res://tests/test_game.gd
if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha nos testes logicos (ExitCode: $LASTEXITCODE)"
    exit $LASTEXITCODE
}

if (-not $SkipUi) {
    Write-Host "[3/3] Executando Testes Graficos e UI (test_ui.gd)..." -ForegroundColor Yellow
    & $GodotBin --path $ProjectPath --script res://tests/test_ui.gd -- --test-mode
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Falha nos testes graficos (ExitCode: $LASTEXITCODE)"
        exit $LASTEXITCODE
    }
} else {
    Write-Host "[3/3] Teste grafico ignorado (-SkipUi especificado)." -ForegroundColor DarkGray
}

Write-Host "=== SUCESSO: Todos os testes passaram e o projeto esta integro! ===" -ForegroundColor Green
exit 0
