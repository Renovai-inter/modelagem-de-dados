<#
=============================================================================
RENOVAÍ — DISASTER RECOVERY: SCRIPT DE BACKUP LÓGICO (PowerShell)
=============================================================================
Referência: Aulas de Modelagem de Dados — Segurança de Dados (Instituto J&F)
Slide 8 e Slide 10 (Hands-On 2)
=============================================================================
#>

param(
    [string]$DbHost = $env:DB_HOST,
    [string]$DbPort = $env:DB_PORT,
    [string]$DbName = $env:DB_NAME,
    [string]$DbUser = $env:DB_USER,
    [string]$OutputDir = "./backups"
)

if (-not $DbHost) { $DbHost = "localhost" }
if (-not $DbPort) { $DbPort = "5432" }
if (-not $DbName) { $DbName = "bd_renovai" }
if (-not $DbUser) { $DbUser = "postgres" }

$DataHora = Get-Date -Format "yyyyMMdd_HHmmss"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "RENOVAÍ — INICIANDO ROTINA DE BACKUP LÓGICO (PostgreSQL)" -ForegroundColor Cyan
Write-Host "Data/Hora: $DataHora"
Write-Host "Banco Alvo: $DbName em ${DbHost}:${DbPort}"
Write-Host "==========================================================================" -ForegroundColor Cyan

# 1. Backup DDL apenas da estrutura (Slide 10 Hands-on 2)
$SchemaFile = "$OutputDir/renovai_schema_ddl_$DataHora.sql"
Write-Host "--> 1. Gerando backup DDL (apenas estrutura DDL, sem dados)..." -ForegroundColor Yellow
& pg_dump -h $DbHost -p $DbPort -U $DbUser -d $DbName -s -f $SchemaFile
Write-Host "    [OK] Arquivo gerado: $SchemaFile" -ForegroundColor Green

# 2. Backup isolado da tabela 'coletas' (Slide 8)
$ColetasFile = "$OutputDir/backup_coletas_$DataHora.sql"
Write-Host "--> 2. Gerando backup isolado da tabela crítica 'coletas'..." -ForegroundColor Yellow
& pg_dump -h $DbHost -p $DbPort -U $DbUser -d $DbName -t coletas -f $ColetasFile
Write-Host "    [OK] Arquivo gerado: $ColetasFile" -ForegroundColor Green

# 3. Backup completo
$FullFile = "$OutputDir/renovai_completo_$DataHora.sql"
Write-Host "--> 3. Gerando backup completo da base de dados..." -ForegroundColor Yellow
& pg_dump -h $DbHost -p $DbPort -U $DbUser -d $DbName -f $FullFile
Write-Host "    [OK] Arquivo gerado: $FullFile" -ForegroundColor Green

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "ROTINA DE BACKUP FINALIZADA COM SUCESSO!" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
