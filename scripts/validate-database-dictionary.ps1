$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Doc = Join-Path $Root "docs\08-database-dictionary.md"
$Tables = Join-Path $Root "docs\database-table-catalog.csv"
$Fields = Join-Path $Root "docs\database-field-catalog.csv"
foreach ($Path in @($Doc, $Tables, $Fields)) {
    if (-not (Test-Path $Path)) { throw "缺少数据库字典文件：$Path" }
}
$TableRows = Import-Csv $Tables
$FieldRows = Import-Csv $Fields
$DuplicateTables = $TableRows | Group-Object table_name | Where-Object Count -gt 1
if ($DuplicateTables) { throw "存在重复表名：$($DuplicateTables.Name -join ', ')" }
$DuplicateFields = $FieldRows | Group-Object database, table_name, field_name | Where-Object Count -gt 1
if ($DuplicateFields) { throw "存在重复字段定义。" }
$Implemented = @($TableRows | Where-Object status -eq '已迁移').Count
$Planned = @($TableRows | Where-Object status -eq '规划').Count
Write-Host "数据库字典验证通过"
Write-Host "表总数：$($TableRows.Count)"
Write-Host "已迁移表：$Implemented"
Write-Host "规划表：$Planned"
Write-Host "字段总数：$($FieldRows.Count)"
