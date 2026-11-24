-- Bridge: textos en cada idioma.
-- Inglés por defecto; español si el juego está en español (esES / esMX).
-- Para añadir un idioma: copia el bloque de español, cambia la condición de GetLocale()
-- y traduce los textos. Las claves que falten se muestran en inglés.

local _, ns = ...

local L = {
	-- General
	LOADED = "Version %s loaded. Type /bridge for help.",
	VERSION = "Version %s",
	ERROR = "Error: %s",
	YES = "yes",
	NO = "no",

	-- Paradas
	STOP_ADDED = "Stop added",
	DIRECT_ROUTE = "Direct route to",
	STOP_MOVED = "Stop moved",
	STOP_REMOVED = "Stop removed: %s",
	ROUTE_CLEARED = "All stops cleared.",
	STOPS_REMOVED = "%d stops removed.",
	STOP_RENAMED = "Stop renamed: %s",
	STOP_EDITED = "Description changed: %s",
	STOP_SHARED = "Stop shared: %s",
	WAY_USAGE = "Usage: /way [zone] x y [name]   (e.g. /way Elwynn Forest 42 65 Goldshire)",
	ZOOM_IN = "Zoom in to a zone: stops can't be placed on the whole-world map.",
	DROP_IN_ZONE = "Drop the stop inside a zone.",
	SEND_FAILED = "Couldn't send the stop to AzerothGPS.",

	-- Tooltip de una parada
	UNKNOWN_DISTANCE = "Unknown distance",
	ETA = "ETA %s",

	-- Modo ruta y botón del mapa
	ROUTE_MODE_ON = "Route mode on: a click on the map adds a stop.",
	ROUTE_MODE_OFF = "Route mode off.",
	MENU_ROUTE_MODE_ON = "Turn on route mode",
	MENU_ROUTE_MODE_OFF = "Cancel route mode",
	MENU_CLEAR_STOPS = "Clear stops",
	MENU_CLEAR_ZONE = "In this zone",
	MENU_CLEAR_ALL = "All",
	MENU_ASK_NAME = "Ask for a name when adding",
	MENU_MANAGE = "Manage stops…",
	MANAGER_TITLE = "Manage stops",
	MANAGER_HINT = "Click: show on the map · Drag: reorder",

	-- Importar una lista de /way
	IMPORT_OPEN = "Import /way list",
	IMPORT_TITLE = "Import /way list",
	IMPORT_HINT = "Paste /way lines here, one per line. Each one becomes a stop, in order.",
	IMPORT_CLEAR_FIRST = "Clear current stops before importing",
	IMPORT_BUTTON = "Import",
	IMPORT_ADDED = "Import: %d stops added",
	IMPORT_REPEATED = "%d repeated",
	IMPORT_BAD = "%d lines not understood",
	MANAGER_FILTERING = "Clear the search to reorder.",
	MANAGER_EMPTY = "No stops yet. Alt+click on the map to add one.",
	MANAGER_NO_MATCH = "No stops match the search.",
	TIP_UP = "Move up",
	TIP_DOWN = "Move down",
	MENU_RENAME = "Edit name and description",
	MENU_SHARE = "Share with",
	SHARE_PARTY = "Party",
	SHARE_RAID = "Raid",
	SHARE_BATTLEGROUND = "Battleground",
	SHARE_GUILD = "Guild",
	MENU_KEEP = "Keep stops between sessions",
	MENU_COMPASS = "Show compass",
	MENU_ARRIVAL = "Arrival notice",
	WAY_RESET_USAGE = "Usage: /way reset all | /way reset <zone> | /way reset not <zone>",
	CWAY_DONE = "Next stop: %s (%s), the closest one.",
	CWAY_NONE = "No stop on this continent.",
	SHARED_ASK = "%s shares a stop with you:\n%s\n\nAdd it to your stops?",
	SHARED_ADD = "Add",
	SHARED_IGNORE = "Ignore",
	CORPSE = "Your corpse",
	CORPSE_ADDED = "Your corpse is now the first stop. It will go away when you resurrect.",
	MENU_UNITS = "Units",
	UNITS_YARDS = "Yards",
	UNITS_METERS = "Meters",
	ARRIVED = "You have arrived at %s.",
	NEXT_STOP = "Next stop: %s",
	ROUTE_DONE = "That was the last stop.",
	COMPASS_TIP = "Drag to move",
	MENU_REMOVE = "Remove",
	NAME_BOX_HINT = "Stop name (Enter: OK · Tab: next · Esc: cancel)",
	DESC_BOX_HINT = "Description (optional)",
	BUTTON_TIP_CLICK = "Click: options",
	BUTTON_TIP_DRAG = "Shift+drag: move this button",
	BUTTON_RESET = "Map button back in its original place.",
	BUTTON_SHOWN = "Map button shown.",
	BUTTON_HIDDEN = "Map button hidden.",
	MARKERS_SHOWN = "Map markers shown.",
	MARKERS_HIDDEN = "Map markers hidden.",
	SIZE_SET = "Marker size: %d%%",
	SIZE_CURRENT = "Current size: %d%%. Use /bridge %s 30-200",

	-- Questie
	QUESTIE_SET_ROUTE = "Set |cff33ff99route|r",
	QUESTIE_ADD_STOP = "Add as |cff33ff99stop|r",
	QUESTIE_LINK_FAILED = "Couldn't link with Questie (has its version changed?).",
	NO_MAP_FOR_TARGET = "Don't know which map that objective is on.",
	QUEST_NO_TARGET = "This quest has no objective to go to right now.",
	QUEST_NO_POINT = "Can't find a point for this quest.",
	OBJECTIVE_NO_POINT = "Can't find a point for this objective.",

	-- Ventana para copiar
	LOG_HINT = "The text is already selected: Cmd+C (Ctrl+C on Windows) to copy it. Esc to close.",
	LOG_RECENT = "Bridge: recent messages",

	-- Depuración y diagnóstico
	DEBUG_ON = "Debug on.",
	DEBUG_OFF = "Debug off.",
	DEBUG_SENDING = "Sending: %s",
	DEBUG_HANDLER_ERROR = "Error in %s: %s",
	DEBUG_EXTERNAL = "Copied external stop: %s",
	DEBUG_ICON_CLICK = "Click on an icon: %s at %.1f, %.1f",
	DIAG_HEADER = "--- Diagnostics (Bridge %s) ---",
	DIAG_CLIENT = "Client interface: %s",
	DIAG_AGPS_LOADED = "AzerothGPS: loaded, API v%s",
	DIAG_AGPS_MISSING = "AzerothGPS: not loaded",
	DIAG_NOBODY = "nobody",
	DIAG_WAY_WINNER = "Chat sends /way to: %s",
	DIAG_API = "BridgeAPI: v%s",
	DIAG_WAY_OWN = "/way registered by Bridge: %s",
	DIAG_WAY_AGPS = "no (AzerothGPS already handles it)",
	DIAG_WAY_OTHER = "no (another addon has it)",
	DIAG_TOMTOM = "TomTom: %s",
	DIAG_TOMTOM_SHIM = "imitated by Bridge",
	DIAG_TOMTOM_REAL = "the real addon",
	DIAG_QUESTIE = "Questie: %s",
	DIAG_LOADED = "loaded",
	DIAG_PINS = "World map: %d active pins, %d frames listened to by Bridge",
	DIAG_STOPS = "Bridge stops: %d, debug: %s",
	DIAG_COMPASS = "Compass: on %s, visible %s, distance to stop 1: %s",

	-- Ayuda (/bridge)
	HELP_HEADER = "Version %s. Commands:",
	HELP_MANAGE = "open the Manage stops window",
	HELP_IMPORT = "paste a list of /way lines to add them as stops",
	HELP_CLEAR = "clear all stops (and the AzerothGPS route, if installed)",
	HELP_MARKERS = "show/hide the map markers",
	HELP_SIZE = "marker size, 30 to 200 (%)",
	HELP_BUTTON = "show/hide the Bridge map button",
	HELP_BUTTON_RESET = "put the button back in place",
	HELP_VERSION = "show the installed version",
	HELP_DEV = "For development: /bridge diag, /bridge debug, /bridge %s",
	HELP_MAP = "On the map: Alt+click adds a stop, Alt+Shift+click goes only to that point.",
}

