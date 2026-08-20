# Script rápido para actualizar el índice de Codebase Memory
# Uso: .\update-memory.ps1

$CbmPath = 'C:\Users\daniel\AppData\Local\Programs\codebase-memory-mcp\codebase-memory-mcp.exe'

Write-Host "🔄 Actualizando índice de Codebase Memory..." -ForegroundColor Cyan

# Indexar el repositorio
Write-Host "`n📚 Indexando código..." -ForegroundColor Green
& $CbmPath cli --progress index_repository --repo-path '.' | ConvertFrom-Json | ForEach-Object {
    Write-Host "  • Nodos: $($_.nodes)"
    Write-Host "  • Relaciones: $($_.edges)"
    Write-Host "  • Status: $($_.status)"
}

Write-Host "`n✅ Índice actualizado exitosamente" -ForegroundColor Green
Write-Host "`n💾 Para guardar cambios:"
Write-Host "  git add .codebase-memory/"
Write-Host "  git commit -m 'Update codebase memory index'"
Write-Host "  git push"
