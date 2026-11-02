<#
=============================================================================
RENOVAÍ — DISASTER RECOVERY: SCRIPT DE RESTAURAÇÃO (PowerShell)
=============================================================================
Referência: Aulas de Modelagem de Dados — Segurança de Dados (Instituto J&F)
Slide 8: Cenário de Recuperação pós DROP TABLE acidental
=============================================================================
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ArquivoBackup,
    [string]$DbHost = $env:DB_HOST,
    [string]$DbPort = $env:DB_PORT,
    [string]$DbName = $env:DB_NAME,
    [string]$DbUser = $env:DB_USER
)

if (-not $DbHost) { $DbHost = "localhost" }
if (-not $DbPort) { $DbPort = "5432" }
if (-not $DbName) { $DbName = "bd_renovai" }
if (-not $DbUser) { $DbUser = "postgres" }

if (-not (Test-Path $ArquivoBackup)) {
    Write-Error "Arquivo de backup não encontrado: $ArquivoBackup"
    exit 1
}

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "RENOVAÍ — INICIANDO RESTAURAÇÃO DE DESASTRE (psql)" -ForegroundColor Cyan
Write-Host "Arquivo de Entrada: $ArquivoBackup"
Write-Host "Destino: $DbName em ${DbHost}:${DbPort}"
Write-Host "==========================================================================" -ForegroundColor Cyan

& psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -v ON_ERROR_STOP=1 -f $ArquivoBackup

if ($LASTEXITCODE -eq 0) {
    Write-Host "==========================================================================" -ForegroundColor Green
    Write-Host "RESTAURAÇÃO CONCLUÍDA COM SUCESSO!" -ForegroundColor Green
    Write-Host "==========================================================================" -ForegroundColor Green
} else {
    Write-Error "Falha durante a restauração com código de saída $LASTEXITCODE"
}
