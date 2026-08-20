# Codebase Memory Index

Este directorio contiene el índice de memoria del proyecto Cascabel (tilt-os) para optimizar las búsquedas de código con Claude.

## Archivos

- **graph.db.zst**: Base de datos comprimida del índice del codebase
  - Generado automáticamente por `codebase-memory-mcp`
  - Contiene 1,744 nodos (funciones, clases, etc.) y 7,173 relaciones

## Uso en múltiples PCs

### Primera vez:
```bash
# PC 1: Crear el índice
codebase-memory-mcp cli index_repository --repo-path .

# Commit y push al repositorio
git add .codebase-memory/
git commit -m "Initialize codebase memory index"
git push
```

### Máquinas posteriores:
```bash
# PC 2: Clonar el repositorio
git clone <repo-url>
cd tilt-os

# El índice se importa automáticamente
codebase-memory-mcp cli index_repository --repo-path .
# Detectará graph.db.zst y lo importará, luego indexará cambios incrementales
```

## Actualizar el índice

Después de cambios importantes en el código:

```bash
# Reindexar
codebase-memory-mcp cli index_repository --repo-path .

# El .gitattributes usa merge=ours para evitar conflictos
# en ediciones concurrentes del artefacto
git add .codebase-memory/graph.db.zst
git commit -m "Update codebase memory index"
git push
```

## Integración con Claude Code

El MCP ha sido instalado automáticamente en:
- `C:\Users\daniel\.claude\agents/codebase-memory.md`
- `C:\Users\daniel\.claude\agents/codebase-memory-scout.md`
- `C:\Users\daniel\.claude\agents/codebase-memory-auditor.md`

Usa `codebase-memory` skill en Claude Code para:
- Explorar la estructura del proyecto
- Encontrar dónde se definen funciones/clases
- Trazar relaciones entre componentes
- Auditar la calidad del código