-- Palabras de los comandos: siempre en inglés, en todos los idiomas.
local W = {
	clear = "clear", markers = "markers", size = "size", button = "button", reset = "reset",
	version = "version", copy = "copy", manage = "manage", import = "import",
}

local locale = GetLocale()
if locale == "esES" or locale == "esMX" then
	L.LOADED = "Versión %s cargada. Escribe /bridge para ver la ayuda."
	L.VERSION = "Versión %s"
	L.ERROR = "Error: %s"
	L.YES = "sí"
	L.NO = "no"

	L.STOP_ADDED = "Parada añadida"
	L.DIRECT_ROUTE = "Ruta directa a"
	L.STOP_MOVED = "Parada movida"
	L.STOP_REMOVED = "Parada quitada: %s"
	L.ROUTE_CLEARED = "Paradas borradas."
	L.STOPS_REMOVED = "%d paradas quitadas."
	L.STOP_RENAMED = "Parada renombrada: %s"
	L.STOP_EDITED = "Descripción cambiada: %s"
	L.STOP_SHARED = "Parada compartida: %s"
	L.WAY_USAGE = "Uso: /way [zona] x y [nombre]   (p. ej. /way Bosque de Elwynn 42 65 Villadorada)"
	L.ZOOM_IN = "Acércate a una zona: en el mapa del mundo entero no se pueden poner paradas."
	L.DROP_IN_ZONE = "Suelta la parada dentro de una zona."
	L.SEND_FAILED = "No se pudo enviar la parada a AzerothGPS."

	L.UNKNOWN_DISTANCE = "Distancia desconocida"
	L.ETA = "Llegada en %s"

	L.ROUTE_MODE_ON = "Modo ruta activado: un clic en el mapa añade una parada."
	L.ROUTE_MODE_OFF = "Modo ruta desactivado."
	L.MENU_ROUTE_MODE_ON = "Activar modo ruta"
	L.MENU_ROUTE_MODE_OFF = "Cancelar modo ruta"
	L.MENU_CLEAR_STOPS = "Borrar paradas"
	L.MENU_CLEAR_ZONE = "De la zona"
	L.MENU_CLEAR_ALL = "Todas"
	L.MENU_ASK_NAME = "Pedir nombre al añadir"
	L.MENU_MANAGE = "Gestionar paradas…"
	L.MANAGER_TITLE = "Gestionar paradas"
	L.MANAGER_HINT = "Clic: ver en el mapa · Arrastrar: reordenar"

	L.IMPORT_OPEN = "Importar lista /way"
	L.IMPORT_TITLE = "Importar lista de /way"
	L.IMPORT_HINT = "Pega aquí las líneas /way, una por línea. Cada una será una parada, en orden."
	L.IMPORT_CLEAR_FIRST = "Borrar las paradas actuales antes de importar"
	L.IMPORT_BUTTON = "Importar"
	L.IMPORT_ADDED = "Importar: %d paradas añadidas"
	L.IMPORT_REPEATED = "%d repetidas"
	L.IMPORT_BAD = "%d líneas no entendidas"
	L.MANAGER_FILTERING = "Borra la búsqueda para reordenar."
	L.MANAGER_EMPTY = "Aún no hay paradas. Alt+clic en el mapa para añadir una."
	L.MANAGER_NO_MATCH = "Ninguna parada coincide con la búsqueda."
	L.TIP_UP = "Subir"
	L.TIP_DOWN = "Bajar"
	L.MENU_RENAME = "Editar nombre y descripción"
	L.MENU_SHARE = "Compartir con"
	L.SHARE_PARTY = "Grupo"
	L.SHARE_RAID = "Banda"
	L.SHARE_BATTLEGROUND = "Campo de batalla"
	L.SHARE_GUILD = "Hermandad"
	L.MENU_KEEP = "Guardar paradas entre sesiones"
	L.MENU_COMPASS = "Mostrar brújula"
	L.MENU_ARRIVAL = "Aviso al llegar"
	L.WAY_RESET_USAGE = "Uso: /way reset all | /way reset <zona> | /way reset not <zona>"
	L.CWAY_DONE = "Siguiente parada: %s (%s), la más cercana."
	L.CWAY_NONE = "No hay paradas en este continente."
	L.SHARED_ASK = "%s te comparte una parada:\n%s\n\n¿La añades a tus paradas?"
	L.SHARED_ADD = "Añadir"
	L.SHARED_IGNORE = "Ignorar"
	L.CORPSE = "Tu cadáver"
	L.CORPSE_ADDED = "Tu cadáver es ahora la primera parada. Se quitará al resucitar."
	L.MENU_UNITS = "Unidades"
	L.UNITS_YARDS = "Yardas"
	L.UNITS_METERS = "Metros"
	L.ARRIVED = "Has llegado a %s."
	L.NEXT_STOP = "Siguiente parada: %s"
	L.ROUTE_DONE = "Era la última parada."
	L.COMPASS_TIP = "Arrastra para moverla"
	L.MENU_REMOVE = "Quitar"
	L.NAME_BOX_HINT = "Nombre de la parada (Intro: aceptar · Tab: siguiente · Esc: cancelar)"
	L.DESC_BOX_HINT = "Descripción (opcional)"
	L.BUTTON_TIP_CLICK = "Clic: opciones"
	L.BUTTON_TIP_DRAG = "Mayús+arrastrar: mover este botón"
	L.BUTTON_RESET = "Botón del mapa en su sitio original."
	L.BUTTON_SHOWN = "Botón del mapa visible."
	L.BUTTON_HIDDEN = "Botón del mapa oculto."
	L.MARKERS_SHOWN = "Marcadores del mapa visibles."
	L.MARKERS_HIDDEN = "Marcadores del mapa ocultos."
	L.SIZE_SET = "Tamaño de los marcadores: %d%%"
	L.SIZE_CURRENT = "Tamaño actual: %d%%. Usa /bridge %s 30-200"

	L.QUESTIE_SET_ROUTE = "Establecer |cff33ff99ruta|r"
	L.QUESTIE_ADD_STOP = "Añadir como |cff33ff99parada|r"
	L.QUESTIE_LINK_FAILED = "No he podido enlazar con Questie (¿ha cambiado de versión?)."
	L.NO_MAP_FOR_TARGET = "No sé en qué mapa está ese objetivo."
	L.QUEST_NO_TARGET = "Esta misión no tiene ahora un objetivo al que ir."
	L.QUEST_NO_POINT = "No encuentro un punto para esta misión."
	L.OBJECTIVE_NO_POINT = "No encuentro un punto para este objetivo."

	L.LOG_HINT = "El texto ya está seleccionado: Cmd+C (Ctrl+C en Windows) para copiarlo. Esc para cerrar."
	L.LOG_RECENT = "Bridge: últimos mensajes"

	L.DEBUG_ON = "Depuración activada."
	L.DEBUG_OFF = "Depuración desactivada."
	L.DEBUG_SENDING = "Enviando: %s"
	L.DEBUG_HANDLER_ERROR = "Error en %s: %s"
	L.DEBUG_EXTERNAL = "Copiada parada externa: %s"
	L.DEBUG_ICON_CLICK = "Clic en un icono: %s en %.1f, %.1f"
	L.DIAG_HEADER = "--- Diagnóstico (Bridge %s) ---"
	L.DIAG_CLIENT = "Interface del cliente: %s"
	L.DIAG_AGPS_LOADED = "AzerothGPS: cargado, API v%s"
	L.DIAG_AGPS_MISSING = "AzerothGPS: no cargado"
	L.DIAG_NOBODY = "nadie"
	L.DIAG_WAY_WINNER = "El chat entrega /way a: %s"
	L.DIAG_API = "BridgeAPI: v%s"
	L.DIAG_WAY_OWN = "/way registrado por Bridge: %s"
	L.DIAG_WAY_AGPS = "no (ya lo gestiona AzerothGPS)"
	L.DIAG_WAY_OTHER = "no (lo tiene otro addon)"
	L.DIAG_TOMTOM = "TomTom: %s"
	L.DIAG_TOMTOM_SHIM = "imitado por Bridge"
	L.DIAG_TOMTOM_REAL = "el addon de verdad"
	L.DIAG_QUESTIE = "Questie: %s"
	L.DIAG_LOADED = "cargado"
	L.DIAG_PINS = "Mapa del mundo: %d pines activos, %d marcos escuchados por Bridge"
	L.DIAG_STOPS = "Paradas de Bridge: %d, depuración: %s"
	L.DIAG_COMPASS = "Brújula: activada %s, visible %s, distancia a la parada 1: %s"

	L.HELP_HEADER = "Versión %s. Comandos:"
	L.HELP_MANAGE = "abrir la ventana Gestionar paradas"
	L.HELP_IMPORT = "pegar una lista de líneas /way para añadirlas como paradas"
	L.HELP_CLEAR = "borrar todas las paradas (y la ruta de AzerothGPS, si lo tienes)"
	L.HELP_MARKERS = "mostrar/ocultar los marcadores del mapa"
	L.HELP_SIZE = "tamaño de los marcadores, de 30 a 200 (%)"
	L.HELP_BUTTON = "mostrar/ocultar el botón Bridge del mapa"
	L.HELP_BUTTON_RESET = "devolver el botón a su sitio"
	L.HELP_VERSION = "ver la versión instalada"
	L.HELP_DEV = "Para desarrollo: /bridge diag, /bridge debug, /bridge %s"
	L.HELP_MAP = "En el mapa: Alt+clic añade una parada, Alt+Mayús+clic va solo a ese punto."

end

-- Teclas según el sistema: en Mac, Alt es Opción y para copiar se usa Cmd
local isMac = IsMacClient and IsMacClient()
local isSpanish = locale == "esES" or locale == "esMX"
if isMac then
	local option = isSpanish and "Opción" or "Option"
	for key, text in pairs(L) do
		if type(text) == "string" then L[key] = text:gsub("Alt%+", option .. "+") end
	end
	L.LOG_HINT = isSpanish and "El texto ya está seleccionado: Cmd+C para copiarlo. Esc para cerrar."
		or "The text is already selected: Cmd+C to copy it. Esc to close."
else
	L.LOG_HINT = isSpanish and "El texto ya está seleccionado: Ctrl+C para copiarlo. Esc para cerrar."
		or "The text is already selected: Ctrl+C to copy it. Esc to close."
end

-- Una clave sin traducir se muestra tal cual, en lugar de dar un error
setmetatable(L, { __index = function(_, key) return key end })

ns.L = L
ns.W = W
