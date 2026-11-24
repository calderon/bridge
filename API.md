# BridgeAPI

> *[English version below](#english)*

## Español

Bridge ofrece una API para que otros addons (o tus macros con `/run`) puedan crear y gestionar paradas. Está en la tabla global **`BridgeAPI`**.

### Antes de usarla

```lua
if BridgeAPI and BridgeAPI.version >= 1 then
    -- Bridge está cargado
end
-- Las funciones de rutas necesitan BridgeAPI.version >= 2
```

Si tu addon la usa, añade `## OptionalDeps: Bridge` a su `.toc` para que Bridge se cargue antes.

### Conceptos

- **Coordenadas:** `mapID` es el uiMapID de Blizzard, y `x`, `y` van de 0 a 1, como en `C_Map`. Si das un mapa de continente, Bridge busca la zona que hay debajo.
- **`id`:** cada parada tiene un identificador numérico que **no cambia** aunque la parada se reordene, se renombre o se mueva.
- **Copias:** las funciones que devuelven paradas dan **copias**; cambiarlas no afecta a Bridge.
- **AzerothGPS:** si está cargado, cada cambio actualiza su ruta. Si no, las paradas solo se ven en el mapa.
- **Rutas:** lo que se recorre es siempre la **Ruta actual** (la que siguen la brújula, el mapa y AzerothGPS). Todas las funciones de paradas actúan sobre ella. Las **rutas guardadas** son plantillas: `LoadRoute` copia sus paradas en la Ruta actual.

Una parada devuelta por la API tiene estos campos:

| Campo | Qué es |
|---|---|
| `id` | Identificador fijo |
| `index` | Posición en la ruta (1 = la primera) |
| `name` | Nombre |
| `zone` | Nombre de la zona |
| `mapID`, `x`, `y` | Zona y coordenadas (0–1) |
| `source` | Quién la añadió, si se indicó (`"Questie"`, `"/way"`, el nombre de tu addon…) |
| `description` | Descripción, si tiene (sale en el tooltip) |
| `reached` | `true` si ya se ha llegado a ella en el recorrido (sigue guardada en su ruta) |

Una ruta guardada devuelta por la API (versión 2) tiene estos campos:

| Campo | Qué es |
|---|---|
| `id` | Identificador fijo (número, o texto en las rutas compartidas) |
| `name` | Nombre |
| `count` | Número de paradas |
| `shared` | `true` si la ven todos los personajes de la cuenta |
| `loaded` | `true` si es la última cargada en la Ruta actual |
| `modified` | Solo en `GetLoadedRoute()`: `true` si la Ruta actual ya no coincide con ella |

### Funciones

| Función | Devuelve | Qué hace |
|---|---|---|
| `BridgeAPI.AddStop(mapID, x, y [, opts])` | `id` o `nil` | Añade una parada al final de la ruta |
| `BridgeAPI.RouteTo(mapID, x, y [, opts])` | `id` o `nil` | Vacía la Ruta actual y deja esta parada como única (tu cadáver se queda) |
| `BridgeAPI.RemoveStop(id)` | `true`/`false` | Quita una parada |
| `BridgeAPI.ClearStops()` | — | Vacía la Ruta actual (tu cadáver se queda) |
| `BridgeAPI.RenameStop(id, nombre)` | `true`/`false` | Cambia el nombre (la descripción no cambia) |
| `BridgeAPI.MoveStop(id, mapID, x, y)` | `true`/`false` | Cambia la posición en el mapa |
| `BridgeAPI.ReorderStop(id, posición)` | `true`/`false` | Cambia su lugar en la ruta (1 = la primera) |
| `BridgeAPI.GetStop(id)` | parada o `nil` | Una parada |
| `BridgeAPI.GetStops()` | lista | Todas, en el orden de la ruta |
| `BridgeAPI.ShowStop(id)` | `true`/`false` | Abre el mapa del mundo en la parada y la hace parpadear |
| `BridgeAPI.GetDistance(id)` | yardas o `nil` | Distancia en línea recta desde el jugador. Siempre en yardas, aunque el jugador haya elegido metros. `nil` si no se puede saber (otro continente, mazmorra…) |
| `BridgeAPI.HasAzerothGPS()` | `true`/`false` | Si las paradas se convierten en ruta |
| `BridgeAPI.GetRoutes()` | lista | Las rutas guardadas, por orden alfabético (versión 2) |
| `BridgeAPI.GetLoadedRoute()` | ruta o `nil` | La última ruta guardada cargada en la Ruta actual, con `modified` (versión 2) |
| `BridgeAPI.LoadRoute(id)` | `true`/`false` | Carga una ruta guardada en la Ruta actual, sustituyendo sus paradas (tu cadáver se queda) (versión 2) |
| `BridgeAPI.CreateRoute(nombre)` | `id` o `nil` | Crea una ruta guardada vacía (versión 2) |
| `BridgeAPI.RestartRoute()` | — | Reinicia la Ruta actual: vuelve a la primera parada (versión 2) |
| `BridgeAPI.RegisterCallback(dueño, evento, fn)` | `true`/`false` | Escuchar un evento |
| `BridgeAPI.UnregisterCallback(dueño [, evento])` | — | Dejar de escuchar uno o todos |

**`opts`** (opcional) en `AddStop` y `RouteTo`:

| Campo | Qué hace |
|---|---|
| `name` | Nombre de la parada. Si no se indica, el de la zona. |
| `description` | Descripción opcional; sale en el tooltip de la parada |
| `exclusive` | `true` para borrar la ruta y dejar solo esta (`RouteTo` lo hace siempre) |
| `source` | Texto que identifica quién la añade (por ejemplo, el nombre de tu addon) |
| `silent` | `true` para que Bridge no escriba "Parada añadida" en el chat |

Las paradas añadidas por la API **nunca** muestran la cajita para poner nombre.

### Eventos

`fn(evento, parada)` se llama tras cada cambio, venga de donde venga (el mapa, la ventana Gestionar rutas, Questie, un `/way`, la llegada a una parada en AzerothGPS u otro addon). `parada` es una copia.

| Evento | Cuándo | `parada` |
|---|---|---|
| `STOP_ADDED` | Se añade una parada | La nueva |
| `STOP_REMOVED` | Se quita una parada | La quitada (`index` ya no aplica) |
| `STOP_CHANGED` | Se renombra, cambia su descripción o se mueve | Con los datos nuevos |
| `STOP_REACHED` | Se llega a una parada (no se quita: queda marcada como alcanzada) | La alcanzada (`reached = true`) |
| `STOPS_REORDERED` | Cambia el orden | — |
| `STOPS_CLEARED` | Se borran todas | — |
| `ACTIVE_ROUTE_CHANGED` | Se carga una ruta guardada en la Ruta actual (sus paradas pasan a ser las de la API) | `{ id, name }` de la ruta cargada |

`dueño` identifica a quien escucha (por ejemplo, el nombre de tu addon). Hay una función por dueño y evento: registrar otra la sustituye.

### Ejemplos

```lua
-- Ir a un punto de Elwynn (mapa 1429)
local id = BridgeAPI.RouteTo(1429, 0.42, 0.65, { name = "Villadorada", source = "MiAddon" })

-- Añadir otra parada sin escribir en el chat
BridgeAPI.AddStop(1429, 0.32, 0.50, { name = "Buzón", silent = true })

-- Pasar la primera parada al final
local stops = BridgeAPI.GetStops()
if stops[1] then BridgeAPI.ReorderStop(stops[1].id, #stops) end

-- Enterarse de cada parada nueva
BridgeAPI.RegisterCallback("MiAddon", "STOP_ADDED", function(event, stop)
    print("Nueva parada:", stop.name, stop.zone)
end)
```

Desde el chat: `/run BridgeAPI.RouteTo(1429, 0.42, 0.65, {name = "Villadorada"})`

---

<a name="english"></a>
## English

Bridge offers an API so that other addons (or your `/run` macros) can create and manage stops. It lives in the global table **`BridgeAPI`**.

### Before using it

```lua
if BridgeAPI and BridgeAPI.version >= 1 then
    -- Bridge is loaded
end
-- The route functions need BridgeAPI.version >= 2
```

If your addon uses it, add `## OptionalDeps: Bridge` to its `.toc` so Bridge loads first.

### Concepts

- **Coordinates:** `mapID` is Blizzard's uiMapID, and `x`, `y` go from 0 to 1, as in `C_Map`. If you pass a continent map, Bridge finds the zone underneath.
- **`id`:** every stop has a numeric identifier that **never changes**, even if the stop is reordered, renamed or moved.
- **Copies:** functions that return stops give **copies**; changing them does not affect Bridge.
- **AzerothGPS:** if it is loaded, every change updates its route. If not, stops are only shown on the map.
- **Routes:** what is walked is always the **Current route** (the one the compass, the map and AzerothGPS follow). All the stop functions work on it. **Saved routes** are templates: `LoadRoute` copies their stops into the Current route.

A stop returned by the API has these fields:

| Field | Meaning |
|---|---|
| `id` | Fixed identifier |
| `index` | Position in the route (1 = first) |
| `name` | Name |
| `zone` | Zone name |
| `mapID`, `x`, `y` | Zone and coordinates (0–1) |
| `source` | Who added it, if given (`"Questie"`, `"/way"`, your addon's name…) |
| `description` | Description, if any (shown in the tooltip) |
| `reached` | `true` if it has already been reached in the current walk (it stays saved in its route) |

A saved route returned by the API (version 2) has these fields:

| Field | Meaning |
|---|---|
| `id` | Fixed identifier (a number, or text for shared routes) |
| `name` | Name |
| `count` | Number of stops |
| `shared` | `true` if all the characters of the account see it |
| `loaded` | `true` if it is the last one loaded into the Current route |
| `modified` | Only in `GetLoadedRoute()`: `true` if the Current route no longer matches it |

### Functions

| Function | Returns | What it does |
|---|---|---|
| `BridgeAPI.AddStop(mapID, x, y [, opts])` | `id` or `nil` | Adds a stop at the end of the route |
| `BridgeAPI.RouteTo(mapID, x, y [, opts])` | `id` or `nil` | Empties the Current route and leaves this as the only stop (your corpse stays) |
| `BridgeAPI.RemoveStop(id)` | `true`/`false` | Removes a stop |
| `BridgeAPI.ClearStops()` | — | Empties the Current route (your corpse stays) |
| `BridgeAPI.RenameStop(id, name)` | `true`/`false` | Changes the name (the description is kept) |
| `BridgeAPI.MoveStop(id, mapID, x, y)` | `true`/`false` | Changes its position on the map |
| `BridgeAPI.ReorderStop(id, position)` | `true`/`false` | Changes its place in the route (1 = first) |
| `BridgeAPI.GetStop(id)` | stop or `nil` | One stop |
| `BridgeAPI.GetStops()` | list | All of them, in route order |
| `BridgeAPI.ShowStop(id)` | `true`/`false` | Opens the world map at the stop and flashes it |
| `BridgeAPI.GetDistance(id)` | yards or `nil` | Straight-line distance from the player. Always in yards, even if the player chose meters. `nil` if it can't be known (another continent, a dungeon…) |
| `BridgeAPI.HasAzerothGPS()` | `true`/`false` | Whether stops become a route |
| `BridgeAPI.GetRoutes()` | list | The saved routes, in alphabetical order (version 2) |
| `BridgeAPI.GetLoadedRoute()` | route or `nil` | The last saved route loaded into the Current route, with `modified` (version 2) |
| `BridgeAPI.LoadRoute(id)` | `true`/`false` | Loads a saved route into the Current route, replacing its stops (your corpse stays) (version 2) |
| `BridgeAPI.CreateRoute(name)` | `id` or `nil` | Creates an empty saved route (version 2) |
| `BridgeAPI.RestartRoute()` | — | Restarts the Current route: back to the first stop (version 2) |
| `BridgeAPI.RegisterCallback(owner, event, fn)` | `true`/`false` | Listen to an event |
| `BridgeAPI.UnregisterCallback(owner [, event])` | — | Stop listening to one or all events |

**`opts`** (optional) for `AddStop` and `RouteTo`:

| Field | What it does |
|---|---|
| `name` | Stop name. If not given, the zone name. |
| `description` | Optional description; shown in the stop's tooltip |
| `exclusive` | `true` to clear the route and keep only this one (`RouteTo` always does) |
| `source` | Text identifying who adds it (for example, your addon's name) |
| `silent` | `true` so Bridge does not print "Stop added" in chat |

Stops added through the API **never** show the naming box.

### Events

`fn(event, stop)` is called after every change, wherever it comes from (the map, the Manage routes window, Questie, a `/way`, arriving at a stop in AzerothGPS, or another addon). `stop` is a copy.

| Event | When | `stop` |
|---|---|---|
| `STOP_ADDED` | A stop is added | The new one |
| `STOP_REMOVED` | A stop is removed | The removed one (`index` no longer applies) |
| `STOP_CHANGED` | A stop is renamed, its description changes, or it is moved | With the new data |
| `STOP_REACHED` | A stop is reached (it is not removed: it is marked as reached) | The reached one (`reached = true`) |
| `STOPS_REORDERED` | The order changes | — |
| `STOPS_CLEARED` | All stops are cleared | — |
| `ACTIVE_ROUTE_CHANGED` | A saved route is loaded into the Current route (its stops become the API's stops) | `{ id, name }` of the loaded route |

`owner` identifies the listener (for example, your addon's name). There is one function per owner and event: registering another one replaces it.

### Examples

```lua
-- Go to a point in Elwynn (map 1429)
local id = BridgeAPI.RouteTo(1429, 0.42, 0.65, { name = "Goldshire", source = "MyAddon" })

-- Add another stop without printing to chat
BridgeAPI.AddStop(1429, 0.32, 0.50, { name = "Mailbox", silent = true })

-- Move the first stop to the end
local stops = BridgeAPI.GetStops()
if stops[1] then BridgeAPI.ReorderStop(stops[1].id, #stops) end

-- Get notified of every new stop
BridgeAPI.RegisterCallback("MyAddon", "STOP_ADDED", function(event, stop)
    print("New stop:", stop.name, stop.zone)
end)
```

From chat: `/run BridgeAPI.RouteTo(1429, 0.42, 0.65, {name = "Goldshire"})`
