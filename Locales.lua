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
	STOP_ADDED_TO = "Stop added to “%s”",
	DIRECT_ROUTE = "Direct route to",
	STOP_MOVED = "Stop moved",
	STOP_MOVED_TO = "Stop moved: %s → %s",
	STOP_COPIED_TO = "Stop copied: %s → %s",
	STOP_REMOVED = "Stop removed: %s",
	ROUTE_CLEARED = "Current route emptied.",
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
	MENU_CLEAR_STOPS = "Empty Current route",
	CLEAR_CONFIRM = "Empty the Current route?",
	CLEAR_STOPS = "Its %d stops will be removed (your corpse stays).",
	CLEAR_STOPS_ONE = "Its stop will be removed (your corpse stays).",
	CLEAR_YES = "Empty",
	MENU_ASK_NAME = "Ask for a name when adding",
	MENU_MANAGE = "Manage routes…",
	MANAGER_TITLE = "Manage routes",
	MANAGER_ROUTES = "Routes",
	ROUTE_LOAD = "Load into the Current route",
	ROUTE_LOADED_TIP = "Last loaded route (click to load it again)",
	ROUTE_LOADED = "Route loaded into the Current route: %s",
	LOAD_CONFIRM = "Load “%s” into the Current route?",
	LOAD_REPLACE = "Its %d stops will be replaced (your corpse stays).",
	LOAD_REPLACE_ONE = "Its stop will be replaced (your corpse stays).",
	LOAD_YES = "Load",
	ROUTE_NEW = "New route",
	ROUTE_NEW_NAME = "Route %d",
	ROUTE_NAME_HINT = "Route name (Enter: OK · Esc: cancel)",
	ROUTE_CREATED = "Route created: %s",
	ROUTE_RENAME = "Rename route",
	ROUTE_RENAMED = "Route renamed: %s",
	ROUTE_DUPLICATE = "Duplicate route",
	ROUTE_COPY_NAME = "%s (copy)",
	ROUTE_DUPLICATED = "Route duplicated: %s",
	ROUTE_RESTART = "Restart the route from its first stop",
	ROUTE_RESTARTED = "Route restarted: %s",
	ROUTE_DELETE = "Delete route",
	ROUTE_DELETE_SHARED = "It is shared: it will disappear for all your characters.",
	ROUTE_SHARED = "Shared with my characters",
	ROUTE_SHARED_TIP = "Shared routes are seen and edited by all the characters of your account (shown in blue in the list). What each character walks is still its own, in its Current route.",
	ROUTE_SHARED_ON = "Route shared with your characters: %s",
	ROUTE_SHARED_OFF = "Route no longer shared: %s",
	ROUTE_UNSHARE_CONFIRM = "Stop sharing “%s”? Your other characters won't see it any more.",
	ROUTE_UNSHARE_YES = "Stop sharing",
	ROUTE_DELETE_YES = "Delete",
	ROUTE_DELETE_CONFIRM = "Delete the route “%s” and its %d stops?",
	ROUTE_DELETE_CONFIRM_ONE = "Delete the route “%s” and its stop?",
	ROUTE_DELETE_CONFIRM_EMPTY = "Delete the route “%s”? It has no stops.",
	ROUTE_DELETED = "Route deleted: %s",
	MANAGER_HINT = "Click: show on the map · Drag: reorder, or onto a route to move it (Shift: copy) · Right-click: menu",
	MENU_MOVE_TO = "Move to",
	MENU_COPY_TO = "Copy to",

	-- Importar una lista de /way
	IMPORT_OPEN = "Import stops",
	IMPORT_TITLE_ROUTE = "Import stops into “%s”",
	IMPORT_HINT = "Paste /way lines here, one per line. Each one becomes a stop, in order.",
	IMPORT_CLEAR_FIRST = "Clear this route's stops before importing",
	IMPORT_BUTTON = "Import",
	IMPORT_ADDED = "Import: %d stops added",
	IMPORT_REPEATED = "%d repeated",
	IMPORT_BAD = "%d lines not understood",
	MANAGER_EMPTY = "This route has no stops yet. Alt+click on the map to add one.",
	MANAGER_NO_MATCH = "No routes or stops match the search.",
	SEARCH_ROUTE = "%d route",
	SEARCH_ROUTES = "%d routes",
	SEARCH_STOP = "%d stop",
	SEARCH_STOPS = "%d stops",
	TIP_UP = "Move up",
	TIP_DOWN = "Move down",
	MENU_RENAME = "Edit name and description",
	MENU_SHARE = "Share with",
	SHARE_PARTY = "Party",
	SHARE_RAID = "Raid",
	SHARE_BATTLEGROUND = "Battleground",
	SHARE_GUILD = "Guild",
	DEFAULT_ROUTE = "My route",
	CURRENT_ROUTE = "Current route",
	BUTTON_TIP_ROUTE = "Current route: %s",
	ROUTE_MODIFIED = "%s (modified)",
	CURRENT_ROUTE_TIP = "Current route: the one the compass, the map and AzerothGPS follow. Load a saved route into it with its ▶ button.",
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
	ROUTE_DONE = "Route completed.",
	REACHED_TIP = "Already reached (restart the route to walk it again)",
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
	HELP_MANAGE = "open the Manage routes window",
	HELP_IMPORT = "import stops by pasting a list of /way lines",
	HELP_CLEAR = "empty the Current route (and the AzerothGPS route, if installed); your corpse stays",
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
	L.STOP_ADDED_TO = "Parada añadida a «%s»"
	L.DIRECT_ROUTE = "Ruta directa a"
	L.STOP_MOVED = "Parada movida"
	L.STOP_MOVED_TO = "Parada movida: %s → %s"
	L.STOP_COPIED_TO = "Parada copiada: %s → %s"
	L.STOP_REMOVED = "Parada quitada: %s"
	L.ROUTE_CLEARED = "Ruta actual vaciada."
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
	L.MENU_CLEAR_STOPS = "Vaciar Ruta actual"
	L.CLEAR_CONFIRM = "¿Vaciar la Ruta actual?"
	L.CLEAR_STOPS = "Se quitarán sus %d paradas (tu cadáver se queda)."
	L.CLEAR_STOPS_ONE = "Se quitará su parada (tu cadáver se queda)."
	L.CLEAR_YES = "Vaciar"
	L.MENU_ASK_NAME = "Pedir nombre al añadir"
	L.MENU_MANAGE = "Gestionar rutas…"
	L.MANAGER_TITLE = "Gestionar rutas"
	L.MANAGER_ROUTES = "Rutas"
	L.ROUTE_LOAD = "Cargar en la Ruta actual"
	L.ROUTE_LOADED_TIP = "Última ruta cargada (clic para volver a cargarla)"
	L.ROUTE_LOADED = "Ruta cargada en la Ruta actual: %s"
	L.LOAD_CONFIRM = "¿Cargar «%s» en la Ruta actual?"
	L.LOAD_REPLACE = "Se sustituirán las %d paradas que tiene ahora (tu cadáver se conserva)."
	L.LOAD_REPLACE_ONE = "Se sustituirá la parada que tiene ahora (tu cadáver se conserva)."
	L.LOAD_YES = "Cargar"
	L.ROUTE_NEW = "Nueva ruta"
	L.ROUTE_NEW_NAME = "Ruta %d"
	L.ROUTE_NAME_HINT = "Nombre de la ruta (Intro: aceptar · Esc: cancelar)"
	L.ROUTE_CREATED = "Ruta creada: %s"
	L.ROUTE_RENAME = "Renombrar ruta"
	L.ROUTE_RENAMED = "Ruta renombrada: %s"
	L.ROUTE_DUPLICATE = "Duplicar ruta"
	L.ROUTE_COPY_NAME = "%s (copia)"
	L.ROUTE_DUPLICATED = "Ruta duplicada: %s"
	L.ROUTE_RESTART = "Reiniciar la ruta desde su primera parada"
	L.ROUTE_RESTARTED = "Ruta reiniciada: %s"
	L.ROUTE_DELETE = "Borrar ruta"
	L.ROUTE_DELETE_SHARED = "Está compartida: desaparecerá para todos tus personajes."
	L.ROUTE_SHARED = "Compartida con mis personajes"
	L.ROUTE_SHARED_TIP = "Las rutas compartidas las ven y editan todos los personajes de tu cuenta (salen en azul en la lista). Lo que recorre cada personaje sigue siendo suyo, en su Ruta actual."
	L.ROUTE_SHARED_ON = "Ruta compartida con tus personajes: %s"
	L.ROUTE_SHARED_OFF = "Ruta ya no compartida: %s"
	L.ROUTE_UNSHARE_CONFIRM = "¿Dejar de compartir «%s»? Tus otros personajes dejarán de verla."
	L.ROUTE_UNSHARE_YES = "Dejar de compartir"
	L.ROUTE_DELETE_YES = "Borrar"
	L.ROUTE_DELETE_CONFIRM = "¿Borrar la ruta «%s» y sus %d paradas?"
	L.ROUTE_DELETE_CONFIRM_ONE = "¿Borrar la ruta «%s» y su parada?"
	L.ROUTE_DELETE_CONFIRM_EMPTY = "¿Borrar la ruta «%s»? No tiene paradas."
	L.ROUTE_DELETED = "Ruta borrada: %s"
	L.MANAGER_HINT = "Clic: ver en el mapa · Arrastrar: reordenar, o sobre una ruta para moverla (Mayús: copiar) · Clic derecho: menú"
	L.MENU_MOVE_TO = "Mover a"
	L.MENU_COPY_TO = "Copiar a"

	L.IMPORT_OPEN = "Importar paradas"
	L.IMPORT_TITLE_ROUTE = "Importar paradas en «%s»"
	L.IMPORT_HINT = "Pega aquí las líneas /way, una por línea. Cada una será una parada, en orden."
	L.IMPORT_CLEAR_FIRST = "Borrar las paradas de esta ruta antes de importar"
	L.IMPORT_BUTTON = "Importar"
	L.IMPORT_ADDED = "Importar: %d paradas añadidas"
	L.IMPORT_REPEATED = "%d repetidas"
	L.IMPORT_BAD = "%d líneas no entendidas"
	L.MANAGER_EMPTY = "Esta ruta aún no tiene paradas. Alt+clic en el mapa para añadir una."
	L.MANAGER_NO_MATCH = "Ninguna ruta ni parada coincide con la búsqueda."
	L.SEARCH_ROUTE = "%d ruta"
	L.SEARCH_ROUTES = "%d rutas"
	L.SEARCH_STOP = "%d parada"
	L.SEARCH_STOPS = "%d paradas"
	L.TIP_UP = "Subir"
	L.TIP_DOWN = "Bajar"
	L.MENU_RENAME = "Editar nombre y descripción"
	L.MENU_SHARE = "Compartir con"
	L.SHARE_PARTY = "Grupo"
	L.SHARE_RAID = "Banda"
	L.SHARE_BATTLEGROUND = "Campo de batalla"
	L.SHARE_GUILD = "Hermandad"
	L.DEFAULT_ROUTE = "Mi ruta"
	L.CURRENT_ROUTE = "Ruta actual"
	L.BUTTON_TIP_ROUTE = "Ruta actual: %s"
	L.ROUTE_MODIFIED = "%s (modificada)"
	L.CURRENT_ROUTE_TIP = "Ruta actual: la que siguen la brújula, el mapa y AzerothGPS. Carga en ella una ruta guardada con su botón ▶."
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
	L.ROUTE_DONE = "Ruta completada."
	L.REACHED_TIP = "Ya has llegado aquí (reinicia la ruta para volver a recorrerla)"
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
	L.HELP_MANAGE = "abrir la ventana Gestionar rutas"
	L.HELP_IMPORT = "importar paradas pegando una lista de líneas /way"
	L.HELP_CLEAR = "vaciar la Ruta actual (y la ruta de AzerothGPS, si lo tienes); tu cadáver se queda"
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
