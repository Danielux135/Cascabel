# Codebase Memory Index

Índice de memoria del proyecto Cascabel (tilt-os), para que Claude pueda buscar
por el grafo del codebase en vez de leer archivo por archivo.

## ESTE DIRECTORIO ESTÁ VACÍO A PROPÓSITO

Antes decía que aquí vivía un `graph.db.zst` con el grafo comprimido, y daba
instrucciones para commitearlo y compartirlo entre máquinas. **Ese fichero no
existe y la versión actual del CLI no lo genera**: sus quince herramientas son
`index_repository`, `search_graph`, `query_graph`, `trace_path`,
`get_code_snippet`, `get_graph_schema`, `get_architecture`, `search_code`,
`list_projects`, `delete_project`, `index_status`, `check_index_coverage`,
`detect_changes`, `manage_adr` e `ingest_traces`, y ninguna exporta un
artefacto. El propio indexado lo dice en su salida: `"artifact_present": false`.

El grafo vive en el almacén local del daemon, fuera del repo. **O sea que el
índice no viaja con el repositorio**: en una máquina nueva hay que generarlo,
y cuesta cuatro segundos.

El directorio se queda con su `.gitkeep` por si una versión posterior vuelve a
exportar el artefacto aquí.

## Generar o actualizar el índice

```
codebase-memory-mcp cli index_repository --repo-path C:\dev\tilt-os
```

Detecta cambios incrementales él solo. **Y ya está: no hay que commitear nada.**

Hay que lanzarlo **con Claude Code cerrado**, o el daemon rechaza al cliente
(`CBM daemon is active or starting but could not accept this client within
30000 ms`) porque el servidor MCP de la sesión lo tiene tomado. Si se atasca:

```
taskkill /F /IM codebase-memory-mcp.exe
```

## Cuándo hace falta

Lo largo está en `CLAUDE.md`, apartado "Codebase Memory MCP — cuándo y cómo".
En corto: para buscar dónde se usa algo en todo el proyecto, trazar cadenas de
llamadas, medir el impacto de un cambio o auditar código muerto. Para un
bugfix dentro de un archivo que ya tienes abierto, no.

## Ver el grafo en 3D

```
codebase-memory-mcp daemon start
```

Y luego <http://localhost:9749>.
