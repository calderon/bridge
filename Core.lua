--[[
Bridge
Sistema de paradas sobre el mapa del mundo (el de Blizzard, que Leatrix Maps mejora).
Si AzerothGPS está instalado, además mantiene al día su ruta.

  * Alt + clic en el mapa o en un icono ..... añade una parada (con el nombre del icono)
  * Alt + Mayús + clic ....................... borra la ruta y va SOLO a ese punto
  * Alt + clic / arrastrar sobre una parada .. la quita / la mueve
  * Botón "Bridge" del mapa .................. modo ruta y borrar todas las paradas
  * Questie: "Establecer ruta" / "Añadir como parada" en el menú del rastreador
  * /bridge .................................. ayuda

Envío a AzerothGPS: con líneas "/way zona x y nombre" y "/agps clear". AzerothGPS no
las registra como comandos, sino que lee lo que se escribe en el chat; Bridge las
escribe ahí por ti. AzerothGPS no permite leer su ruta, así que la información solo
va de Bridge a AzerothGPS (y del aviso de llegada de su API, de vuelta).
]]

local ADDON, ns = ...
local L, W = ns.L, ns.W -- textos en el idioma del juego y palabras de los comandos (Locales.lua)
local PIN_TEMPLATE = "BridgePinTemplate"

-- La versión va aquí (y no solo en el .toc) porque el juego no relee el .toc con /reload.
-- No cambiarla a mano: release-please la actualiza aquí y en Bridge.toc en cada versión.
local VERSION = "1.2.0" -- x-release-please-version
local PIN_TEXTURE = "Interface\\AddOns\\Bridge\\Media\\pin"
local PIN_TEXTURE_HOVER = "Interface\\AddOns\\Bridge\\Media\\pin_hover"

-- Aspecto de un marcador: pin verde con su número
-- Ya alcanzada en el recorrido: en gris (sin color y algo transparente) hasta reiniciar
local function ApplyLook(icon, label, stop, number, size, hover)
	icon:SetTexture(hover and PIN_TEXTURE_HOVER or PIN_TEXTURE)
	label:SetText(number or "")
	local reached = stop and stop.reached and true or false
	icon:SetDesaturated(reached)
	icon:SetAlpha(reached and 0.6 or 1)
	label:SetAlpha(reached and 0.6 or 1)
end

local DB

-- Rutas (2.0), modelo "reproductor de música": DB.routes (en orden) tiene la Ruta actual
-- (route.quick: la primera, de cada personaje) y las rutas guardadas, que son plantillas.
-- Lo que se recorre es siempre la Ruta actual; cargar una ruta guardada copia sus paradas
-- en ella. DB.loadedRoute = id de la última ruta guardada cargada (solo como referencia).
local DATA_VERSION = 3 -- versión de los datos guardados, para migrar en el futuro

-- Rutas compartidas con todos los personajes de la cuenta: se guardan aparte, en datos de
-- la cuenta (BridgeSharedDB), con id de texto ("s1", "s2"…) para no coincidir con las
-- privadas. La Ruta actual nunca se comparte.
local SharedDB

-- Todas las rutas que ve este personaje: la actual primero y después las guardadas
-- (privadas y compartidas juntas) por orden alfabético, para que una ruta no cambie de
-- sitio al compartirla o dejar de compartirla
local function AllRoutes()
	local current, saved = nil, {}
	for _, route in ipairs(DB.routes) do
		if route.quick then current = route else table.insert(saved, route) end
	end
	if SharedDB then
		for _, route in ipairs(SharedDB.routes) do table.insert(saved, route) end
	end
	table.sort(saved, function(a, b)
		local na, nb = (a.name or ""):lower(), (b.name or ""):lower()
		if na ~= nb then return na < nb end
		return tostring(a.id) < tostring(b.id)
	end)
	if current then table.insert(saved, 1, current) end
	return saved
end

-- Compartir una ruta guardada con todos tus personajes, o dejar de compartirla (vuelve a
-- ser solo de este personaje). Cambia de sitio y de id.
local function SetRouteShared(route, shared)
	if not route or route.quick or not SharedDB or (route.shared == true) == shared then return end
	local from, to = shared and DB.routes or SharedDB.routes, shared and SharedDB.routes or DB.routes
	for i, other in ipairs(from) do
		if other == route then table.remove(from, i) break end
	end
	local oldId = route.id
	if shared then
		SharedDB.nextRouteId = (SharedDB.nextRouteId or 0) + 1
		route.id, route.shared = "s" .. SharedDB.nextRouteId, true
	else
		DB.nextRouteId = (DB.nextRouteId or 0) + 1
		route.id, route.shared = DB.nextRouteId, nil
	end
	table.insert(to, route)
	if DB.loadedRoute == oldId then DB.loadedRoute = route.id end
	return true
end

local function NewRoute(name)
	DB.nextRouteId = (DB.nextRouteId or 0) + 1
	local route = { id = DB.nextRouteId, name = name, stops = {} }
	table.insert(DB.routes, route)
	return route
end

-- La Ruta actual: siempre existe, es la primera de la lista y de cada personaje. Es la que
-- siguen la brújula, el mapa, el minimapa y AzerothGPS. No se puede borrar ni renombrar.
-- (En los datos se marca con route.quick: antes se llamaba "Ruta rápida".)
local function CurrentRoute()
	for _, route in ipairs(DB.routes) do
		if route.quick then return route end
	end
end

local function EnsureCurrentRoute()
	local current = CurrentRoute()
	if not current then
		DB.nextRouteId = (DB.nextRouteId or 0) + 1
		current = { id = DB.nextRouteId, stops = {}, quick = true }
		table.insert(DB.routes, 1, current)
	end
	current.name = L.CURRENT_ROUTE -- siempre en el idioma del juego
	return current
end

-- Tu cadáver (si lo hay): se guarda en la Ruta actual (es de cada personaje) y va primero
local function CorpseStop()
	local current = CurrentRoute()
	if not current then return end
	for _, st in ipairs(current.stops) do
		if st.corpse then return st end
	end
end

-- La ruta que se recorre: siempre la Ruta actual
local function ActiveRoute()
	return CurrentRoute() or EnsureCurrentRoute()
end

-- La lista de paradas que se está usando: la de la Ruta actual. Todo el código la
-- pide aquí, y no a DB directamente.
local function Stops()
	return ActiveRoute().stops
end

-- Para actuar sobre una ruta concreta (la ventana Gestionar rutas): sin ruta, la actual.
-- Solo la actual se manda a AzerothGPS, al mapa, a la brújula y a los eventos de la API.
local function StopsOf(route)
	return (route or ActiveRoute()).stops
end

local function IsActiveRoute(route)
	return not route or route.quick == true
end

-- Recorrido: al llegar a una parada se marca como alcanzada (st.reached) en vez de
-- borrarla. La siguiente del recorrido es la primera que aún no se ha alcanzado.
local function NextStopIndex(after)
	local stops = Stops()
	for i = (after or 0) + 1, #stops do
		if not stops[i].reached then return i, stops[i] end
	end
end

-- Como NextStopIndex, pero sin contar tu cadáver (para no poner nada delante de él)
local function NextWaypointIndex()
	for i, st in ipairs(Stops()) do
		if not st.reached and not st.corpse then return i, st end
	end
end

-- Datos de la 1.x (una sola lista, DB.stops): pasan a la ruta guardada "Mi ruta", que se
-- carga en la Ruta actual. Datos de la 2.0 en desarrollo (versión 2, con "ruta activa"):
-- la que estaba activa se carga en la Ruta actual, con lo ya recorrido.
local function MigrateData()
	if not DB.routes then
		DB.routes = {}
		local route = NewRoute(L.DEFAULT_ROUTE)
		if type(DB.stops) == "table" then route.stops = DB.stops end
		DB.activeRoute = route.id
	end
	local current = EnsureCurrentRoute()
	if (DB.dataVersion or 0) < 3 then
		local old
		for _, route in ipairs(DB.routes) do
			if route.id == DB.activeRoute and not route.quick then old = route end
		end
		if old then
			-- Se conserva tu cadáver, si lo había; el resto, copia de la que estaba activa
			for i = #current.stops, 1, -1 do
				if not current.stops[i].corpse then table.remove(current.stops, i) end
			end
			for _, st in ipairs(old.stops) do
				if not st.corpse then
					local copy = {}
					for k, v in pairs(st) do copy[k] = v end
					table.insert(current.stops, copy)
				end
			end
			DB.loadedRoute = old.id
		end
		-- Las rutas guardadas no se recorren: ninguna parada alcanzada
		for _, route in ipairs(DB.routes) do
			if not route.quick then
				for _, st in ipairs(route.stops) do st.reached = nil end
			end
		end
	end
	DB.activeRoute = nil
	DB.stops = nil
	DB.keepStops = nil -- opción quitada en la 2.0: las rutas se guardan siempre
	DB.dataVersion = DATA_VERSION
end

local routeMode = false
local providers = {}
local managerFrame -- ventana "Gestionar rutas" (se crea al abrirla por primera vez)

-- Últimas líneas escritas por Bridge (para poder copiarlas) y captura de un comando
local recentLines = {}
local captureBuf

local function Plain(text)
	return (tostring(text):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Bridge|r: " .. tostring(msg))
	local line = Plain(msg)
	table.insert(recentLines, line)
	if #recentLines > 300 then table.remove(recentLines, 1) end
	if captureBuf then table.insert(captureBuf, line) end
end

---------------------------------------------------------------------------
-- Identificadores y avisos (para la API pública, BridgeAPI)
---------------------------------------------------------------------------

-- Cada parada tiene un id que no cambia aunque se reordene, renombre o mueva
local function NewStopId()
	DB.nextId = (DB.nextId or 0) + 1
	return DB.nextId
end

-- Copia de una parada para otros addons (nunca la tabla interna)
local function PublicStop(s)
	if not s then return nil end
	local index
	for i, st in ipairs(Stops()) do
		if st == s then index = i break end
	end
	return {
		id = s.id, index = index, name = s.name, zone = s.zone,
		mapID = s.mapID, x = s.x, y = s.y, source = s.source, description = s.desc,
		reached = s.reached and true or false,
	}
end

-- callbacks[evento][dueño] = función
local callbacks = {}
local function Fire(event, ...)
	local list = callbacks[event]
	if not list then return end
	for owner, fn in pairs(list) do
		local ok, err = pcall(fn, event, ...)
		if not ok and DB and DB.debug then Print(L.DEBUG_HANDLER_ERROR:format(tostring(owner), tostring(err))) end
	end
end

-- Ventana con un cuadro de texto que se puede seleccionar y copiar (Cmd+C en Mac)
local logFrame
local function ShowLog(lines, title)
	if not logFrame then
		local f = CreateFrame("Frame", "BridgeLogFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
		f:SetSize(640, 420)
		f:SetPoint("CENTER")
		f:SetFrameStrata("DIALOG")
		f:SetToplevel(true)
		if f.SetBackdrop then
			f:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
				tile = true, tileSize = 32, edgeSize = 32,
				insets = { left = 11, right = 12, top = 12, bottom = 11 },
			})
		end
		f:EnableMouse(true)
		f:SetMovable(true)
		f:RegisterForDrag("LeftButton")
		f:SetScript("OnDragStart", f.StartMoving)
		f:SetScript("OnDragStop", f.StopMovingOrSizing)

		f.Title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		f.Title:SetPoint("TOP", 0, -18)
		local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		hint:SetPoint("BOTTOM", 0, 16)
		hint:SetText(L.LOG_HINT)

		local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", -6, -6)

		local sf = CreateFrame("ScrollFrame", "BridgeLogScroll", f, "UIPanelScrollFrameTemplate")
		sf:SetPoint("TOPLEFT", 22, -42)
		sf:SetPoint("BOTTOMRIGHT", -40, 36)
		local eb = CreateFrame("EditBox", nil, sf)
		eb:SetMultiLine(true)
		eb:SetAutoFocus(false)
		eb:SetFontObject(ChatFontNormal)
		eb:SetWidth(570)
		eb:SetScript("OnEscapePressed", function() f:Hide() end)
		sf:SetScrollChild(eb)
		f.Edit = eb
		table.insert(UISpecialFrames, "BridgeLogFrame") -- Esc la cierra
		logFrame = f
	end
	logFrame.Title:SetText(title or ("Bridge " .. VERSION))
	logFrame.Edit:SetText(table.concat(lines, "\n"))
	logFrame:Show()
	logFrame.Edit:SetFocus()
	logFrame.Edit:HighlightText()
end

---------------------------------------------------------------------------
-- Ejecutar comandos de barra como si el jugador los escribiera en el chat
---------------------------------------------------------------------------

-- Todos los addons que registran un comando. El chat solo entrega el comando a UNO
-- de ellos; aquí los sacamos todos.
local function HandlersFor(cmd)
	cmd = cmd:lower()
	local list, seen = {}, {}
	for key, fn in pairs(SlashCmdList) do
		local i = 1
		-- El /way que registra Bridge (BRIDGEWAY) no cuenta: es solo para el jugador
		local alias = key ~= "BRIDGEWAY" and _G["SLASH_" .. key .. i]
		while alias do
			if type(alias) == "string" and alias:lower() == cmd then
				if not seen[fn] then
					seen[fn] = true
					table.insert(list, { key = key, fn = fn })
				end
				break
			end
			i = i + 1
			alias = _G["SLASH_" .. key .. i]
		end
	end
	return list
end

local function SlashExists(cmd)
	return #HandlersFor(cmd) > 0
end

local Senders = {}

-- Si algún addon tiene el comando registrado: se le llama directamente
function Senders.todos(line, cmd, rest)
	local any = false
	for _, h in ipairs(HandlersFor(cmd)) do
		local ok, err = pcall(h.fn, rest, DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox)
		if ok then any = true elseif DB.debug then Print(L.DEBUG_HANDLER_ERROR:format(h.key, tostring(err))) end
	end
	return any
end

-- true mientras Bridge manda sus propios comandos (para no copiarlos de vuelta)
local sendingOurs = false

-- "enter": escribe la línea en la caja del chat y pulsa Intro, como si fueras tú.
-- No se hace al momento: se pone en cola y se manda un instante después. Si se
-- mandara mientras el chat aún procesa un comando tuyo (p. ej. /bridge borrar), la
-- caja todavía tendría tu comando y se volvería a ejecutar una y otra vez.
local chatQueue, chatScheduled = {}, false
local FlushChatQueue
local function ScheduleChatFlush(delay)
	if chatScheduled then return end
	chatScheduled = true
	C_Timer.After(delay or 0, function()
		chatScheduled = false
		FlushChatQueue()
	end)
end
FlushChatQueue = function()
	local eb = DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox
	if not eb then wipe(chatQueue) return end
	-- Si estás escribiendo algo en el chat, esperamos a que termines
	if eb:HasFocus() and (eb:GetText() or "") ~= "" then
		ScheduleChatFlush(0.5)
		return
	end
	local onEnter = eb:GetScript("OnEnterPressed")
	while #chatQueue > 0 do
		local line = table.remove(chatQueue, 1)
		sendingOurs = true
		eb:SetText(line)
		if onEnter then
			pcall(onEnter, eb)
		elseif ChatEdit_SendText then
			pcall(ChatEdit_SendText, eb, 0)
		end
		sendingOurs = false
		if (eb:GetText() or "") ~= "" then eb:SetText("") end
	end
end
function Senders.enter(line)
	if not (DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox) then return false end
	table.insert(chatQueue, line)
	ScheduleChatFlush(0)
	return true
end

local function RunSlash(line)
	local cmd, rest = line:match("^(/%S+)%s*(.*)$")
	if not cmd then return false end
	-- AzerothGPS no registra /agps ni /way como comandos: lee lo que se escribe en el
	-- chat. Si nadie tiene registrado el comando, lo escribimos en el chat por ti.
	local sender = SlashExists(cmd) and Senders.todos or Senders.enter
	if DB.debug then Print(L.DEBUG_SENDING:format(line)) end
	sendingOurs = true
	local ok, result = pcall(sender, line, cmd, rest)
	sendingOurs = false
	return ok and result
end

-- AzerothGPS es opcional. Sin él, las paradas se quedan solo en el mapa: no hay a
-- quién mandarlas (y escribir /way en el chat daría "comando desconocido").
local function HasGPS()
	return type(AzerothGPS) == "table"
end

local function SendToGPS(line)
	if not HasGPS() then return true end
	return RunSlash(line)
end

---------------------------------------------------------------------------
-- Coordenadas
---------------------------------------------------------------------------

-- Devuelve continente y posición de mundo (yardas) de un punto del mapa.
local function ToWorld(mapID, x, y)
	local cont, world = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
	if cont and world then return cont, world.x, world.y end
end

-- /way necesita una zona. Si el clic es en un mapa de continente, buscamos la
-- zona que hay debajo y convertimos las coordenadas a esa zona.
local function ToZone(mapID, x, y)
	local info = mapID and C_Map.GetMapInfo(mapID)
	if not info then return end

	local continentType = Enum and Enum.UIMapType and Enum.UIMapType.Continent or 2
	if info.mapType and info.mapType <= continentType then
		local sub = C_Map.GetMapInfoAtPosition(mapID, x, y)
		if sub and sub.mapID and sub.mapID ~= mapID then
			local cont, wx, wy = ToWorld(mapID, x, y)
			if cont then
				local _, pos = C_Map.GetMapPosFromWorldPos(cont, CreateVector2D(wx, wy), sub.mapID)
				if pos then return sub.mapID, pos.x, pos.y, sub.name end
			end
		end
		return nil
	end
	return mapID, x, y, info.name
end

---------------------------------------------------------------------------
-- Paradas
---------------------------------------------------------------------------

local UpdateCompassShown -- más abajo (brújula)
local function RefreshPins()
	if UpdateCompassShown then UpdateCompassShown() end
	for provider in pairs(providers) do
		if provider:GetMap() then provider:RefreshAllData() end
	end
	if managerFrame and managerFrame:IsShown() then managerFrame:Refresh() end
end

-- Limpia un nombre o una descripción: sin saltos de línea ni "|" (códigos de color); nil si queda vacío
local function CleanName(name)
	if type(name) ~= "string" then return nil end
	name = name:gsub("[\r\n|]", " "):match("^%s*(.-)%s*$")
	return name ~= "" and name or nil
end

-- Añade la parada ya con su nombre definitivo
-- opts.route: añadirla a esa ruta en vez de a la activa
local function CommitStop(zMap, zx, zy, zoneName, name, exclusive, opts)
	opts = opts or {}
	local active = IsActiveRoute(opts.route)
	if exclusive and active then
		SendToGPS("/agps clear")
		wipe(Stops())
		Fire("STOPS_CLEARED")
	end
	local line = string.format("/way %s %.1f %.1f %s", zoneName, zx * 100, zy * 100, name)
	if not active or SendToGPS(line) then
		local cont, wx, wy = ToWorld(zMap, zx, zy)
		local stop = {
			id = NewStopId(), name = name, zone = zoneName, mapID = zMap, x = zx, y = zy,
			cont = cont, wx = wx, wy = wy, line = line, source = opts.source,
			desc = CleanName(opts.description),
		}
		table.insert(StopsOf(opts.route), stop)
		if not opts.silent then
			Print(string.format("%s: |cffffd100%s|r (%s %.1f, %.1f)",
				exclusive and L.DIRECT_ROUTE or L.STOP_ADDED, name, zoneName, zx * 100, zy * 100))
		end
		RefreshPins()
		if active then Fire("STOP_ADDED", PublicStop(stop)) end
		return stop
	else
		Print(L.SEND_FAILED)
	end
end

---------------------------------------------------------------------------
-- Caja para poner nombre a una parada nueva
--   Intro: aceptar · Esc: cancelar (no se añade) · clic fuera: aceptar
---------------------------------------------------------------------------

local nameBox
-- onAccept(nombre, descripción): la descripción es opcional (nil si se deja vacía)
-- opts (opcional): { hint = "título de la caja", noDescription = true (solo el nombre),
--   anchor = frame (la caja sale encima de él, alineada a su izquierda; si no, junto al ratón) }
local function AskName(suggestion, onAccept, description, opts)
	if not nameBox then
		local f = CreateFrame("Frame", "BridgeNameFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
		f:SetSize(230, 90)
		f:SetFrameStrata("FULLSCREEN_DIALOG")
		f:SetToplevel(true)
		f:EnableMouse(true)
		if f.SetBackdrop then
			f:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true, tileSize = 16, edgeSize = 14,
				insets = { left = 3, right = 3, top = 3, bottom = 3 },
			})
			f:SetBackdropColor(0, 0, 0, 0.9)
		end
		local hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		hint:SetPoint("TOPLEFT", 10, -7)
		local eb = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
		eb:SetHeight(20)
		eb:SetPoint("TOPLEFT", 14, -22)
		eb:SetAutoFocus(false)
		eb:SetMaxLetters(60)
		local descHint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		descHint:SetPoint("TOPLEFT", eb, "BOTTOMLEFT", -4, -8)
		descHint:SetText(L.DESC_BOX_HINT)
		local db = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
		db:SetHeight(20)
		db:SetPoint("TOPLEFT", descHint, "BOTTOMLEFT", 4, -3)
		db:SetAutoFocus(false)
		db:SetMaxLetters(200)
		local function Close(accept)
			if f.closing then return end
			f.closing = true
			local cb, text, desc = f.onAccept, eb:GetText(), db:GetText()
			f.onAccept = nil
			eb:ClearFocus()
			db:ClearFocus()
			f:Hide()
			f.closing = false
			if accept and cb then cb(CleanName(text) or f.suggestion, CleanName(desc)) end
		end
		for _, box in ipairs({ eb, db }) do
			box:SetScript("OnEnterPressed", function() Close(true) end)
			box:SetScript("OnEscapePressed", function() Close(false) end)
			-- Tab: pasar al otro campo
			box:SetScript("OnTabPressed", function(self)
				local other = self == eb and db or eb
				if not other:IsShown() then return end
				other:SetFocus()
				other:HighlightText()
			end)
			-- Clic fuera de la caja: se acepta lo que haya escrito. Se mira un instante
			-- después, porque al pasar de un campo al otro uno pierde el foco antes de
			-- que el otro lo gane.
			box:SetScript("OnEditFocusLost", function()
				C_Timer.After(0, function()
					if f:IsShown() and not eb:HasFocus() and not db:HasFocus() then Close(true) end
				end)
			end)
		end
		f.Edit, f.Desc, f.Close = eb, db, Close
		f.Hint, f.DescHint = hint, descHint
		nameBox = f
	end
	-- Título y campos según para qué sea (parada: nombre y descripción; ruta: solo nombre)
	opts = opts or {}
	nameBox.Hint:SetText(opts.hint or L.NAME_BOX_HINT)
	nameBox.DescHint:SetShown(not opts.noDescription)
	nameBox.Desc:SetShown(not opts.noDescription)
	nameBox:SetHeight(opts.noDescription and 52 or 90)
	-- El ancho se ajusta al título (cambia según el idioma)
	local width = math.max(230, math.ceil(nameBox.Hint:GetStringWidth()) + 22)
	nameBox:SetWidth(width)
	nameBox.Edit:SetWidth(width - 26)
	nameBox.Desc:SetWidth(width - 26)
	-- Si había otra caja abierta, se acepta antes de abrir la nueva
	if nameBox:IsShown() then nameBox.Close(true) end
	nameBox.suggestion, nameBox.onAccept = suggestion, onAccept
	nameBox:ClearAllPoints()
	if opts.anchor then
		nameBox:SetPoint("BOTTOMLEFT", opts.anchor, "TOPLEFT", -4, 4)
	else
		local scale = UIParent:GetEffectiveScale()
		local cx, cy = GetCursorPosition()
		nameBox:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cx / scale + 14, cy / scale + 10)
	end
	nameBox:SetClampedToScreen(true)
	nameBox:Show()
	nameBox:Raise() -- por encima de la ventana Gestionar rutas
	nameBox.Desc:SetText(description or "")
	nameBox.Edit:SetText(suggestion)
	nameBox.Edit:SetFocus()
	nameBox.Edit:HighlightText()
end

---------------------------------------------------------------------------
-- Confirmación pequeña (p. ej. borrar una ruta), encima de lo que la abre
---------------------------------------------------------------------------

local confirmBox
local function Confirm(text, yesText, onYes, anchor)
	if not confirmBox then
		local f = CreateFrame("Frame", "BridgeConfirmFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
		f:SetSize(280, 80)
		f:SetFrameStrata("FULLSCREEN_DIALOG")
		f:SetToplevel(true)
		f:EnableMouse(true)
		f:SetClampedToScreen(true)
		if f.SetBackdrop then
			f:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true, tileSize = 16, edgeSize = 14,
				insets = { left = 3, right = 3, top = 3, bottom = 3 },
			})
			f:SetBackdropColor(0, 0, 0, 0.95)
		end
		f.Text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		f.Text:SetPoint("TOPLEFT", 12, -12)
		f.Text:SetPoint("TOPRIGHT", -12, -12)
		f.Text:SetJustifyH("LEFT")
		f.Text:SetWordWrap(true)
		f.No = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		f.No:SetSize(100, 22)
		f.No:SetPoint("BOTTOMRIGHT", -10, 10)
		f.No:SetText(CANCEL or "Cancel")
		f.No:SetScript("OnClick", function() f:Hide() end)
		f.Yes = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		f.Yes:SetSize(100, 22)
		f.Yes:SetPoint("RIGHT", f.No, "LEFT", -6, 0)
		f.Yes:SetScript("OnClick", function()
			local cb = f.onYes
			f.onYes = nil
			f:Hide()
			if cb then cb() end
		end)
		f:Hide()
		confirmBox = f
	end
	local f = confirmBox
	f.onYes = onYes
	-- El botón se ensancha según su texto (y la caja, si hace falta)
	f.Yes:SetText(yesText)
	local fs = f.Yes:GetFontString()
	local yesWidth = math.max(100, math.ceil(fs and fs:GetStringWidth() or 0) + 28)
	f.Yes:SetWidth(yesWidth)
	f:SetWidth(math.max(280, yesWidth + 100 + 6 + 20))
	f.Text:SetText(text)
	f:SetHeight(math.ceil(f.Text:GetStringHeight()) + 52)
	f:ClearAllPoints()
	f:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", -4, 4)
	f:Show()
	f:Raise()
end

-- askName: true cuando la parada la pone el jugador en el mapa (Alt+clic)
-- opts (opcional): { source = "quién la añade", silent = true para no escribir en el chat }
-- Devuelve la parada creada (salvo si se pide el nombre: entonces se crea al aceptar).
local function AddStop(mapID, x, y, name, exclusive, askName, opts)
	if not x or not y or x < 0 or x > 1 or y < 0 or y > 1 then return end

	local zMap, zx, zy, zoneName = ToZone(mapID, x, y)
	if not zMap then
		Print(L.ZOOM_IN)
		return
	end
	-- Sin nombre (no es un icono): el de la zona. El número ya lo lleva el pin.
	local suggestion = CleanName(name) or zoneName
	if askName and DB.askName ~= false then
		AskName(suggestion, function(finalName, description)
			local withDesc = {}
			for k, v in pairs(opts or {}) do withDesc[k] = v end
			withDesc.description = description
			CommitStop(zMap, zx, zy, zoneName, finalName, exclusive, withDesc)
		end)
	else
		return CommitStop(zMap, zx, zy, zoneName, suggestion, exclusive, opts)
	end
end

-- AzerothGPS no permite quitar una sola parada: borramos su ruta y le
-- volvemos a mandar las que quedan.
local rebuildPending = false
local function RebuildRoute()
	if rebuildPending then return end
	rebuildPending = true
	-- Pequeña espera: si se quitan varias seguidas, se reconstruye una sola vez
	C_Timer.After(0.2, function()
		rebuildPending = false
		SendToGPS("/agps clear")
		for _, other in ipairs(Stops()) do
			-- Las ya alcanzadas no: AzerothGPS solo lleva lo que queda del recorrido
			if other.line and not other.reached then SendToGPS(other.line) end
		end
	end)
end

local function RemoveStop(index, route)
	local stops = StopsOf(route)
	local s = stops[index]
	if not s then return end
	local active = IsActiveRoute(route)
	local public = active and PublicStop(s)
	table.remove(stops, index)
	if active then RebuildRoute() end
	RefreshPins()
	Print(L.STOP_REMOVED:format(s.name or "?"))
	if active then Fire("STOP_REMOVED", public) end
end

local function ClearStops(silent, route)
	local active = IsActiveRoute(route)
	if active then SendToGPS("/agps clear") end
	wipe(StopsOf(route))
	RefreshPins()
	if not silent then Print(L.ROUTE_CLEARED) end
	if active then Fire("STOPS_CLEARED") end
end

-- Quita de golpe todas las paradas que cumplan 'match' (una sola reconstrucción)
local function RemoveStopsWhere(match)
	local removed = {}
	for i = #Stops(), 1, -1 do
		if match(Stops()[i]) then
			table.insert(removed, PublicStop(Stops()[i]))
			table.remove(Stops(), i)
		end
	end
	if #removed > 0 then
		RebuildRoute()
		RefreshPins()
		Print(L.STOPS_REMOVED:format(#removed))
		for _, public in ipairs(removed) do Fire("STOP_REMOVED", public) end
	end
end

-- Cambia el nombre y, si se pasa (aunque sea nil, para quitarla), la descripción
local function RenameStop(index, newName, newDesc, setDesc, route)
	local s = StopsOf(route)[index]
	local active = IsActiveRoute(route)
	if not s or not newName then return end
	local nameChanged = newName ~= s.name
	local descChanged = setDesc and newDesc ~= s.desc
	if not nameChanged and not descChanged then return end
	if descChanged then s.desc = newDesc end
	if nameChanged then
		s.name = newName
		s.line = string.format("/way %s %.1f %.1f %s", s.zone, s.x * 100, s.y * 100, newName)
		if active then RebuildRoute() end -- AzerothGPS necesita el nombre nuevo
	end
	RefreshPins()
	Print((nameChanged and L.STOP_RENAMED or L.STOP_EDITED):format(newName))
	if active then Fire("STOP_CHANGED", PublicStop(s)) end
	return true
end

-- Nombre de ruta sin repetir: si ya existe, se le añade " (2)", " (3)"…
-- except: una ruta que no cuenta (la que se está renombrando)
local function UniqueRouteName(name, except)
	local function Taken(candidate)
		for _, route in ipairs(AllRoutes()) do
			if route ~= except and (route.name or ""):lower() == candidate:lower() then return true end
		end
	end
	local candidate, n = name, 1
	while Taken(candidate) do
		n = n + 1
		candidate = string.format("%s (%d)", name, n)
	end
	return candidate
end

-- Ruta nueva, vacía (no se activa)
local function CreateRoute(name)
	local route = NewRoute(UniqueRouteName(name))
	Print(L.ROUTE_CREATED:format(route.name))
	return route
end

-- Cambiar el nombre de una ruta (sin repetir el de otra)
local function RenameRoute(route, name)
	if not (route and name) or route.quick then return end
	name = UniqueRouteName(name, route)
	if name == route.name then return end
	route.name = name
	Print(L.ROUTE_RENAMED:format(name))
	return true
end

-- Cargar una ruta guardada en la Ruta actual: sus paradas (copias nuevas) sustituyen a
-- las que hubiera (tu cadáver se conserva) y el recorrido empieza por la primera. Lo que
-- luego cambies en la Ruta actual no toca la ruta guardada.
local function LoadRoute(route)
	if not route or route.quick then return end
	local stops = Stops()
	for i = #stops, 1, -1 do
		if not stops[i].corpse then table.remove(stops, i) end
	end
	for _, st in ipairs(route.stops) do
		if not st.corpse then
			local copy = {}
			for k, v in pairs(st) do copy[k] = v end
			copy.id, copy.reached = NewStopId(), nil
			table.insert(stops, copy)
		end
	end
	DB.loadedRoute = route.id
	RebuildRoute() -- AzerothGPS: borra su ruta y recibe esta
	RefreshPins()
	Print(L.ROUTE_LOADED:format(route.name or "?"))
	Fire("ACTIVE_ROUTE_CHANGED", { id = route.id, name = route.name })
end

-- Paradas de la Ruta actual, sin contar tu cadáver (para avisar antes de sustituirlas)
local function CurrentStopCount()
	local n = 0
	for _, st in ipairs(Stops()) do
		if not st.corpse then n = n + 1 end
	end
	return n
end

-- Copia de una ruta con todas sus paradas ("<nombre> (copia)"), sin activar.
-- Las paradas copiadas son nuevas (otro id) y empiezan sin alcanzar; tu cadáver no se copia.
local function DuplicateRoute(route)
	if not route then return end
	local copy = NewRoute(UniqueRouteName(L.ROUTE_COPY_NAME:format(route.name or "?")))
	for _, st in ipairs(route.stops) do
		if not st.corpse then
			local new = {}
			for k, v in pairs(st) do new[k] = v end
			new.id, new.reached = NewStopId(), nil
			table.insert(copy.stops, new)
		end
	end
	Print(L.ROUTE_DUPLICATED:format(copy.name))
	return copy
end

-- Mover una parada a otra ruta (al final de esa ruta). Tu cadáver no se mueve.
-- Si sale de la ruta activa, AzerothGPS la pierde; si entra en la activa, la recibe.
local function MoveStopToRoute(stop, from, to)
	if not (stop and from and to) or from == to or stop.corpse then return end
	local index
	for i, st in ipairs(from.stops) do
		if st == stop then index = i break end
	end
	if not index then return end
	local fromActive, toActive = IsActiveRoute(from), IsActiveRoute(to)
	local public = fromActive and PublicStop(stop)
	table.remove(from.stops, index)
	stop.reached = nil -- en la otra ruta empieza sin alcanzar
	table.insert(to.stops, stop)
	if fromActive then
		RebuildRoute()
		Fire("STOP_REMOVED", public)
	end
	if toActive then
		if stop.line then SendToGPS(stop.line) end
		Fire("STOP_ADDED", PublicStop(stop))
	end
	RefreshPins()
	Print(L.STOP_MOVED_TO:format(stop.name or "?", to.name or "?"))
	return true
end

-- Copiar una parada a otra ruta (al final de esa ruta). La original se queda.
-- La copia es una parada nueva (otro id) y empieza sin alcanzar. Tu cadáver no se copia.
local function CopyStopToRoute(stop, to)
	if not (stop and to) or stop.corpse then return end
	local copy = {}
	for k, v in pairs(stop) do copy[k] = v end
	copy.id, copy.reached = NewStopId(), nil
	table.insert(to.stops, copy)
	if IsActiveRoute(to) then
		if copy.line then SendToGPS(copy.line) end
		Fire("STOP_ADDED", PublicStop(copy))
	end
	RefreshPins()
	Print(L.STOP_COPIED_TO:format(copy.name or "?", to.name or "?"))
	return copy
end

-- ¿Se ha llegado ya a alguna parada de esta ruta?
local function HasReached(route)
	for _, st in ipairs(route.stops) do
		if st.reached then return true end
	end
	return false
end

-- Reiniciar el recorrido: ninguna parada alcanzada. Si es la activa, la brújula vuelve
-- a la primera y AzerothGPS recibe otra vez la ruta entera.
local function RestartRoute(route)
	if not route then return end
	for _, st in ipairs(route.stops) do st.reached = nil end
	if IsActiveRoute(route) then RebuildRoute() end
	RefreshPins()
	Print(L.ROUTE_RESTARTED:format(route.name or "?"))
	return true
end

-- Borrar una ruta guardada con sus paradas (la Ruta actual no se borra).
local function DeleteRoute(route)
	if not route or route.quick then return end
	if DB.loadedRoute == route.id then DB.loadedRoute = nil end
	local list = route.shared and SharedDB and SharedDB.routes or DB.routes
	for i, other in ipairs(list) do
		if other == route then table.remove(list, i) break end
	end
	RefreshPins()
	Print(L.ROUTE_DELETED:format(route.name or "?"))
	return true
end

-- Enlace de mapa de Blizzard para una parada (lo que se ve como "Punto del mapa" en el chat)
local function StopLink(s)
	if not (C_Map.SetUserWaypoint and C_Map.GetUserWaypointHyperlink and UiMapPoint) then return end
	local previous = C_Map.HasUserWaypoint and C_Map.HasUserWaypoint() and C_Map.GetUserWaypoint()
	local ok = pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(s.mapID, s.x, s.y))
	local link = ok and C_Map.GetUserWaypointHyperlink()
	-- Devolvemos el pin de Blizzard a como estaba
	if previous then pcall(C_Map.SetUserWaypoint, previous) else pcall(C_Map.ClearUserWaypoint) end
	return link
end

local function ShareStop(s, channel)
	local where = string.format("(%s %.1f, %.1f)", s.zone or "?", s.x * 100, s.y * 100)
	local link = StopLink(s)
	local msg = link and (link .. " " .. s.name .. " " .. where) or (s.name .. " " .. where)
	if not pcall(SendChatMessage, msg, channel) and channel == "INSTANCE_CHAT" then
		channel = "BATTLEGROUND"
		pcall(SendChatMessage, msg, channel)
	end
	-- Quien tenga Bridge la recibe además como parada (con la pregunta de si la quiere)
	if C_ChatInfo and C_ChatInfo.SendAddonMessage then
		local payload = string.format("1\t%d\t%.4f\t%.4f\t%s", s.mapID, s.x, s.y, ((s.name or ""):gsub("\t", " ")))
		pcall(C_ChatInfo.SendAddonMessage, "Bridge", payload:sub(1, 250), channel)
	end
	Print(L.STOP_SHARED:format(s.name))
end

---------------------------------------------------------------------------
-- Copiar los /way que no manda Bridge (escritos a mano, macros, otros addons)
---------------------------------------------------------------------------

local hookedWay = {}

local zoneLookup
local function LookupZone(name)
	if not zoneLookup then
		-- Índice nombre -> mapa, construido una sola vez. Preferimos zonas sobre otros tipos.
		zoneLookup = {}
		local zoneType = Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3
		for id = 1, 5000 do
			local info = C_Map.GetMapInfo(id)
			if info and info.name and info.name ~= "" then
				local key = info.name:lower()
				local prev = zoneLookup[key]
				if not prev or (info.mapType == zoneType and prev.mapType ~= zoneType) then
					zoneLookup[key] = { mapID = id, mapType = info.mapType }
				end
			end
		end
	end
	local hit = zoneLookup[name:lower()]
	return hit and hit.mapID
end

-- "/way [zona] x y [texto]", también "#mapID x y" y "x,y"
local function ParseWay(msg)
	local tokens = {}
	for t in msg:gsub(",", " "):gmatch("%S+") do table.insert(tokens, t) end
	for i = 1, #tokens - 1 do
		local x, y = tonumber(tokens[i]), tonumber(tokens[i + 1])
		if x and y then
			local zone = table.concat(tokens, " ", 1, i - 1)
			local text = table.concat(tokens, " ", i + 2)
			local mapID
			if zone == "" then
				mapID = C_Map.GetBestMapForUnit("player")
			elseif zone:match("^#%d+$") then
				mapID = tonumber(zone:sub(2))
			else
				mapID = LookupZone(zone)
			end
			if mapID and x >= 0 and x <= 100 and y >= 0 and y <= 100 then
				return mapID, x / 100, y / 100, (text ~= "" and text or nil)
			end
			return
		end
	end
end

-- Devuelve la parada nueva, true si no había nada que añadir (ya existía o era
-- "reset all") o false si la línea no se entiende.
local function OnExternalWay(msg)
	if sendingOurs or not DB or type(msg) ~= "string" then return true end
	local lower = msg:lower():match("^%s*(.-)%s*$")
	-- Como en TomTom: /way reset all, /way reset <zona>, /way reset not <zona>
	local resetArg = lower:match("^reset%s*(.*)$")
	if resetArg then
		if resetArg == "all" then
			ClearStops()
			return true
		end
		local negate, zoneName = false, resetArg
		if resetArg:match("^not%s+") then negate, zoneName = true, resetArg:gsub("^not%s+", "") end
		local zoneID = zoneName ~= "" and LookupZone(zoneName)
		if not zoneID then
			Print(L.WAY_RESET_USAGE)
			return true
		end
		RemoveStopsWhere(function(st)
			local inZone = st.mapID == zoneID or (st.zone or ""):lower() == zoneName
			if negate then return not inZone end
			return inZone
		end)
		return true
	end
	local mapID, x, y, text = ParseWay(msg)
	if not mapID then return false end
	for _, s in ipairs(Stops()) do
		if s.mapID == mapID and math.abs(s.x - x) < 0.002 and math.abs(s.y - y) < 0.002 then return true end
	end
	local info = C_Map.GetMapInfo(mapID)
	local zoneName = info and info.name or "?"
	text = text or zoneName
	local cont, wx, wy = ToWorld(mapID, x, y)
	local stop = {
		id = NewStopId(), name = text, zone = zoneName, mapID = mapID, x = x, y = y, cont = cont, wx = wx, wy = wy,
		line = string.format("/way %s %.1f %.1f %s", zoneName, x * 100, y * 100, text), source = "/way",
	}
	table.insert(Stops(), stop)
	RefreshPins()
	Fire("STOP_ADDED", PublicStop(stop))
	if DB.debug then Print(L.DEBUG_EXTERNAL:format(text)) end
	return stop
end

-- Lo que escribes en el chat: AzerothGPS lo lee ahí, así que Bridge también.
local pendingChatLine = {}
local function HookChatBoxes()
	for i = 1, (NUM_CHAT_WINDOWS or 10) do
		local eb = _G["ChatFrame" .. i .. "EditBox"]
		if eb and not eb.bridgeHooked then
			eb.bridgeHooked = true
			eb:HookScript("OnTextChanged", function(self)
				local t = self:GetText()
				if t and t ~= "" then pendingChatLine[self] = t end
			end)
			eb:HookScript("OnEscapePressed", function(self) pendingChatLine[self] = nil end)
			eb:HookScript("OnEnterPressed", function(self)
				local t = pendingChatLine[self]
				pendingChatLine[self] = nil
				if not t or sendingOurs then return end
				local wayArgs = t:match("^%s*/[wW][aA][yY]%s+(.*)$")
				if wayArgs then
					OnExternalWay(wayArgs)
				elseif t:lower():match("^%s*/agps%s+clear%s*$") then
					-- Borraste la ruta de AzerothGPS a mano: Bridge también la borra
					wipe(Stops())
					RefreshPins()
					Fire("STOPS_CLEARED")
				end
			end)
		end
	end
end

local function HookWayCommands()
	local hookedAny = false
	for _, h in ipairs(HandlersFor("/way")) do
		if not hookedWay[h.key] then
			hookedWay[h.key] = true
			hooksecurefunc(SlashCmdList, h.key, function(msg) OnExternalWay(msg) end)
			hookedAny = true
		end
	end
	-- El chat guarda una copia de cada comando; la borramos para que use la versión enganchada
	if hookedAny and hash_SlashCmdList then
		hash_SlashCmdList["/WAY"] = nil
	end
end

-- ¿Es una de las cajas de escribir del chat?
local function IsChatEditBox(eb)
	if not eb then return false end
	for i = 1, (NUM_CHAT_WINDOWS or 10) do
		if eb == _G["ChatFrame" .. i .. "EditBox"] then return true end
	end
	return false
end

-- /way de Bridge: solo se registra si ningún otro addon tiene /way. Así el juego
-- no responde "comando desconocido" y la parada se añade aunque no haya AzerothGPS.
local function BridgeWayCommand(msg, editBox)
	if sendingOurs then return end -- un /way que Bridge escribe para AzerothGPS
	local result = OnExternalWay(msg)
	if result == false then
		Print(L.WAY_USAGE)
		return
	end
	-- AzerothGPS lee lo que se escribe en el chat. Si el /way llega por otro sitio
	-- (una macro, otro addon), no lo ha visto: se lo mandamos nosotros.
	if type(result) == "table" then
		-- Sin AzerothGPS nadie más avisa: lo hacemos nosotros
		if not HasGPS() then
			Print(string.format("%s: |cffffd100%s|r (%s %.1f, %.1f)",
				L.STOP_ADDED, result.name, result.zone, result.x * 100, result.y * 100))
		elseif not IsChatEditBox(editBox) then
			SendToGPS(result.line)
		end
	end
end

-- Con AzerothGPS cargado no hace falta: él ya se queda con los /way que escribes
-- (y contesta a los que están mal), y Bridge recoge la parada leyendo el chat.
local wayRegistered = false
local wayStatus -- por qué no se registró (para /bridge diag)
local function RegisterWayCommand()
	if wayRegistered then return end
	if HasGPS() then wayStatus = "agps" return end
	if SlashExists("/way") then wayStatus = "other" return end
	SLASH_BRIDGEWAY1 = "/way"
	SlashCmdList.BRIDGEWAY = BridgeWayCommand
	-- El chat guarda una copia de los comandos: que vuelva a mirar
	if hash_SlashCmdList then hash_SlashCmdList["/WAY"] = nil end
	wayRegistered = true
end

---------------------------------------------------------------------------
-- Importar una lista de /way pegada (de una guía, una web, otro jugador)
---------------------------------------------------------------------------

-- ¿Ya hay una parada en ese sitio? (mismo criterio que /way)
local function StopExistsAt(mapID, x, y, route)
	for _, s in ipairs(StopsOf(route)) do
		if s.mapID == mapID and math.abs(s.x - x) < 0.002 and math.abs(s.y - y) < 0.002 then return true end
	end
	return false
end

-- Cada línea con coordenadas se convierte en una parada, en orden. Vale con o sin
-- "/way" delante (y "/tway" de TomTom); las líneas vacías no cuentan.
-- route: la ruta donde se importa (sin ruta, la activa)
local function ImportWayLines(text, clearFirst, route)
	local added, repeated, bad = 0, 0, 0
	if clearFirst then ClearStops(true, route) end
	for raw in (text or ""):gmatch("[^\r\n]+") do
		local line = raw:match("^%s*(.-)%s*$")
		if line ~= "" then
			local lower = line:lower()
			local args = line
			if lower:match("^/t?way%s") then
				args = line:gsub("^%S+%s+", "")
			elseif lower:match("^/") then
				args = nil -- otro comando: no es una parada
			end
			-- "/way reset ..." no se aplica al importar
			local mapID, x, y, name
			if args and not args:lower():match("^reset") then
				mapID, x, y, name = ParseWay(args)
			end
			if not mapID then
				bad = bad + 1
			elseif StopExistsAt(mapID, x, y, route) then
				repeated = repeated + 1
			elseif AddStop(mapID, x, y, name, false, false, { source = "import", silent = true, route = route }) then
				added = added + 1
			else
				bad = bad + 1
			end
		end
	end
	local parts = { L.IMPORT_ADDED:format(added) }
	if repeated > 0 then table.insert(parts, L.IMPORT_REPEATED:format(repeated)) end
	if bad > 0 then table.insert(parts, L.IMPORT_BAD:format(bad)) end
	Print(table.concat(parts, ", ") .. ".")
	return added
end

local importFrame
-- route: la ruta donde se importa (sin ruta, la activa)
local function ShowImport(route)
	if not importFrame then
		local f = CreateFrame("Frame", "BridgeImportFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
		f:SetSize(560, 380)
		f:SetPoint("CENTER")
		f:SetFrameStrata("FULLSCREEN_DIALOG")
		f:SetToplevel(true)
		f:SetClampedToScreen(true)
		if f.SetBackdrop then
			f:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
				tile = true, tileSize = 32, edgeSize = 32,
				insets = { left = 11, right = 12, top = 12, bottom = 11 },
			})
		end
		local bg = f:CreateTexture(nil, "BACKGROUND", nil, -1)
		bg:SetPoint("TOPLEFT", 11, -12)
		bg:SetPoint("BOTTOMRIGHT", -12, 11)
		bg:SetColorTexture(0.06, 0.06, 0.07, 0.97)
		f:EnableMouse(true)
		f:SetMovable(true)
		f:RegisterForDrag("LeftButton")
		f:SetScript("OnDragStart", f.StartMoving)
		f:SetScript("OnDragStop", f.StopMovingOrSizing)
		table.insert(UISpecialFrames, "BridgeImportFrame") -- Esc la cierra

		local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		title:SetPoint("TOP", 0, -18)
		f.Title = title
		local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", -6, -6)

		local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		hint:SetPoint("TOPLEFT", 24, -42)
		hint:SetPoint("RIGHT", -24, 0)
		hint:SetJustifyH("LEFT")
		hint:SetText(L.IMPORT_HINT)

		-- Cuadro de texto de varias líneas, con fondo para que se vea dónde pegar
		local box = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
		box:SetPoint("TOPLEFT", 20, -62)
		box:SetPoint("BOTTOMRIGHT", -20, 74)
		if box.SetBackdrop then
			box:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true, tileSize = 16, edgeSize = 14,
				insets = { left = 3, right = 3, top = 3, bottom = 3 },
			})
			box:SetBackdropColor(0, 0, 0, 0.8)
		end
		local sf = CreateFrame("ScrollFrame", "BridgeImportScroll", box, "UIPanelScrollFrameTemplate")
		sf:SetPoint("TOPLEFT", 8, -8)
		sf:SetPoint("BOTTOMRIGHT", -28, 8)
		local eb = CreateFrame("EditBox", nil, sf)
		eb:SetMultiLine(true)
		eb:SetAutoFocus(false)
		eb:SetFontObject(ChatFontNormal)
		eb:SetWidth(470)
		eb:SetScript("OnEscapePressed", function() f:Hide() end)
		sf:SetScrollChild(eb)
		-- Clic en cualquier parte del cuadro: a escribir
		box:EnableMouse(true)
		box:SetScript("OnMouseDown", function() eb:SetFocus() end)
		f.Edit = eb

		local check = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
		check:SetSize(24, 24)
		check:SetPoint("BOTTOMLEFT", 20, 44)
		local checkText = check.Text or check.text or check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		checkText:ClearAllPoints()
		checkText:SetPoint("LEFT", check, "RIGHT", 2, 0)
		checkText:SetText(L.IMPORT_CLEAR_FIRST)
		f.Clear = check

		local cancel = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		cancel:SetSize(110, 24)
		cancel:SetPoint("BOTTOMRIGHT", -20, 18)
		cancel:SetText(CANCEL or "Cancel")
		cancel:SetScript("OnClick", function() f:Hide() end)

		local import = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		import:SetSize(110, 24)
		import:SetPoint("RIGHT", cancel, "LEFT", -8, 0)
		import:SetText(L.IMPORT_BUTTON)
		import:SetScript("OnClick", function()
			ImportWayLines(eb:GetText(), check:GetChecked(), f.route)
			f:Hide()
		end)

		f:SetScript("OnShow", function()
			eb:SetText("")
			check:SetChecked(false)
			eb:SetFocus()
		end)
		-- Las ventanas nuevas nacen visibles: la dejamos oculta hasta que se abra
		f:Hide()
		importFrame = f
	end
	-- El título dice en qué ruta se importa
	importFrame.route = route
	importFrame.Title:SetText(L.IMPORT_TITLE_ROUTE:format((route or ActiveRoute()).name or "?"))
	importFrame:Show()
end

-- Mueve una parada a otro punto y rehace la ruta de AzerothGPS
local function MoveStop(index, mapID, x, y)
	local s = Stops()[index]
	if not s then return end
	local zMap, zx, zy, zoneName = ToZone(mapID, x, y)
	if not zMap then
		Print(L.DROP_IN_ZONE)
		RefreshPins()
		return
	end
	local cont, wx, wy = ToWorld(zMap, zx, zy)
	s.zone, s.mapID, s.x, s.y, s.cont, s.wx, s.wy = zoneName, zMap, zx, zy, cont, wx, wy
	s.line = string.format("/way %s %.1f %.1f %s", zoneName, zx * 100, zy * 100, s.name)
	RebuildRoute()
	RefreshPins()
	Print(string.format("%s: |cffffd100%s|r (%s %.1f, %.1f)", L.STOP_MOVED, s.name, zoneName, zx * 100, zy * 100))
	Fire("STOP_CHANGED", PublicStop(s))
	return true
end

---------------------------------------------------------------------------
-- Questie: "Establecer ruta" en el menú del rastreador de misiones
---------------------------------------------------------------------------

local function HookQuestie()
	if type(QuestieLoader) ~= "table" or type(QuestieLoader.ImportModule) ~= "function" then return end
	local function Import(name)
		local ok, mod = pcall(QuestieLoader.ImportModule, QuestieLoader, name)
		if ok and type(mod) == "table" then return mod end
	end
	local TrackerMenu = Import("TrackerMenu")
	local DistanceUtils = Import("DistanceUtils")
	local ZoneDB = Import("ZoneDB")
	local Eligibility = Import("TrackerMapEligibility")
	if not (TrackerMenu and DistanceUtils and ZoneDB) then
		Print(L.QUESTIE_LINK_FAILED)
		return
	end

	-- Dos opciones: "Establecer ruta" deja el objetivo como única parada (borra la ruta);
	-- "Añadir como parada" lo suma a la ruta actual.
	local OPTIONS = {
		{ label = L.QUESTIE_SET_ROUTE, exclusive = true },
		{ label = L.QUESTIE_ADD_STOP, exclusive = false },
	}

	-- Questie da la zona como areaId y las coordenadas en 0-100
	local function GoTo(name, zone, x, y, exclusive)
		local ok, uiMapId = pcall(ZoneDB.GetUiMapIdByAreaId, ZoneDB, zone)
		if not ok or not uiMapId then
			Print(L.NO_MAP_FOR_TARGET)
			return
		end
		AddStop(uiMapId, x / 100, y / 100, name, exclusive, false, { source = "Questie" })
	end

	-- Misión entera: el objetivo más cercano
	local function QuestTarget(quest)
		local q = quest
		if Eligibility and Eligibility.RefreshAndGetCapabilities then
			local caps
			q, caps = Eligibility.RefreshAndGetCapabilities(quest.Id, quest.enrichment)
			if not (q and caps and caps.canNavigateQuest) then
				Print(L.QUEST_NO_TARGET)
				return
			end
		end
		local spawn, zone, name = DistanceUtils.GetNearestSpawnForQuest(q)
		if not spawn then
			Print(L.QUEST_NO_POINT)
			return
		end
		return name, zone, spawn[1], spawn[2]
	end

	if type(TrackerMenu.GetMenuForQuest) == "function" then
		local original = TrackerMenu.GetMenuForQuest
		TrackerMenu.GetMenuForQuest = function(self, quest, ...)
			local menu = original(self, quest, ...)
			pcall(function()
				if type(menu) ~= "table" or type(quest) ~= "table" then return end
				if Eligibility and Eligibility.GetCapabilities then
					local caps = Eligibility.GetCapabilities(quest)
					if caps and not caps.canNavigateQuest then return end
				end
				-- Tras el título y "Objetivos", una debajo de la otra
				local pos = math.min(3, #menu + 1)
				for k, opt in ipairs(OPTIONS) do
					table.insert(menu, pos + k - 1, {
						text = opt.label,
						notCheckable = true,
						func = function()
							local name, zone, x, y = QuestTarget(quest)
							if name or zone then GoTo(name, zone, x, y, opt.exclusive) end
						end,
					})
				end
			end)
			return menu
		end
	end

	-- Si "TomTom" es la imitación de Bridge, Questie pondría también su opción
	-- "Establecer objetivo de TomTom". Bridge ya tiene las suyas: esa se omite.
	for _, fname in ipairs({ "addTomTomOptionForQuest", "addTomTomOptionForObjective" }) do
		local original = TrackerMenu[fname]
		if type(original) == "function" then
			TrackerMenu[fname] = function(...)
				if type(TomTom) == "table" and TomTom.isBridge then return end
				return original(...)
			end
		end
	end

	-- Cada objetivo del submenú "Objetivos"
	if type(TrackerMenu.addShowObjectivesOnMapOption) == "function" then
		local original = TrackerMenu.addShowObjectivesOnMapOption
		TrackerMenu.addShowObjectivesOnMapOption = function(objectiveMenu, quest, objective, ...)
			if type(objectiveMenu) == "table" and type(objective) == "table" then
				for _, opt in ipairs(OPTIONS) do
					table.insert(objectiveMenu, {
						text = opt.label,
						notCheckable = true,
						func = function()
							local ok, spawn, zone, name = pcall(DistanceUtils.GetNearestObjective, objective.spawnList)
							if ok and spawn then
								GoTo(name, zone, spawn[1], spawn[2], opt.exclusive)
							else
								Print(L.OBJECTIVE_NO_POINT)
							end
						end,
					})
				end
			end
			return original(objectiveMenu, quest, objective, ...)
		end
	end
end

---------------------------------------------------------------------------
-- Marcadores en el mapa del mundo
---------------------------------------------------------------------------

local OpenStopMenu -- se define más abajo, junto al resto de menús

BridgePinMixin = CreateFromMixins(MapCanvasPinMixin)

function BridgePinMixin:OnLoad()
	self.isBridgePin = true
	-- Número blanco con contorno negro: se lee sobre el verde y sobre cualquier fondo
	self.Label:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
	-- El marco (28x28) está centrado en la punta; el dibujo sube por encima.
	-- Solo responde la cabeza del pin (5 a 21 puntos por encima de la punta): la punta
	-- deja libre el icono que haya debajo (p. ej. el "!" de Questie) para su tooltip.
	self:SetHitRectInsets(6, 6, -7, 19)
	self.Label:SetTextColor(1, 1, 1)
	self.Label:SetShadowOffset(1, -1)
	self.Label:SetShadowColor(0, 0, 0, 1)
	self:UpdatePassThrough()
end

-- Sin Alt, los clics atraviesan el marcador: el mapa y Leatrix funcionan igual.
-- Con Alt pulsado, el marcador recibe el clic izquierdo: clic = quitar, arrastrar = mover.
-- Todo lo de Bridge va con Alt: Alt+clic quita, Alt+arrastrar mueve, Alt+clic derecho
-- abre el menú. Sin Alt, los dos botones atraviesan el pin: el mapa y Leatrix (ir
-- atrás, cambiar de zona…) funcionan igual que si el pin no estuviera.
function BridgePinMixin:UpdatePassThrough()
	if not self.SetPassThroughButtons then return end
	if IsAltKeyDown() or self.pressing then
		pcall(self.SetPassThroughButtons, self) -- recibe los dos botones
	else
		pcall(self.SetPassThroughButtons, self, "LeftButton", "RightButton")
	end
end

-- Tamaño del marcador: igual en pantalla al hacer zoom, pero proporcional al tamaño
-- del mapa. En el mapa del mundo mide ~22 px; en mapas más pequeños, menos.
local REFERENCE_WIDTH = 600
function BridgePinMixin:ApplyCurrentScale()
	local map = self:GetMap()
	if not map then return end
	local canvasScale = (map.GetCanvasScale and map:GetCanvasScale()) or 1
	if not canvasScale or canvasScale <= 0 then canvasScale = 1 end
	local view = map.ScrollContainer or map
	local width = view:GetWidth() or REFERENCE_WIDTH
	local factor = math.min(1, math.max(0.4, width / REFERENCE_WIDTH))
	self:SetScale(factor * (DB and DB.pinScale or 1) / canvasScale)
	self:ApplyCurrentPosition()
	self:ApplyFrameLevel()
end

-- Por encima del resto de iconos del mapa
function BridgePinMixin:ApplyFrameLevel()
	local parent = self:GetParent()
	local base = parent and parent:GetFrameLevel() or 0
	-- Por encima de cualquier otra capa del mapa (algunas cubren el mapa entero)
	self:SetFrameLevel(math.min(math.max(base + 1500, 9000) + (self.index or 0), 9990))
end

function BridgePinMixin:OnAcquired(stop, index, x, y)
	self.stop = stop
	self.index = index
	ApplyLook(self.Icon, self.Label, stop, index, 28)
	self:SetPosition(x, y)
	self:ApplyCurrentScale()
	self:ApplyFrameLevel()
	self:UpdatePassThrough()
end

function BridgePinMixin:OnReleased()
	self:StopTooltipTicker()
	self:SetHighlighted(false)
	self.pressing, self.dragging = nil, nil
	self:SetScript("OnUpdate", nil)
	if MapCanvasPinMixin.OnReleased then MapCanvasPinMixin.OnReleased(self) end
end

function BridgePinMixin:OnMouseDown(button)
	if button ~= "LeftButton" or not IsAltKeyDown() then return end
	self.pressing = true
	self.dragging = false
	self.startX, self.startY = GetCursorPosition()
	self:SetScript("OnUpdate", self.OnDragUpdate)
end

function BridgePinMixin:OnDragUpdate()
	local cx, cy = GetCursorPosition()
	if not self.dragging then
		local scale = UIParent:GetEffectiveScale()
		if math.abs(cx - self.startX) + math.abs(cy - self.startY) < 6 * scale then return end
		self.dragging = true
		self:StopTooltipTicker()
		GameTooltip:Hide()
		self:SetAlpha(0.7)
	end
	local nx, ny = self:GetMap():GetNormalizedCursorPosition()
	if nx then
		self.dragX = math.min(math.max(nx, 0), 1)
		self.dragY = math.min(math.max(ny, 0), 1)
		self:SetPosition(self.dragX, self.dragY)
	end
end

function BridgePinMixin:OnMouseUp(button)
	if button == "RightButton" then
		if self.index and not self.pressing then
			GameTooltip:Hide()
			OpenStopMenu(self)
		end
		return
	end
	if button ~= "LeftButton" or not self.pressing then return end
	self:SetScript("OnUpdate", nil)
	self:SetAlpha(1)
	local wasDragging, index = self.dragging, self.index
	self.pressing, self.dragging = nil, nil
	if wasDragging and self.dragX then
		MoveStop(index, self:GetMap():GetMapID(), self.dragX, self.dragY)
	else
		RemoveStop(index)
	end
end

-- Unidades: "yd" (imperial) o "m" (métrico). Por defecto, métrico salvo en el cliente en inglés de EE. UU.
local function Units()
	if DB and DB.units then return DB.units end
	return GetLocale() == "enUS" and "yd" or "m"
end

-- El juego mide en yardas; si se usan metros, se convierte (1 yd = 0,9144 m)
local function FormatDistance(yards)
	if Units() == "m" then
		local m = yards * 0.9144
		if m >= 1000 then return string.format("%.1f km", m / 1000) end
		return string.format("%d m", math.floor(m + 0.5))
	end
	if yards >= 1000 then return string.format("%.1fk yd", yards / 1000) end
	return string.format("%d yd", math.floor(yards + 0.5))
end

-- Distancia en yardas desde el jugador (nil si no se puede saber: otro continente, mazmorra...)
local function DistanceTo(stop)
	if not (stop.cont and stop.wx and UnitPosition) then return end
	-- UnitPosition da las coordenadas de mundo en el mismo orden que C_Map (x, y) y el continente
	local px, py, _, instance = UnitPosition("player")
	if not px or instance ~= stop.cont then return end
	local dx, dy = px - stop.wx, py - stop.wy
	return math.sqrt(dx * dx + dy * dy)
end

function BridgePinMixin:FillTooltip()
	local stop = self.stop
	if not stop then return end
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(stop.name or "?", 1, 0.82, 0)
	if stop.desc then GameTooltip:AddLine(stop.desc, 0.9, 0.9, 0.9, true) end
	if stop.reached then GameTooltip:AddLine(L.REACHED_TIP, 0.6, 0.6, 0.6) end
	local d = DistanceTo(stop)
	if d then
		GameTooltip:AddLine(FormatDistance(d), 1, 1, 1)
	else
		GameTooltip:AddLine(L.UNKNOWN_DISTANCE, 1, 1, 1)
	end
	GameTooltip:AddLine(string.format("%s (%.2f, %.2f)", stop.zone or "?", (stop.x or 0) * 100, (stop.y or 0) * 100), 0.7, 0.7, 0.7)
	GameTooltip:Show()
end

function BridgePinMixin:StopTooltipTicker()
	if self.tooltipTicker then
		self.tooltipTicker:Cancel()
		self.tooltipTicker = nil
	end
end

function BridgePinMixin:SetHighlighted(on)
	ApplyLook(self.Icon, self.Label, self.stop, self.index, 28, on)
end

function BridgePinMixin:OnMouseEnter()
	if not self.stop then return end
	self:SetHighlighted(true)
	if self.dragging then return end
	self:FillTooltip()
	-- La distancia se actualiza mientras el ratón esté encima
	self:StopTooltipTicker()
	self.tooltipTicker = C_Timer.NewTicker(0.2, function()
		if self.dragging or not self:IsMouseOver(7, 19, 6, -6) or GameTooltip:GetOwner() ~= self then
			self:StopTooltipTicker()
			return
		end
		self:FillTooltip()
	end)
end

function BridgePinMixin:OnMouseLeave()
	if not self.dragging then self:SetHighlighted(false) end
	self:StopTooltipTicker()
	GameTooltip:Hide()
end

local ProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin)

-- Los marcadores NO se registran como pines del mapa (AcquirePin): AzerothGPS copia
-- a sus ventanas los pines registrados del mapa del mundo. Son marcos propios puestos
-- sobre el lienzo del mapa, que usan las mismas funciones de posición del mapa.
local activePins = {}   -- [mapa] = { marcadores visibles }
local freePins = {}

local function AcquireBridgePin(map)
	local canvas = map:GetCanvas()
	local pin = table.remove(freePins)
	if pin then
		pin:SetParent(canvas)
	else
		pin = CreateFrame("Frame", nil, canvas, PIN_TEMPLATE)
		pin:SetScript("OnEnter", pin.OnMouseEnter)
		pin:SetScript("OnLeave", pin.OnMouseLeave)
		pin:SetScript("OnMouseDown", pin.OnMouseDown)
		pin:SetScript("OnMouseUp", pin.OnMouseUp)
	end
	pin.owningMap = map
	pin:Show()
	activePins[map] = activePins[map] or {}
	table.insert(activePins[map], pin)
	return pin
end

local function EachBridgePin(map)
	return ipairs(activePins[map] or {})
end

function ProviderMixin:RemoveAllData()
	local map = self:GetMap()
	for _, pin in EachBridgePin(map) do
		pin:OnReleased()
		pin:Hide()
		pin:ClearAllPoints()
		pin.stop, pin.index = nil, nil
		table.insert(freePins, pin)
	end
	activePins[map] = nil
end

function ProviderMixin:RefreshAllData()
	self:RemoveAllData()
	if not DB or not DB.showPins then return end
	local map = self:GetMap()
	-- Solo en el mapa del mundo: en el de zona (Mayús+M) AzerothGPS ya marca las paradas
	if map ~= WorldMapFrame then return end
	local mapID = map:GetMapID()
	if not mapID then return end
	for i, s in ipairs(Stops()) do
		-- Tu cadáver ya lo marca el juego (lápida en el mapa, flecha en el minimapa)
		if s.cont and s.wx and not s.corpse then
			local _, pos = C_Map.GetMapPosFromWorldPos(s.cont, CreateVector2D(s.wx, s.wy), mapID)
			if pos and pos.x >= 0 and pos.x <= 1 and pos.y >= 0 and pos.y <= 1 then
				AcquireBridgePin(map):OnAcquired(s, i, pos.x, pos.y)
			end
		end
	end
end

---------------------------------------------------------------------------
-- Clics en el mapa y en sus iconos
---------------------------------------------------------------------------

local function WantsStop()
	return IsAltKeyDown() or routeMode
end

-- ¿Hay una parada nuestra bajo el ratón (o muy cerca)?
local function StopUnderCursor(map, cx, cy)
	for _, pin in EachBridgePin(map) do
		if pin:IsMouseOver(7, 19, 6, -6) and pin.index then return pin.index end
	end
	-- Sin marcadores (p. ej. ocultos con /bridge marcadores): por distancia, unos 10 píxeles
	local mapID = map:GetMapID()
	local canvas = map.GetCanvas and map:GetCanvas()
	if not (mapID and canvas and cx) then return end
	local scale = (map.GetCanvasScale and map:GetCanvasScale()) or 1
	local w, h = canvas:GetWidth() * scale, canvas:GetHeight() * scale
	for i, s in ipairs(Stops()) do
		if s.cont and s.wx then
			local _, pos = C_Map.GetMapPosFromWorldPos(s.cont, CreateVector2D(s.wx, s.wy), mapID)
			if pos then
				local dx, dy = (pos.x - cx) * w, (pos.y - cy) * h
				if dx * dx + dy * dy < 100 then return i end
			end
		end
	end
end

local function CanvasClick(canvas, button)
	if button ~= "LeftButton" or IsControlKeyDown() or not WantsStop() then
		return false -- Ctrl+clic se deja para el pin de Blizzard
	end
	local x, y = canvas:GetNormalizedCursorPosition()
	local near = StopUnderCursor(canvas, x, y)
	if near then
		RemoveStop(near)
		return true
	end
	AddStop(canvas:GetMapID(), x, y, nil, IsShiftKeyDown(), true)
	return true -- consumimos el clic para que el mapa no cambie de zona
end

-- ¿El marco 'frame' es 'pin' o está dentro de él?
local function IsInside(frame, pin)
	local f, steps = frame, 0
	while f and steps < 10 do
		if f == pin then return true end
		f = f.GetParent and f:GetParent()
		steps = steps + 1
	end
	return false
end

-- Intenta sacar el nombre de cualquier icono del mapa (Blizzard, Leatrix, Questie...)
local function PinName(pin, clicked)
	if GameTooltip:IsShown() then
		local owner = GameTooltip:GetOwner()
		if owner and (owner == clicked or IsInside(owner, pin)) then
			local t = GameTooltipTextLeft1 and GameTooltipTextLeft1:GetText()
			if t and t ~= "" then return Plain(t) end
		end
	end
	for _, obj in ipairs({ clicked, pin }) do
		if obj then
			for _, f in ipairs({ "name", "title", "label", "description" }) do
				local v = obj[f]
				if type(v) == "string" and v ~= "" then return v end
			end
			for _, k in ipairs({ "poiInfo", "areaPoiInfo", "dungeonInfo", "info", "data" }) do
				local t = obj[k]
				if type(t) == "table" and type(t.name) == "string" and t.name ~= "" then return t.name end
			end
		end
	end
end

-- El pin del mapa al que pertenece un marco (él mismo o uno de sus padres)
local function OwningPin(frame)
	local f, steps = frame, 0
	while f and steps < 10 do
		if f.owningMap and f.GetPosition and not f.isBridgePin then return f end
		f = f.GetParent and f:GetParent()
		steps = steps + 1
	end
end

-- Clic en un pin o en un marco dentro de un pin. Questie, por ejemplo, pone cada
-- icono como un marco DENTRO del pin del mapa, y es ese marco el que recibe el clic.
-- Nombre del icono que tienes delante: el tooltip visible, si su dueño está bajo el ratón
local function TooltipNameUnderMouse()
	if not GameTooltip:IsShown() then return end
	local owner = GameTooltip:GetOwner()
	if owner and owner.IsMouseOver and owner:IsMouseOver() then
		local t = GameTooltipTextLeft1 and GameTooltipTextLeft1:GetText()
		if t and t ~= "" then return Plain(t) end
	end
end

local function PinMouseUp(frame, button)
	if button ~= "LeftButton" or IsControlKeyDown() or not WantsStop() then return end
	local pin = OwningPin(frame)
	local map = (pin and pin.owningMap) or WorldMapFrame
	if not (map and map.GetNormalizedCursorPosition and map.GetMapID) then return end
	-- La parada va donde está el ratón (encima del icono). Si el pin tiene una posición
	-- que coincide con el ratón, usamos la del pin para clavarla exacta.
	local cx, cy = map:GetNormalizedCursorPosition()
	if not cx then return end
	-- Si debajo del ratón hay un pin de Bridge, el clic es para quitarlo, no para añadir
	local mine = StopUnderCursor(map, cx, cy)
	if mine then
		RemoveStop(mine)
		return
	end
	local x, y = cx, cy
	if pin and pin.GetPosition then
		local px, py = pin:GetPosition()
		if px and py and math.abs(px - cx) < 0.02 and math.abs(py - cy) < 0.02 then x, y = px, py end
	end
	local name = TooltipNameUnderMouse() or (pin and PinName(pin, frame))
	if DB and DB.debug then
		Print(L.DEBUG_ICON_CLICK:format(tostring(name), x * 100, y * 100))
	end
	AddStop(map:GetMapID(), x, y, name, IsShiftKeyDown(), true)
end

local hookedFrames = setmetatable({}, { __mode = "k" })
-- Solo se escuchan marcos que YA responden a clics. Ponerle un script de ratón a un
-- marco hace que el juego lo active para el ratón: un marco invisible que cubre todo
-- el mapa empezaba a tapar los iconos (tooltips de Questie incluidos).
local function RespondsToClicks(f)
	if f.IsMouseClickEnabled then
		local ok, on = pcall(f.IsMouseClickEnabled, f)
		if ok then return on end
	end
	if f.IsMouseEnabled then
		local ok, on = pcall(f.IsMouseEnabled, f)
		if ok then return on end
	end
	return false
end

local function HookFrame(f)
	if f and not hookedFrames[f] and not f.isBridgePin and f.HookScript and RespondsToClicks(f) then
		hookedFrames[f] = true
		pcall(f.HookScript, f, "OnMouseUp", PinMouseUp)
	end
end

-- Todos los pines activos del mapa. Se recorren las listas de pines directamente
-- (map.pinPools), porque EnumerateAllPins puede no existir en esta versión del juego.
local function ForEachMapPin(map, fn)
	if type(map.pinPools) == "table" then
		for _, pool in pairs(map.pinPools) do
			if pool and pool.EnumerateActive then
				for pin in pool:EnumerateActive() do fn(pin) end
			end
		end
	elseif map.EnumerateAllPins then
		for pin in map:EnumerateAllPins() do fn(pin) end
	end
end

local function HookPins(map)
	ForEachMapPin(map, function(pin)
		if not pin.isBridgePin then
			HookFrame(pin)
			-- Los marcos de dentro (iconos de Questie y otros addons que usan HereBeDragons)
			if pin.icon then HookFrame(pin.icon) end
			if pin.GetChildren then
				for _, child in ipairs({ pin:GetChildren() }) do HookFrame(child) end
			end
		end
	end)
end

local function AttachToMap(map)
	if not map or map.BridgeAttached then return end
	map.BridgeAttached = true

	if map.AddCanvasClickHandler then
		map:AddCanvasClickHandler(CanvasClick, 100)
	elseif map.ScrollContainer then
		map.ScrollContainer:HookScript("OnMouseUp", function(_, button) CanvasClick(map, button) end)
	end

	local provider = CreateFromMixins(ProviderMixin)
	map:AddDataProvider(provider)
	providers[provider] = true

	-- Al abrir el mapa, los iconos ya están puestos: los enganchamos
	map:HookScript("OnShow", function() C_Timer.After(0.2, function() HookPins(map) end) end)

	if map.OnCanvasScaleChanged then
		hooksecurefunc(map, "OnCanvasScaleChanged", function()
			for _, pin in EachBridgePin(map) do pin:ApplyCurrentScale() end
		end)
	end
	if map.OnCanvasSizeChanged then
		hooksecurefunc(map, "OnCanvasSizeChanged", function()
			for _, pin in EachBridgePin(map) do pin:ApplyCurrentPosition() end
		end)
	end

	local pending = false
	hooksecurefunc(map, "AcquirePin", function()
		if pending then return end
		pending = true
		C_Timer.After(0, function() pending = false; HookPins(map) end)
	end)
	HookPins(map)
end

---------------------------------------------------------------------------
-- Botón en el mapa
---------------------------------------------------------------------------

-- Menú desplegable genérico. items: { text=, func=, title=true, disabled=, sub={...} }
-- Usa el sistema de menús moderno si existe; si no, el clásico (UIDropDownMenu).
local dropdown
local openMenu, menuClosedAt = nil, 0

-- ¿Está abierto el menú (o se acaba de cerrar por este mismo clic)?
local function MenuIsOpen()
	if openMenu and openMenu:IsShown() then return true end
	return GetTime() - menuClosedAt < 0.3
end

local function CloseMenu()
	if openMenu and openMenu:IsShown() then
		if openMenu.Close then pcall(openMenu.Close, openMenu) else openMenu:Hide() end
	end
	if CloseDropDownMenus then CloseDropDownMenus() end
end

local function TrackMenu(menu)
	openMenu = menu
	if menu and not menu.bridgeTracked and menu.HookScript then
		menu.bridgeTracked = true
		menu:HookScript("OnHide", function() menuClosedAt = GetTime() end)
	end
end

-- anchor: función que coloca el menú (por defecto, bajo el botón y alineado a la derecha)
-- onTop: true si se abre desde una ventana de Bridge (Gestionar rutas): esas ventanas están
-- en la capa más alta y el menú (y sus submenús) quedaría debajo; se sube a la capa de
-- los tooltips cada vez que el juego monta un nivel del menú.
local function RaiseMenuOf(frame)
	local top = frame
	while top:GetParent() and top:GetParent() ~= UIParent do top = top:GetParent() end
	if top.SetFrameStrata then top:SetFrameStrata("TOOLTIP") end
end

local function ShowMenu(owner, items, anchor, onTop)
	if MenuUtil and MenuUtil.CreateContextMenu then
		local menu = MenuUtil.CreateContextMenu(owner, function(_, root)
			local function build(desc, list)
				for _, it in ipairs(list) do
					if it.separator then
						if desc.CreateDivider then desc:CreateDivider() end
					elseif it.title then
						desc:CreateTitle(it.text)
					elseif it.check then
						desc:CreateCheckbox(it.text, it.checked, it.toggle)
					else
						-- En los submenús, el menú moderno pega el texto al borde: le damos margen
						local b = desc:CreateButton((desc ~= root and "  " or "") .. it.text, it.func)
						if onTop and b.AddInitializer then b:AddInitializer(function(frame) RaiseMenuOf(frame) end) end
						if it.sub then build(b, it.sub) end
						if it.disabled and b.SetEnabled then b:SetEnabled(false) end
					end
				end
			end
			build(root, items)
		end)
		-- El menú moderno se abre junto al ratón; lo ponemos siempre bajo el botón
		if menu and menu.ClearAllPoints then
			menu:ClearAllPoints()
			if anchor then anchor(menu) else menu:SetPoint("TOPRIGHT", owner, "BOTTOMRIGHT", 0, -2) end
		end
		if onTop and menu and menu.SetFrameStrata then menu:SetFrameStrata("TOOLTIP") end
		TrackMenu(menu)
		return
	end
	if not (UIDropDownMenu_Initialize and ToggleDropDownMenu) then return end
	dropdown = dropdown or CreateFrame("Frame", "BridgeDropDown", UIParent, "UIDropDownMenuTemplate")
	UIDropDownMenu_Initialize(dropdown, function(_, level, menuList)
		for _, it in ipairs(menuList or items) do
			if it.separator then
				if UIDropDownMenu_AddSeparator then UIDropDownMenu_AddSeparator(level) end
			else
				local info = UIDropDownMenu_CreateInfo()
				info.text = it.text
				info.notCheckable = true
				if it.title then
					info.isTitle = true
				elseif it.check then
					info.notCheckable = false
					info.isNotRadio = true
					info.keepShownOnClick = true
					info.checked = it.checked()
					info.func = function() it.toggle() end
				else
					info.func = it.func
					info.disabled = it.disabled
					if it.sub then info.hasArrow = true; info.menuList = it.sub end
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end
	end, "MENU")
	-- Siempre bajo el botón, alineado por la derecha
	ToggleDropDownMenu(1, nil, dropdown, owner, owner:GetWidth() - 160, 0)
	if onTop then
		for level = 1, (UIDROPDOWNMENU_MAXLEVELS or 3) do
			local list = _G["DropDownList" .. level]
			if list then list:SetFrameStrata("TOOLTIP") end
		end
	end
	TrackMenu(DropDownList1)
end

OpenStopMenu = function(pin)
	local s = pin.stop
	if not (pin.index and s) then return end
	local inGroup = IsInGroup and IsInGroup()
	local inRaid = IsInRaid and IsInRaid()
	local _, instanceType = IsInInstance()
	local inGuild = IsInGuild and IsInGuild()
	ShowMenu(pin, {
		{ text = s.name, title = true },
		{ text = L.MENU_RENAME, func = function()
			AskName(s.name, function(newName, newDesc)
				-- Por si la lista cambió mientras escribías
				for i, st in ipairs(Stops()) do
					if st == s then RenameStop(i, newName, newDesc, true) return end
				end
			end, s.desc)
		end },
		{ text = L.MENU_SHARE, sub = {
			{ text = L.SHARE_PARTY, disabled = not inGroup, func = function() ShareStop(s, "PARTY") end },
			{ text = L.SHARE_RAID, disabled = not inRaid, func = function() ShareStop(s, "RAID") end },
			{ text = L.SHARE_BATTLEGROUND, disabled = instanceType ~= "pvp", func = function() ShareStop(s, "INSTANCE_CHAT") end },
			{ text = L.SHARE_GUILD, disabled = not inGuild, func = function() ShareStop(s, "GUILD") end },
		} },
		{ text = L.MENU_REMOVE, func = function()
			for i, st in ipairs(Stops()) do
				if st == s then RemoveStop(i) return end
			end
		end },
	}, function(menu) menu:SetPoint("TOPLEFT", pin, "TOPRIGHT", 2, 0) end)
end

---------------------------------------------------------------------------
-- Ventana "Gestionar rutas": a la izquierda las rutas, a la derecha los waypoints de
-- la ruta elegida (filtro, ir a uno en el mapa, editar, quitar, reordenar con ▲▼ o
-- arrastrando, importar). Lo que se hace aquí actúa sobre la ruta elegida.
---------------------------------------------------------------------------

local ROW_HEIGHT = 36 -- dos líneas: nombre, y debajo zona y coordenadas

-- Cambia una parada de posición y rehace la ruta de AzerothGPS en el orden nuevo
local function MoveStopTo(from, to, route)
	local stops = StopsOf(route)
	local n = #stops
	if not stops[from] or to < 1 or to > n or to == from then return end
	local s = table.remove(stops, from)
	table.insert(stops, to, s)
	local active = IsActiveRoute(route)
	if active then RebuildRoute() end
	RefreshPins()
	if active then Fire("STOPS_REORDERED") end
	return true
end

local function IndexOf(stop, route)
	for i, st in ipairs(StopsOf(route)) do
		if st == stop then return i end
	end
end

-- /cway (como en TomTom): la parada más cercana pasa a ser la siguiente
-- (detrás de tu cadáver, si lo hay: eso va siempre primero)
local function CwayCommand()
	local best, bestD
	for i, st in ipairs(Stops()) do
		if not st.corpse and not st.reached then
			local d = DistanceTo(st)
			if d and (not bestD or d < bestD) then best, bestD = i, d end
		end
	end
	if not best then
		Print(L.CWAY_NONE)
		return
	end
	local stop = Stops()[best]
	local target = NextWaypointIndex() or best
	MoveStopTo(best, target)
	Print(L.CWAY_DONE:format(stop.name or "?", FormatDistance(bestD)))
end

local function RegisterCwayCommand()
	if SlashExists("/cway") then return end
	SLASH_BRIDGECWAY1 = "/cway"
	SlashCmdList.BRIDGECWAY = CwayCommand
	if hash_SlashCmdList then hash_SlashCmdList["/CWAY"] = nil end
end

-- El pin de una parada parpadea un momento para encontrarlo en el mapa
local function FlashStop(stop)
	for _, pin in EachBridgePin(WorldMapFrame) do
		if pin.stop == stop then
			local n = 0
			C_Timer.NewTicker(0.15, function(ticker)
				n = n + 1
				pin:SetHighlighted(n % 2 == 1)
				if n >= 8 then ticker:Cancel(); pin:SetHighlighted(false) end
			end, 8)
			return
		end
	end
end

-- Lleva el mapa del mundo hasta una parada y la centra
local function NavigateToStop(stop)
	if not (stop and stop.mapID) then return end
	if not WorldMapFrame:IsShown() then
		if OpenWorldMap then OpenWorldMap(stop.mapID) elseif ToggleWorldMap then ToggleWorldMap() end
	end
	WorldMapFrame:SetMapID(stop.mapID)
	C_Timer.After(0.05, function()
		if WorldMapFrame.ResetZoom then WorldMapFrame:ResetZoom() end
		if WorldMapFrame.PanAndZoomTo then WorldMapFrame:PanAndZoomTo(stop.x, stop.y) end
		C_Timer.After(0.35, function() FlashStop(stop) end)
	end)
end

local function SetButtonEnabled(b, enabled)
	b:SetEnabled(enabled)
	local tex = b:GetNormalTexture()
	if tex then tex:SetDesaturated(not enabled) end
	b:SetAlpha(enabled and 1 or 0.35)
end

local function IconButton(parent, texture, tip, onClick)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(16, 16)
	b:SetNormalTexture(texture)
	b:SetHighlightTexture(texture, "ADD")
	b:SetScript("OnClick", onClick)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(tip)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	return b
end

local function CreateManagerRow(f, slot)
	local row = CreateFrame("Button", nil, f.Content)
	row:SetHeight(ROW_HEIGHT)
	row:SetPoint("TOPLEFT", f.Content, "TOPLEFT", 0, -(slot - 1) * ROW_HEIGHT)
	row:SetPoint("RIGHT", f.Content, "RIGHT", 0, 0)
	row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	row:RegisterForDrag("LeftButton")

	local hl = row:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 1, 1, 0.08)

	-- Coincide con la búsqueda: fondo dorado (y el nombre en amarillo)
	row.Match = row:CreateTexture(nil, "BACKGROUND")
	row.Match:SetAllPoints()
	row.Match:SetColorTexture(1, 0.82, 0, 0.16)
	row.Match:Hide()

	-- Al principio: subir y bajar
	row.Up = IconButton(row, "Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up", L.TIP_UP, function()
		local route = f:Route()
		local i = IndexOf(row.stop, route)
		if i then MoveStopTo(i, i - 1, route) end
	end)
	row.Up:SetPoint("TOPLEFT", 2, -2)
	row.Down = IconButton(row, "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up", L.TIP_DOWN, function()
		local route = f:Route()
		local i = IndexOf(row.stop, route)
		if i then MoveStopTo(i, i + 1, route) end
	end)
	row.Down:SetPoint("TOP", row.Up, "BOTTOM", 0, 0)

	-- Número: el mismo que lleva el pin en el mapa (discreto, en gris)
	row.Num = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	row.Num:SetPoint("LEFT", row, "LEFT", 22, 0)
	row.Num:SetWidth(18)
	row.Num:SetJustifyH("RIGHT")

	-- Al final: renombrar y quitar
	-- Quitar (icono ✕ y menú contextual)
	function row.Remove_()
		local route = f:Route()
		local i = IndexOf(row.stop, route)
		if i then RemoveStop(i, route) end
	end
	row.Remove = IconButton(row, "Interface\\Buttons\\UI-GroupLoot-Pass-Up", L.MENU_REMOVE, row.Remove_)
	row.Remove:SetPoint("RIGHT", -2, 0)
	-- Editar nombre y descripción (icono ✎ y menú contextual)
	function row.Edit()
		local stop, route = row.stop, f:Route()
		AskName(stop.name, function(newName, newDesc)
			local i = IndexOf(stop, route)
			if i then RenameStop(i, newName, newDesc, true, route) end
		end, stop.desc)
	end
	row.Rename = IconButton(row, "Interface\\Buttons\\UI-GuildButton-PublicNote-Up", L.MENU_RENAME, row.Edit)
	row.Rename:SetPoint("RIGHT", row.Remove, "LEFT", -4, 0)

	-- Línea de arriba: nombre (izquierda) y zona con coordenadas (derecha). Debajo: descripción.
	-- Zona y coordenadas a la derecha (antes de los iconos), ocupando lo que necesiten
	row.Zone = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	row.Zone:SetJustifyH("RIGHT")
	row.Zone:SetWordWrap(false)

	-- Nombre a la izquierda, hasta la zona (si no cabe, se corta con "…")
	row.Name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.Name:SetJustifyH("LEFT")
	row.Name:SetWordWrap(false)

	-- Descripción: debajo del nombre, en una línea
	row.Desc = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.Desc:SetPoint("TOPLEFT", row.Name, "BOTTOMLEFT", 0, -3)
	row.Desc:SetPoint("RIGHT", row, "RIGHT", -46, 0)
	row.Desc:SetJustifyH("LEFT")
	row.Desc:SetWordWrap(false)
	row.Desc:SetTextColor(0.75, 0.75, 0.75)

	-- Con descripción: nombre y zona arriba, descripción debajo. Sin ella: centrados en la fila.
	function row:Layout(hasDesc)
		self.Zone:ClearAllPoints()
		self.Name:ClearAllPoints()
		if hasDesc then
			self.Zone:SetPoint("TOPRIGHT", self, "TOPRIGHT", -46, -7)
			self.Name:SetPoint("TOPLEFT", self, "TOPLEFT", 48, -4)
		else
			self.Zone:SetPoint("RIGHT", self, "RIGHT", -46, 0)
			self.Name:SetPoint("LEFT", self, "LEFT", 48, 0)
		end
		self.Name:SetPoint("RIGHT", self.Zone, "LEFT", -10, 0)
		self.Desc:SetShown(hasDesc)
	end
	row:Layout(false)

	-- Clic: ir a la parada en el mapa. Clic derecho: menú (mover a otra ruta)
	row:SetScript("OnClick", function(self, mouseButton)
		if self.wasDragged then self.wasDragged = false return end
		if mouseButton == "RightButton" then
			-- Menú contextual: editar, "Mover a ▸" y "Copiar a ▸" con las demás rutas y, separado al final, quitar
			local stop, from, targets, copyTargets = self.stop, f:Route(), {}, {}
			for _, route in ipairs(AllRoutes()) do
				if route ~= from then
					table.insert(targets, { text = route.name or "?", func = function()
						MoveStopToRoute(stop, from, route)
					end })
					table.insert(copyTargets, { text = route.name or "?", func = function()
						CopyStopToRoute(stop, route)
					end })
				end
			end
			ShowMenu(self, {
				{ text = L.MENU_RENAME, func = self.Edit },
				{ text = L.MENU_MOVE_TO, sub = targets, disabled = #targets == 0 or stop.corpse },
				{ text = L.MENU_COPY_TO, sub = copyTargets, disabled = #copyTargets == 0 or stop.corpse },
				{ separator = true },
				{ text = L.MENU_REMOVE, func = self.Remove_ },
			}, function(menu) menu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 40, 4) end, true)
			return
		end
		NavigateToStop(self.stop)
	end)

	-- Arrastrar para reordenar (no mientras se filtra: el orden visible no es el real)
	row:SetScript("OnDragStart", function(self)
		self.wasDragged = true
		f.dragRow = self
		self:SetAlpha(0.5)
		f.DropLine:Show()
		f:SetScript("OnUpdate", f.UpdateDrag)
	end)
	row:SetScript("OnDragStop", function(self)
		f:SetScript("OnUpdate", nil)
		self:SetAlpha(1)
		f.DropLine:Hide()
		f.dragRow = nil
		local dropRoute = f.dropRoute
		f.dropRoute = nil
		for _, r in ipairs(f.routeRows) do r.DropTarget:Hide() end
		if dropRoute then
			f.dropIndex = nil
			-- Con Mayús pulsada al soltar, se copia (la original se queda)
			if IsShiftKeyDown() then
				CopyStopToRoute(self.stop, dropRoute)
			else
				MoveStopToRoute(self.stop, f:Route(), dropRoute)
			end
			return
		end
		local from, target = self.index, f.dropIndex
		f.dropIndex = nil
		if from and target then
			local to = target > from and target - 1 or target
			if to ~= from then MoveStopTo(from, to, f:Route()) end
		end
	end)
	return row
end

-- Fila de la lista de rutas (columna izquierda): icono de la Ruta actual o botón ▶ para
-- cargar una ruta guardada, nombre y número de paradas. Clic en el resto de la fila:
-- elegirla para ver sus paradas.
local ROUTE_ROW_HEIGHT = 22
local ROUTE_GAP = 9 -- separación entre la Ruta actual y las guardadas
local function CreateRouteRow(f, slot)
	local row = CreateFrame("Button", nil, f.RouteContent)
	row:SetHeight(ROUTE_ROW_HEIGHT)
	row:RegisterForClicks("LeftButtonUp")

	row.Selected = row:CreateTexture(nil, "BACKGROUND")
	row.Selected:SetAllPoints()
	row.Selected:SetColorTexture(0.25, 0.45, 0.85, 0.35)
	-- Su nombre coincide con la búsqueda: fondo dorado
	row.Match = row:CreateTexture(nil, "BACKGROUND", nil, 1)
	row.Match:SetAllPoints()
	row.Match:SetColorTexture(1, 0.82, 0, 0.16)
	row.Match:Hide()
	-- Al arrastrar una parada encima: se moverá a esta ruta
	row.DropTarget = row:CreateTexture(nil, "BORDER")
	row.DropTarget:SetAllPoints()
	row.DropTarget:SetColorTexture(0.2, 1, 0.2, 0.3)
	row.DropTarget:Hide()
	local hl = row:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 1, 1, 0.08)

	-- A la izquierda: en la Ruta actual, su icono (la brújula); en las guardadas, el botón ▶
	-- para cargarlas en la Ruta actual (verde: la última cargada; amarillo con el ratón)
	row.Dot = CreateFrame("Button", nil, row)
	row.Dot:SetSize(16, 16)
	row.Dot:SetPoint("LEFT", 2, 0)
	function row.Dot:Paint(hover)
		local route = row.route
		if not route then return end
		if route.quick then
			self:SetNormalTexture("Interface\\AddOns\\Bridge\\Media\\arrow")
			local tex = self:GetNormalTexture()
			tex:SetDesaturated(false)
			tex:SetVertexColor(1, 1, 1)
			tex:SetAlpha(1)
			return
		end
		self:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
		local tex = self:GetNormalTexture()
		tex:SetDesaturated(true)
		if hover then
			tex:SetVertexColor(1, 0.85, 0.1)
			tex:SetAlpha(1)
		elseif DB.loadedRoute == route.id then
			tex:SetVertexColor(0.3, 1, 0.3)
			tex:SetAlpha(1)
		else
			tex:SetVertexColor(1, 1, 1)
			tex:SetAlpha(0.45)
		end
	end
	row.Dot:SetScript("OnClick", function(self)
		local route = row.route
		if not route or route.quick then return end
		local function Load()
			LoadRoute(route)
			f.selectedRouteId = ActiveRoute().id -- para ver lo cargado
			f:Refresh()
		end
		-- Si la Ruta actual tiene paradas, se pregunta antes de sustituirlas
		local n = CurrentStopCount()
		if n == 0 then Load() return end
		local text = n == 1 and L.LOAD_CONFIRM_ONE:format(route.name or "?") or L.LOAD_CONFIRM:format(n, route.name or "?")
		Confirm(text, L.LOAD_YES, Load, self)
	end)
	row.Dot:SetScript("OnEnter", function(self)
		local route = row.route
		if not route then return end
		self:Paint(not route.quick)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if route.quick then
			GameTooltip:SetText(L.CURRENT_ROUTE_TIP, 1, 1, 1, 1, true)
		else
			GameTooltip:SetText(DB.loadedRoute == route.id and L.ROUTE_LOADED_TIP or L.ROUTE_LOAD)
		end
		GameTooltip:Show()
	end)
	row.Dot:SetScript("OnLeave", function(self)
		self:Paint(false)
		GameTooltip:Hide()
	end)

	row.Count = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	row.Count:SetPoint("RIGHT", -4, 0)

	row.Name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.Name:SetPoint("LEFT", 20, 0)
	row.Name:SetPoint("RIGHT", row.Count, "LEFT", -4, 0)
	row.Name:SetJustifyH("LEFT")
	row.Name:SetWordWrap(false)

	row:SetScript("OnClick", function(self)
		f.selectedRouteId = self.route and self.route.id
		f:Refresh()
	end)
	return row
end

local function CreateManager()
	local f = CreateFrame("Frame", "BridgeManagerFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	f:SetSize(720, 440)
	f:SetPoint("CENTER")
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	if f.SetBackdrop then
		f:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 32,
			insets = { left = 11, right = 12, top = 12, bottom = 11 },
		})
	end
	-- Fondo opaco: con el de diálogo normal se transparentaba el mapa
	local bg = f:CreateTexture(nil, "BACKGROUND", nil, -1)
	bg:SetPoint("TOPLEFT", 11, -12)
	bg:SetPoint("BOTTOMRIGHT", -12, 11)
	bg:SetColorTexture(0.06, 0.06, 0.07, 0.97)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	table.insert(UISpecialFrames, "BridgeManagerFrame") -- Esc la cierra

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", 0, -18)
	title:SetText(L.MANAGER_TITLE)
	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -6, -6)

	-- La ruta elegida en la ventana (si ya no existe, la activa)
	function f:Route()
		for _, route in ipairs(AllRoutes()) do
			if route.id == self.selectedRouteId then return route end
		end
		local route = ActiveRoute()
		self.selectedRouteId = route.id
		return route
	end

	-- Columna izquierda: las rutas
	local routesTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	routesTitle:SetPoint("TOPLEFT", 24, -80)
	routesTitle:SetText(L.MANAGER_ROUTES)
	local rsf = CreateFrame("ScrollFrame", "BridgeManagerRouteScroll", f, "UIPanelScrollFrameTemplate")
	rsf:SetPoint("TOPLEFT", 18, -98)
	rsf:SetPoint("BOTTOMLEFT", 18, 74)
	rsf:SetWidth(172)
	local rcontent = CreateFrame("Frame", nil, rsf)
	rcontent:SetSize(172, 1)
	rsf:SetScrollChild(rcontent)
	f.RouteContent = rcontent
	f.RouteScrollBar = rsf.ScrollBar or _G["BridgeManagerRouteScrollScrollBar"]
	f.routeRows = {}
	-- Línea entre la Ruta actual y las rutas guardadas
	f.RouteSeparator = rcontent:CreateTexture(nil, "ARTWORK")
	f.RouteSeparator:SetColorTexture(1, 1, 1, 0.15)
	f.RouteSeparator:SetHeight(1)
	f.RouteSeparator:SetPoint("TOPLEFT", rcontent, "TOPLEFT", 4, -ROUTE_ROW_HEIGHT - ROUTE_GAP / 2)
	f.RouteSeparator:SetPoint("RIGHT", rcontent, "RIGHT", -4, 0)

	-- Bajo la lista de rutas: crear una ruta nueva (queda elegida, no activa)
	local newRoute = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	newRoute:SetSize(184, 22)
	newRoute:SetPoint("BOTTOMLEFT", 20, 46)
	newRoute:SetText(L.ROUTE_NEW)
	newRoute:SetScript("OnClick", function()
		AskName(L.ROUTE_NEW_NAME:format(#AllRoutes()), function(name)
			local route = CreateRoute(name)
			f.selectedRouteId = route.id
			f:Refresh()
		end, nil, { hint = L.ROUTE_NAME_HINT, noDescription = true, anchor = newRoute })
	end)

	local sep = f:CreateTexture(nil, "ARTWORK")
	sep:SetColorTexture(1, 1, 1, 0.08)
	sep:SetWidth(1)
	sep:SetPoint("TOPLEFT", 218, -76)
	sep:SetPoint("BOTTOMLEFT", 218, 42)

	-- Columna derecha: los waypoints de la ruta elegida
	f.RouteName = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.RouteName:SetPoint("TOPLEFT", 230, -79)
	f.RouteName:SetJustifyH("LEFT")
	f.RouteName:SetWordWrap(false)

	-- Junto al nombre: renombrar la ruta (misma cajita, encima del icono)
	f.RenameRoute = IconButton(f, "Interface\\Buttons\\UI-GuildButton-PublicNote-Up", L.ROUTE_RENAME, function(self)
		local route = f:Route()
		AskName(route.name, function(name)
			RenameRoute(route, name)
			f:Refresh()
		end, nil, { hint = L.ROUTE_NAME_HINT, noDescription = true, anchor = self })
	end)
	f.RenameRoute:SetPoint("LEFT", f.RouteName, "RIGHT", 6, 0)

	-- Duplicarla (la copia queda elegida, no activa)
	f.DuplicateRoute = IconButton(f, "Interface\\Buttons\\UI-PlusButton-Up", L.ROUTE_DUPLICATE, function()
		local copy = DuplicateRoute(f:Route())
		if copy then
			f.selectedRouteId = copy.id
			f:Refresh()
		end
	end)
	f.DuplicateRoute:SetPoint("LEFT", f.RenameRoute, "RIGHT", 4, 0)

	-- Reiniciar su recorrido (solo si ya se ha llegado a alguna parada)
	f.RestartRoute = IconButton(f, "Interface\\Buttons\\UI-RefreshButton", L.ROUTE_RESTART, function()
		RestartRoute(f:Route())
		f:Refresh()
	end)
	f.RestartRoute:SetPoint("LEFT", f.DuplicateRoute, "RIGHT", 4, 0)

	-- Y borrarla (con confirmación; nunca la última)
	f.DeleteRoute = IconButton(f, "Interface\\Buttons\\UI-GroupLoot-Pass-Up", L.ROUTE_DELETE, function(self)
		local route = f:Route()
		local n = #route.stops
		local text = n == 0 and L.ROUTE_DELETE_CONFIRM_EMPTY:format(route.name)
			or n == 1 and L.ROUTE_DELETE_CONFIRM_ONE:format(route.name)
			or L.ROUTE_DELETE_CONFIRM:format(route.name, n)
		if route.shared then text = text .. "\n" .. L.ROUTE_DELETE_SHARED end
		Confirm(text, L.ROUTE_DELETE_YES, function()
			if DeleteRoute(route) then
				f.selectedRouteId = nil
				f:Refresh()
			end
		end, self)
	end)
	f.DeleteRoute:SetPoint("LEFT", f.RestartRoute, "RIGHT", 4, 0)

	-- Buscador, arriba y sobre las dos columnas (por ahora filtra los waypoints de la
	-- ruta elegida; buscará también en las rutas)
	local ok, search = pcall(CreateFrame, "EditBox", "BridgeManagerSearch", f, "SearchBoxTemplate")
	if not ok or not search then search = CreateFrame("EditBox", "BridgeManagerSearch", f, "InputBoxTemplate") end
	search:SetSize(360, 20)
	search:SetPoint("TOPLEFT", 28, -44)
	search:SetAutoFocus(false)
	search:HookScript("OnTextChanged", function() f:Refresh() end)
	search:HookScript("OnEscapePressed", function(self) self:ClearFocus() end)
	f.Search = search

	-- A la derecha del buscador: cuántas rutas y paradas coinciden
	f.Summary = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	f.Summary:SetPoint("LEFT", search, "RIGHT", 12, 0)

	local import = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	import:SetSize(150, 22)
	import:SetPoint("TOPRIGHT", -24, -73)
	import:SetText(L.IMPORT_OPEN)
	import:SetScript("OnClick", function() ShowImport(f:Route()) end)
	f.Import = import

	-- Lista de waypoints
	local sf = CreateFrame("ScrollFrame", "BridgeManagerScroll", f, "UIPanelScrollFrameTemplate")
	sf:SetPoint("TOPLEFT", 226, -102)
	sf:SetPoint("BOTTOMRIGHT", -38, 74)

	-- Abajo a la derecha: compartir la ruta guardada con todos tus personajes
	f.Shared = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
	f.Shared:SetSize(24, 24)
	f.Shared:SetPoint("BOTTOMLEFT", 228, 44)
	local sharedText = f.Shared.Text or f.Shared.text or f.Shared:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	sharedText:ClearAllPoints()
	sharedText:SetPoint("LEFT", f.Shared, "RIGHT", 2, 0)
	sharedText:SetText(L.ROUTE_SHARED)
	f.Shared:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(L.ROUTE_SHARED_TIP, 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	f.Shared:SetScript("OnLeave", GameTooltip_Hide)
	f.Shared:SetScript("OnClick", function(self)
		local route = f:Route()
		local function Apply(shared)
			if SetRouteShared(route, shared) then
				f.selectedRouteId = route.id -- cambia de id al cambiar de sitio
				Print((shared and L.ROUTE_SHARED_ON or L.ROUTE_SHARED_OFF):format(route.name or "?"))
			end
			f:Refresh()
		end
		if self:GetChecked() then
			Apply(true)
		else
			-- Dejar de compartir: tus otros personajes dejarán de verla. Se pregunta antes.
			self:SetChecked(true)
			Confirm(L.ROUTE_UNSHARE_CONFIRM:format(route.name or "?"), L.ROUTE_UNSHARE_YES, function() Apply(false) end, self)
		end
	end)
	local content = CreateFrame("Frame", nil, sf)
	content:SetSize(456, 1)
	sf:SetScrollChild(content)
	f.Content = content
	f.ScrollBar = sf.ScrollBar or _G["BridgeManagerScrollScrollBar"]
	f.rows = {}

	f.Empty = f:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	f.Empty:SetPoint("TOPLEFT", sf, "TOPLEFT", 8, -8)
	f.Empty:SetPoint("RIGHT", sf, "RIGHT", -8, 0)
	f.Empty:SetJustifyH("LEFT")

	f.Hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	f.Hint:SetPoint("BOTTOM", 0, 18)

	-- Línea que marca dónde caerá la fila al arrastrar
	f.DropLine = content:CreateTexture(nil, "OVERLAY")
	f.DropLine:SetColorTexture(0.2, 1, 0.2, 0.9)
	f.DropLine:SetHeight(2)
	f.DropLine:Hide()

	function f.UpdateDrag()
		local _, cy = GetCursorPosition()
		cy = cy / content:GetEffectiveScale()
		local slot = math.floor((content:GetTop() - cy) / ROW_HEIGHT + 0.5)
		slot = math.max(0, math.min(slot, #StopsOf(f:Route())))
		f.dropIndex = slot + 1
		f.DropLine:ClearAllPoints()
		f.DropLine:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -slot * ROW_HEIGHT + 1)
		f.DropLine:SetPoint("RIGHT", content, "RIGHT", 0, 0)
		-- ¿Encima de otra ruta de la lista? Entonces se moverá allí (no se reordena)
		local over
		for _, r in ipairs(f.routeRows) do
			local hit = r:IsShown() and r.route ~= f:Route() and r:IsMouseOver()
			r.DropTarget:SetShown(hit)
			-- Verde: se moverá. Azul (con Mayús): se copiará.
			if IsShiftKeyDown() then
				r.DropTarget:SetColorTexture(0.3, 0.6, 1, 0.35)
			else
				r.DropTarget:SetColorTexture(0.2, 1, 0.2, 0.3)
			end
			if hit then over = r.route end
		end
		f.dropRoute = over
		f.DropLine:SetShown(not over)
	end

	-- La barra de desplazamiento solo cuando la lista no cabe
	local function FitScroll(bar, scroll, height)
		if not bar then return end
		local needed = height > (scroll:GetHeight() or 0)
		bar:SetShown(needed)
		if not needed then scroll:SetVerticalScroll(0) end
	end

	-- Búsqueda: en el nombre de las rutas y en las paradas (nombre, descripción y zona)
	local function Matches(text, filter)
		return text and text:lower():find(filter, 1, true) ~= nil
	end
	local function StopMatches(st, filter)
		return Matches(st.name, filter) or Matches(st.desc, filter) or Matches(st.zone, filter)
	end
	local function Count(n, one, many) return (n == 1 and one or many):format(n) end

	-- results: las rutas que se ven, cada una con { route, nameMatch, stopMatches }
	function f:RefreshRoutes(results, selected)
		-- La Ruta actual va la primera y separada de las guardadas por una línea
		local gap = (results[1] and results[1].route.quick and #results > 1) and ROUTE_GAP or 0
		self.RouteSeparator:SetShown(gap > 0)
		for i, res in ipairs(results) do
			local row = self.routeRows[i] or CreateRouteRow(self, i)
			self.routeRows[i] = row
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", rcontent, "TOPLEFT", 0, -(i - 1) * ROUTE_ROW_HEIGHT - (i > 1 and gap or 0))
			row:SetPoint("RIGHT", rcontent, "RIGHT", 0, 0)
			row.route = res.route
			row.Name:SetText(res.route.name or "?")
			if res.nameMatch then
				row.Name:SetTextColor(1, 0.82, 0)
			elseif res.route.shared then
				row.Name:SetTextColor(0.55, 0.8, 1) -- compartida con tus personajes
			else
				row.Name:SetTextColor(1, 1, 1)
			end
			row.Match:SetShown(res.nameMatch)
			-- (5) normalmente; al buscar, (2/5): 2 de sus 5 paradas coinciden (el 2 en amarillo)
			if res.stopMatches > 0 then
				row.Count:SetText(string.format("(|cffffd100%d|r/%d)", res.stopMatches, #res.route.stops))
			else
				row.Count:SetText(string.format("(%d)", #res.route.stops))
			end
			row.Dot:Paint(row.Dot:IsMouseOver())
			row.Selected:SetShown(res.route == selected)
			row:Show()
		end
		for k = #results + 1, #self.routeRows do self.routeRows[k]:Hide() end
		rcontent:SetHeight(math.max(1, #results * ROUTE_ROW_HEIGHT + gap))
		FitScroll(self.RouteScrollBar, rsf, #results * ROUTE_ROW_HEIGHT + gap)
	end

	function f:Refresh()
		local filter = (self.Search:GetText() or ""):lower():match("^%s*(.-)%s*$")
		self.filtering = filter ~= ""
		-- Rutas que se ven: todas, o al buscar, las que coinciden por nombre o por alguna parada
		local results, matchingStops = {}, 0
		for _, route in ipairs(AllRoutes()) do
			local nameMatch, stopMatches = self.filtering and Matches(route.name, filter), 0
			if self.filtering then
				for _, st in ipairs(route.stops) do
					if StopMatches(st, filter) then stopMatches = stopMatches + 1 end
				end
			end
			if not self.filtering or nameMatch or stopMatches > 0 then
				table.insert(results, { route = route, nameMatch = nameMatch and true or false, stopMatches = stopMatches })
				matchingStops = matchingStops + stopMatches
			end
		end
		-- La ruta elegida, si no está entre los resultados, pasa a ser la primera de ellos
		local route = self:Route()
		local inResults = false
		for _, res in ipairs(results) do if res.route == route then inResults = true end end
		if not inResults and results[1] then
			route = results[1].route
			self.selectedRouteId = route.id
		end
		self:RefreshRoutes(results, route)
		self.Summary:SetText(self.filtering
			and (Count(#results, L.SEARCH_ROUTE, L.SEARCH_ROUTES) .. " · " .. Count(matchingStops, L.SEARCH_STOP, L.SEARCH_STOPS))
			or "")
		local stops = (self.filtering and #results == 0) and {} or StopsOf(route)
		-- El nombre ocupa lo que necesita (hasta un máximo), y el icono va justo detrás
		-- Si la búsqueda no encuentra nada, la cabecera queda vacía
		local nothing = self.filtering and #results == 0
		self.RouteName:SetWidth(260)
		self.RouteName:SetText(nothing and "" or (route.name or "?"))
		self.RouteName:SetWidth(math.max(1, math.min(math.ceil(self.RouteName:GetStringWidth()) + 2, 260)))
		-- Iconos junto al nombre: en la Ruta actual, duplicar y reiniciar; en las guardadas,
		-- renombrar, duplicar y borrar. Se colocan seguidos, sin huecos.
		local current = route.quick == true
		self.RenameRoute:SetShown(not nothing and not current)
		self.DuplicateRoute:SetShown(not nothing)
		self.RestartRoute:SetShown(not nothing and current)
		SetButtonEnabled(self.RestartRoute, HasReached(route))
		self.DeleteRoute:SetShown(not nothing and not current)
		local previous
		for _, icon in ipairs({ self.RenameRoute, self.DuplicateRoute, self.RestartRoute, self.DeleteRoute }) do
			if icon:IsShown() then
				icon:ClearAllPoints()
				if previous then
					icon:SetPoint("LEFT", previous, "RIGHT", 4, 0)
				else
					icon:SetPoint("LEFT", self.RouteName, "RIGHT", 6, 0)
				end
				previous = icon
			end
		end
		self.Import:SetShown(not nothing)
		self.Shared:SetShown(not nothing and not current)
		self.Shared:SetChecked(route.shared == true)
		-- Todas las paradas de la ruta, en su orden; las que coinciden, resaltadas
		local shown = 0
		for i, st in ipairs(stops) do
			shown = shown + 1
			local row = self.rows[shown] or CreateManagerRow(self, shown)
			self.rows[shown] = row
			row.index, row.stop = i, st
			row.Num:SetText(i)
			row.Name:SetText(st.name or "?")
			local match = self.filtering and StopMatches(st, filter)
			row.Match:SetShown(match)
			if match then
				row.Name:SetTextColor(1, 0.82, 0)
			elseif st.reached then
				row.Name:SetTextColor(0.5, 0.5, 0.5)
			else
				row.Name:SetTextColor(1, 1, 1)
			end
			row.Desc:SetAlpha(st.reached and 0.6 or 1)
			row.Zone:SetAlpha(st.reached and 0.6 or 1)
			row.Zone:SetText(string.format("%s (%.1f, %.1f)", st.zone or "?", (st.x or 0) * 100, (st.y or 0) * 100))
			row.Desc:SetText(st.desc or "")
			row:Layout(st.desc ~= nil)
			SetButtonEnabled(row.Up, i > 1)
			SetButtonEnabled(row.Down, i < #stops)
			row:Show()
		end
		for k = shown + 1, #self.rows do self.rows[k]:Hide() end
		content:SetHeight(math.max(1, shown * ROW_HEIGHT))
		FitScroll(self.ScrollBar, sf, shown * ROW_HEIGHT)
		if self.filtering and #results == 0 then
			self.Empty:SetText(L.MANAGER_NO_MATCH)
			self.Empty:Show()
		elseif shown == 0 then
			self.Empty:SetText(L.MANAGER_EMPTY)
			self.Empty:Show()
		else
			self.Empty:Hide()
		end
		self.Hint:SetText(L.MANAGER_HINT)
	end

	f:SetScript("OnShow", function(self) self:Refresh() end)
	-- Al cerrar la ventana, también la confirmación que hubiera abierta
	f:SetScript("OnHide", function() if confirmBox then confirmBox:Hide() end end)
	-- Las ventanas nuevas nacen visibles: la dejamos oculta hasta que se abra
	f:Hide()
	return f
end

local function ToggleManager()
	managerFrame = managerFrame or CreateManager()
	managerFrame:SetShown(not managerFrame:IsShown())
end

local button

local function UpdateButton()
	if not button then return end
	if routeMode then
		-- Modo ruta: texto verde, botón iluminado y un brillo verde que late
		button:SetText("|cff33ff33Bridge|r")
		button:LockHighlight()
		button.Glow:Show()
		button.GlowAnim:Play()
	else
		button:SetText("Bridge")
		button:UnlockHighlight()
		button.GlowAnim:Stop()
		button.Glow:Hide()
	end
	button:SetShown(DB.showButton)
end

local function SetRouteMode(on)
	routeMode = on
	UpdateButton()
	Print(on and L.ROUTE_MODE_ON or L.ROUTE_MODE_OFF)
end

-- Busca el botón de filtros de la esquina superior derecha del mapa
local function FindFilterButton(parent)
	local best
	local pr, pt = parent:GetRight(), parent:GetTop()
	if not (pr and pt) then return end
	for _, f in ipairs(WorldMapFrame.overlayFrames or {}) do
		if f ~= button and f.IsShown and f:IsShown() and f.GetRight then
			local r, t = f:GetRight(), f:GetTop()
			if r and t and math.abs(pr - r) < 60 and math.abs(pt - t) < 60 then
				if not best or r > best:GetRight() then best = f end
			end
		end
	end
	return best
end

local function CreateMapButton()
	local parent = WorldMapFrame.ScrollContainer or WorldMapFrame
	button = CreateFrame("Button", "BridgeMapButton", WorldMapFrame, "UIPanelButtonTemplate")
	button:SetSize(76, 22)
	button:SetFrameLevel(parent:GetFrameLevel() + 500)
	button:SetMovable(true)
	button:SetClampedToScreen(true)
	button:RegisterForDrag("LeftButton")
	button:RegisterForClicks("LeftButtonUp")

	-- Brillo verde para el modo ruta
	local glow = button:CreateTexture(nil, "OVERLAY")
	glow:SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
	glow:SetTexCoord(0, 0.625, 0, 0.6875)
	glow:SetBlendMode("ADD")
	glow:SetVertexColor(0.2, 1, 0.2)
	glow:SetAllPoints()
	glow:Hide()
	local anim = glow:CreateAnimationGroup()
	anim:SetLooping("BOUNCE")
	local alpha = anim:CreateAnimation("Alpha")
	alpha:SetFromAlpha(0.25)
	alpha:SetToAlpha(1)
	alpha:SetDuration(0.8)
	button.Glow, button.GlowAnim = glow, anim

	function button:Place()
		self:ClearAllPoints()
		if DB.buttonPos then
			self:SetPoint("TOPLEFT", parent, "TOPLEFT", DB.buttonPos[1], DB.buttonPos[2])
			return
		end
		-- Pegado a la izquierda del botón de filtros; si no lo encuentra, en la esquina
		local filter = FindFilterButton(parent)
		if filter then
			self:SetPoint("RIGHT", filter, "LEFT", -2, 0)
		else
			self:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -38, -6)
		end
	end
	button:SetScript("OnDragStart", function(self)
		if IsShiftKeyDown() then
			self.dragging = true
			self:StartMoving()
		end
	end)
	button:SetScript("OnDragStop", function(self)
		if not self.dragging then return end
		self:StopMovingOrSizing()
		if self.SetUserPlaced then self:SetUserPlaced(false) end
		local s, ps = self:GetEffectiveScale(), parent:GetEffectiveScale()
		DB.buttonPos = {
			math.floor((self:GetLeft() * s - parent:GetLeft() * ps) / s + 0.5),
			math.floor((self:GetTop() * s - parent:GetTop() * ps) / s + 0.5),
		}
		self:Place()
	end)
	button:Place()
	-- Al abrir el mapa los botones de Blizzard ya están colocados: recolocamos
	WorldMapFrame:HookScript("OnShow", function() button:Place() end)

	-- Al pulsar, el juego cierra los menús abiertos antes del clic: lo apuntamos aquí
	button:HookScript("OnMouseDown", function(self) self.menuWasOpen = MenuIsOpen() end)
	button:SetScript("OnClick", function(self)
		if self.dragging then self.dragging = false; return end
		GameTooltip:Hide()
		-- Si el menú estaba abierto, el clic solo lo cierra
		if self.menuWasOpen or MenuIsOpen() then
			self.menuWasOpen = false
			CloseMenu()
			menuClosedAt = 0
			return
		end
		ShowMenu(self, {
			{ text = "Bridge", title = true },
			{ text = routeMode and L.MENU_ROUTE_MODE_OFF or L.MENU_ROUTE_MODE_ON, func = function() SetRouteMode(not routeMode) end },
			{ text = L.MENU_MANAGE, func = function() ToggleManager() end },
			{ text = L.MENU_CLEAR_STOPS, sub = {
				{ text = L.MENU_CLEAR_ZONE, func = function()
					-- Las de la zona que se está viendo en el mapa
					local mapID = WorldMapFrame:GetMapID()
					RemoveStopsWhere(function(st) return st.mapID == mapID end)
				end },
				{ text = L.MENU_CLEAR_ALL, func = function() ClearStops() end },
			} },
			{ text = L.MENU_UNITS, sub = {
				{ text = L.UNITS_YARDS, check = true,
					checked = function() return Units() == "yd" end,
					toggle = function() DB.units = "yd" end },
				{ text = L.UNITS_METERS, check = true,
					checked = function() return Units() == "m" end,
					toggle = function() DB.units = "m" end },
			} },
			{
				text = L.MENU_COMPASS, check = true,
				checked = function() return DB.showCompass end,
				toggle = function() DB.showCompass = not DB.showCompass; UpdateCompassShown() end,
			},
			{
				text = L.MENU_ARRIVAL, check = true,
				checked = function() return DB.arrivalBanner ~= false end,
				toggle = function() DB.arrivalBanner = not (DB.arrivalBanner ~= false) end,
			},
			{
				text = L.MENU_ASK_NAME, check = true,
				checked = function() return DB.askName ~= false end,
				toggle = function() DB.askName = not (DB.askName ~= false) end,
			},
		})
	end)
	button:SetScript("OnEnter", function(self)
		-- Con el menú abierto no hace falta: ocuparía el mismo sitio
		if openMenu and openMenu:IsShown() then return end
		-- Justo debajo del botón, alineado a la derecha (donde se abre el menú)
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		GameTooltip:ClearAllPoints()
		GameTooltip:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -2)
		GameTooltip:SetText("Bridge")
		if routeMode then
			GameTooltip:AddLine(L.ROUTE_MODE_ON, 0.2, 1, 0.2, true)
		end
		GameTooltip:AddLine(L.BUTTON_TIP_CLICK, 1, 1, 1)
		GameTooltip:AddLine(L.BUTTON_TIP_DRAG, 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	WorldMapFrame:HookScript("OnHide", function()
		if routeMode then routeMode = false; UpdateButton() end
	end)
	UpdateButton()
end

---------------------------------------------------------------------------
-- AzerothGPS: quitar la parada al llegar (aviso OnArrive de su API)
---------------------------------------------------------------------------

local AnnounceArrival -- más abajo (brújula)

-- Llegar a la parada 'index' de la ruta activa: queda guardada, marcada como alcanzada
-- (en todas las rutas, también la Rápida). Devuelve la parada.
local function ReachStop(index)
	local st = Stops()[index]
	if not st then return end
	st.reached = true
	Fire("STOP_REACHED", PublicStop(st))
	return st
end

local function HookArrivals()
	local api = AzerothGPS
	if type(api) ~= "table" or (tonumber(api.version) or 0) < 14 or type(api.OnArrive) ~= "function" then return end
	pcall(api.OnArrive, ADDON, function(info)
		if type(info) ~= "table" then return end
		if info.last then
			-- Fin de su ruta: todas las que quedaban se dan por alcanzadas (siguen guardadas).
			-- Tu cadáver no: se quita al resucitar.
			local last
			for i = #Stops(), 1, -1 do
				local st = Stops()[i]
				if not st.reached and not st.corpse then
					last = last or st
					ReachStop(i)
				end
			end
			if last and AnnounceArrival then AnnounceArrival(last, nil) end
		elseif info.x and info.y then
			local best, bestDist
			for i, s in ipairs(Stops()) do
				if s.wx and not s.corpse and not s.reached and (not info.cont or s.cont == info.cont) then
					local d = (s.wx - info.x) ^ 2 + (s.wy - info.y) ^ 2
					if not bestDist or d < bestDist then best, bestDist = i, d end
				end
			end
			if best and bestDist < 60 * 60 then
				local reached = ReachStop(best)
				local _, nextStop = NextStopIndex()
				if AnnounceArrival then AnnounceArrival(reached, nextStop) end
			end
		end
		RefreshPins()
	end)
end


---------------------------------------------------------------------------
-- Brújula: flecha que apunta a la siguiente parada, con su nombre y distancia
---------------------------------------------------------------------------

local ARRIVE_YARDS = 10
local compass

-- Ángulo desde el jugador hasta la parada, en el mismo sentido que GetPlayerFacing
-- (0 = norte, crece hacia la izquierda). En coordenadas de mundo, x es el norte e y el oeste.
local function BearingTo(stop)
	local px, py, _, instance = UnitPosition("player")
	if not px or instance ~= stop.cont then return end
	return math.atan2(stop.wy - py, stop.wx - px)
end

-- Sin AzerothGPS nadie quita las paradas al llegar: lo hace la brújula
-- Aviso grande en pantalla, como el del cambio de zona
local arrivalFrame
local function ShowArrival(title, subtitle)
	if not arrivalFrame then
		local f = CreateFrame("Frame", "BridgeArrivalFrame", UIParent)
		f:SetSize(800, 80)
		f:SetPoint("CENTER", UIParent, "CENTER", 0, 170)
		f:SetFrameStrata("HIGH")
		f:EnableMouse(false)
		f.Title = f:CreateFontString(nil, "OVERLAY")
		f.Title:SetFont("Fonts\\FRIZQT__.TTF", 28, "THICKOUTLINE")
		f.Title:SetShadowOffset(2, -2)
		f.Title:SetTextColor(0.55, 1, 0.45)
		f.Title:SetPoint("TOP")
		f.Sub = f:CreateFontString(nil, "OVERLAY")
		f.Sub:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
		f.Sub:SetShadowOffset(1, -1)
		f.Sub:SetTextColor(1, 0.82, 0)
		f.Sub:SetPoint("TOP", f.Title, "BOTTOM", 0, -6)
		f:SetScript("OnUpdate", function(self, elapsed)
			self.t = self.t + elapsed
			-- 0,5 s apareciendo, 3 s fijo, 1,5 s desapareciendo
			if self.t < 0.5 then self:SetAlpha(self.t / 0.5)
			elseif self.t < 3.5 then self:SetAlpha(1)
			elseif self.t < 5 then self:SetAlpha(1 - (self.t - 3.5) / 1.5)
			else self:Hide() end
		end)
		arrivalFrame = f
	end
	arrivalFrame.Title:SetText(title)
	arrivalFrame.Sub:SetText(subtitle or "")
	arrivalFrame.t = 0
	arrivalFrame:SetAlpha(0)
	arrivalFrame:Show()
end

-- Cartel, línea en el chat y sonido (tanto si llega la brújula como AzerothGPS).
-- La opción "Aviso al llegar" lo quita todo; la parada se quita igualmente.
function AnnounceArrival(s, nextStop)
	if DB.arrivalBanner == false then return end
	local title = L.ARRIVED:format(s.name or "?")
	local subtitle = nextStop and L.NEXT_STOP:format(nextStop.name or "?") or L.ROUTE_DONE
	ShowArrival(title, subtitle)
	Print(title .. " " .. subtitle)
	PlaySound((SOUNDKIT and SOUNDKIT.MAP_PING) or 3175)
end

-- Llegada a una parada: queda guardada en su ruta, marcada como alcanzada, y el
-- recorrido pasa a la siguiente
local function ArriveAt(index)
	local s = ReachStop(index)
	if not s then return end
	RefreshPins()
	local _, nextStop = NextStopIndex()
	AnnounceArrival(s, nextStop)
end

-- Tiempo estimado de llegada: "1:23" o "1:05:30"
local function FormatETA(seconds)
	seconds = math.floor(seconds + 0.5)
	local h, m, s = math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60
	if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
	return string.format("%d:%02d", m, s)
end

-- Cada medio segundo mide cuánto se ha acortado la distancia (velocidad de acercamiento),
-- la suaviza para que el ETA no salte, y devuelve los segundos que faltan (nil si no te acercas)
local ETA_STEP = 0.5        -- segundos entre medidas
local ETA_MIN_SPEED = 1     -- yardas/s: por debajo, no se muestra ETA
local ETA_MAX_SPEED = 150   -- yardas/s: por encima es un salto (teletransporte, cambio de parada...)
local function UpdateETA(self, stop, d)
	local now = GetTime()
	-- Sin distancia (otro continente, mazmorra...), sin medida anterior o con otra parada: volver a empezar
	if not d or not self.etaD or self.etaStop ~= stop then
		self.etaStop, self.etaD, self.etaT, self.etaSpeed = stop, d, now, nil
		return
	end
	local dt = now - self.etaT
	if dt >= ETA_STEP then
		local speed = (self.etaD - d) / dt
		if math.abs(speed) > ETA_MAX_SPEED then
			self.etaSpeed = nil
		elseif self.etaSpeed then
			self.etaSpeed = self.etaSpeed * 0.7 + speed * 0.3
		else
			self.etaSpeed = speed
		end
		self.etaD, self.etaT = d, now
	end
	if self.etaSpeed and self.etaSpeed >= ETA_MIN_SPEED then
		return d / self.etaSpeed
	end
end

local function UpdateCompass(self, elapsed)
	self.wait = (self.wait or 0) - elapsed
	if self.wait > 0 then return end
	self.wait = 0.05
	local index, stop = NextStopIndex()
	-- Tu cadáver va primero, sea cual sea la ruta activa
	local corpse = CorpseStop()
	if corpse then index, stop = nil, corpse end
	if not stop then self:Hide() return end
	local eta = UpdateETA(self, stop, DistanceTo(stop))
	self.ETA:SetText(eta and L.ETA:format(FormatETA(eta)) or "")
	local count = #Stops()
	self.Name:SetText((index and count > 1) and string.format("%s |cff999999(%d/%d)|r", stop.name or "?", index, count) or (stop.name or "?"))
	local d = DistanceTo(stop)
	local bearing = BearingTo(stop)
	local facing = GetPlayerFacing and GetPlayerFacing()
	if d and d <= ARRIVE_YARDS and not HasGPS() and not stop.corpse then
		ArriveAt(index)
		return
	end
	if d and bearing and facing then
		self.Arrow:SetRotation(bearing - facing)
		self.Arrow:Show()
		self.Dist:SetText(FormatDistance(d))
	else
		self.Arrow:Hide()
		self.Dist:SetText(d and FormatDistance(d) or L.UNKNOWN_DISTANCE)
	end
end

local function PlaceCompass()
	compass:ClearAllPoints()
	local pos = DB.compassPos
	if pos then
		compass:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos[1], pos[2])
	else
		compass:SetPoint("TOP", UIParent, "TOP", 0, -120)
	end
end

local function CreateCompass()
	if compass then return compass end
	compass = CreateFrame("Frame", "BridgeCompass", UIParent)
	compass:SetSize(140, 104)
	compass:SetFrameStrata("MEDIUM")
	compass:SetClampedToScreen(true)
	compass:SetMovable(true)
	compass:EnableMouse(true)
	compass:RegisterForDrag("LeftButton")
	compass:Hide()

	compass.Arrow = compass:CreateTexture(nil, "ARTWORK")
	compass.Arrow:SetTexture("Interface\\AddOns\\Bridge\\Media\\arrow")
	compass.Arrow:SetSize(44, 44)
	compass.Arrow:SetPoint("TOP", 0, 0)

	compass.Name = compass:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	compass.Name:SetPoint("TOP", compass.Arrow, "BOTTOM", 0, -2)
	compass.Name:SetWidth(240)
	compass.Name:SetWordWrap(false)

	compass.Dist = compass:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	compass.Dist:SetPoint("TOP", compass.Name, "BOTTOM", 0, -2)

	compass.ETA = compass:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	compass.ETA:SetPoint("TOP", compass.Dist, "BOTTOM", 0, -2)
	compass.ETA:SetTextColor(0.75, 0.75, 0.75)

	compass:SetScript("OnUpdate", UpdateCompass)
	compass:SetScript("OnDragStart", function(self) self:StartMoving() end)
	compass:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		if self.SetUserPlaced then self:SetUserPlaced(false) end
		local x, y = self:GetCenter()
		DB.compassPos = { math.floor(x + 0.5), math.floor(y + 0.5) }
		PlaceCompass()
	end)
	compass:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:SetText(L.COMPASS_TIP, 1, 1, 1)
		GameTooltip:Show()
	end)
	compass:SetScript("OnLeave", GameTooltip_Hide)
	PlaceCompass()
	return compass
end

-- Se muestra cuando está activada y quedan paradas por alcanzar
function UpdateCompassShown()
	if not DB then return end
	if DB.showCompass and (CorpseStop() or NextStopIndex()) then
		CreateCompass().wait = 0
		compass:Show()
	elseif compass then
		compass:Hide()
	end
end


---------------------------------------------------------------------------
-- Minimapa: las paradas también se ven al ir caminando.
-- Solo sin AzerothGPS (con él, ya las dibuja él en su minimapa).
---------------------------------------------------------------------------

-- Diámetro en yardas que abarca el minimapa en cada nivel de zoom (0 = más alejado)
local MINIMAP_YARDS = {
	outdoor = { [0] = 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 3, 200, 133 + 1 / 3 },
	indoor = { [0] = 300, 240, 180, 120, 80, 50 },
}
local MINI_SIZE = 18
local miniPins = {}

local function MiniPin(i)
	local pin = miniPins[i]
	if pin then return pin end
	pin = CreateFrame("Frame", nil, Minimap)
	pin:SetSize(MINI_SIZE, MINI_SIZE)
	pin.Icon = pin:CreateTexture(nil, "ARTWORK")
	pin.Icon:SetTexture(PIN_TEXTURE)
	pin.Icon:SetSize(MINI_SIZE, MINI_SIZE)
	-- Igual que en el mapa: la punta del pin cae en el punto de la parada
	pin.Icon:SetPoint("CENTER", 0, MINI_SIZE * 13 / 28)
	pin.Label = pin:CreateFontString(nil, "OVERLAY")
	pin.Label:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
	pin.Label:SetTextColor(1, 1, 1)
	pin.Label:SetPoint("CENTER", pin.Icon, "CENTER", 0, 0)
	-- Solo el ratón por encima (tooltip); los clics siguen yendo al minimapa
	if pin.SetMouseClickEnabled then
		pin:SetMouseClickEnabled(false)
		pin:SetMouseMotionEnabled(true)
	else
		pin:EnableMouse(true)
	end
	pin:SetHitRectInsets(3, 3, -7, MINI_SIZE / 2)
	pin:SetScript("OnEnter", function(self)
		local st = self.stop
		if not st then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(st.name or "?", 1, 0.82, 0)
		if st.desc then GameTooltip:AddLine(st.desc, 0.9, 0.9, 0.9, true) end
		if st.reached then GameTooltip:AddLine(L.REACHED_TIP, 0.6, 0.6, 0.6) end
		local d = DistanceTo(st)
		if d then GameTooltip:AddLine(FormatDistance(d), 1, 1, 1) end
		GameTooltip:Show()
	end)
	pin:SetScript("OnLeave", GameTooltip_Hide)
	miniPins[i] = pin
	return pin
end

local function HideMiniPins(from)
	for i = from or 1, #miniPins do miniPins[i]:Hide() end
end

local function UpdateMinimapPins()
	if not DB or HasGPS() or not DB.showPins or not Minimap:IsVisible() then
		HideMiniPins()
		return
	end
	local px, py, _, instance = UnitPosition("player")
	if not px then HideMiniPins() return end
	local zoom = Minimap:GetZoom() or 0
	local sizes = (IsIndoors and IsIndoors()) and MINIMAP_YARDS.indoor or MINIMAP_YARDS.outdoor
	local radius = (sizes[zoom] or sizes[0]) / 2
	local halfW, halfH = Minimap:GetWidth() / 2, Minimap:GetHeight() / 2
	local rotate = GetCVar("rotateMinimap") == "1"
	local facing = rotate and GetPlayerFacing and GetPlayerFacing() or 0
	local cosF, sinF = math.cos(-facing), math.sin(-facing)
	local square = GetMinimapShape and GetMinimapShape() == "SQUARE"
	local shown = 0
	for i, st in ipairs(Stops()) do
		if st.wx and st.cont == instance and not st.corpse then
			-- En coordenadas de mundo, x es el norte e y el oeste
			local east, north = py - st.wy, st.wx - px
			if rotate then
				east, north = east * cosF - north * sinF, east * sinF + north * cosF
			end
			local x, y = east / radius, north / radius
			-- Las que caen fuera se quedan en el borde, señalando hacia dónde están
			local edge = false
			if square then
				local m = math.max(math.abs(x), math.abs(y))
				if m > 1 then x, y, edge = x / m, y / m, true end
			else
				local m = math.sqrt(x * x + y * y)
				if m > 0.95 then x, y, edge = x / m * 0.95, y / m * 0.95, true end
			end
			shown = shown + 1
			local pin = MiniPin(shown)
			pin.stop = st
			ApplyLook(pin.Icon, pin.Label, st, i, MINI_SIZE)
			pin:SetAlpha(edge and 0.6 or 1)
			pin:SetFrameLevel(Minimap:GetFrameLevel() + 5 + (#Stops() - i))
			pin:ClearAllPoints()
			pin:SetPoint("CENTER", Minimap, "CENTER", x * halfW, y * halfH)
			pin:Show()
		end
	end
	HideMiniPins(shown + 1)
end

local function StartMinimapPins()
	if not Minimap then return end
	local driver = CreateFrame("Frame")
	local wait = 0
	driver:SetScript("OnUpdate", function(_, elapsed)
		wait = wait - elapsed
		if wait > 0 then return end
		wait = 0.05
		UpdateMinimapPins()
	end)
end


---------------------------------------------------------------------------
-- Tu cadáver: al liberar el espíritu se pone en la ruta Rápida (y delante de la ruta
-- activa para la brújula y AzerothGPS), y se quita al resucitar
---------------------------------------------------------------------------

local deathSpot -- dónde moriste: { mapID, x, y }

local function RememberDeathSpot()
	deathSpot = nil
	local mapID = C_Map.GetBestMapForUnit("player")
	local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
	if pos then
		local x, y = pos:GetXY()
		if x and x > 0 then deathSpot = { mapID, x, y } end
	end
end

-- Si no lo apuntamos al morir (p. ej. al entrar ya como fantasma), se lo preguntamos al juego
local function CorpseSpot()
	if deathSpot then return unpack(deathSpot) end
	if not (C_DeathInfo and C_DeathInfo.GetCorpseMapPosition) then return end
	local mapID = C_Map.GetBestMapForUnit("player")
	while mapID do
		local pos = C_DeathInfo.GetCorpseMapPosition(mapID)
		if pos then
			local x, y = pos:GetXY()
			if x and x > 0 then return mapID, x, y end
		end
		local info = C_Map.GetMapInfo(mapID)
		mapID = info and info.parentMapID ~= 0 and info.parentMapID or nil
	end
end

-- Quita tu cadáver de donde esté (en la Rápida; en datos antiguos, de cualquier ruta)
local function RemoveCorpseStop()
	local removed = false
	for _, route in ipairs(DB.routes) do
		for i = #route.stops, 1, -1 do
			local st = route.stops[i]
			if st.corpse then
				local public = PublicStop(st)
				table.remove(route.stops, i)
				Fire("STOP_REMOVED", public)
				removed = true
			end
		end
	end
	if removed then
		RebuildRoute()
		RefreshPins()
	end
end

local function AddCorpseStop()
	RemoveCorpseStop()
	local mapID, x, y = CorpseSpot()
	if not mapID then return end -- p. ej. dentro de una mazmorra
	local zMap, zx, zy = ToZone(mapID, x, y)
	zMap, zx, zy = zMap or mapID, zx or x, zy or y
	local info = C_Map.GetMapInfo(zMap)
	local zoneName = info and info.name or "?"
	local cont, wx, wy = ToWorld(zMap, zx, zy)
	local stop = {
		id = NewStopId(), name = L.CORPSE, zone = zoneName, mapID = zMap, x = zx, y = zy,
		cont = cont, wx = wx, wy = wy, corpse = true, source = "Bridge",
		line = string.format("/way %s %.1f %.1f %s", zoneName, zx * 100, zy * 100, L.CORPSE),
	}
	-- En la ruta Rápida, el primero. La brújula y AzerothGPS lo ponen delante de la ruta
	-- activa: primero recuperas el cuerpo, luego sigue la ruta que tenías.
	table.insert(EnsureCurrentRoute().stops, 1, stop)
	RebuildRoute()
	RefreshPins()
	Print(L.CORPSE_ADDED)
	Fire("STOP_ADDED", PublicStop(stop))
end

local function OnDeathEvent(event)
	if not DB then return end
	if event == "PLAYER_DEAD" then
		RememberDeathSpot()
	elseif event == "PLAYER_ALIVE" then
		-- Se dispara al liberar el espíritu (ya eres fantasma)
		-- y también si te resucitan sin haberlo liberado
		if UnitIsGhost("player") then AddCorpseStop() else RemoveCorpseStop(); deathSpot = nil end
	elseif event == "PLAYER_UNGHOST" then
		RemoveCorpseStop()
		deathSpot = nil
	end
end

local function StartCorpseWatch()
	-- No se guarda entre sesiones: si entras siendo fantasma, se vuelve a poner
	for _, route in ipairs(DB.routes) do
		for i = #route.stops, 1, -1 do
			if route.stops[i].corpse then table.remove(route.stops, i) end
		end
	end
	if UnitIsGhost("player") then C_Timer.After(2, AddCorpseStop) end
	local ev = CreateFrame("Frame")
	ev:RegisterEvent("PLAYER_DEAD")
	ev:RegisterEvent("PLAYER_ALIVE")
	ev:RegisterEvent("PLAYER_UNGHOST")
	ev:SetScript("OnEvent", function(_, event) OnDeathEvent(event) end)
end


---------------------------------------------------------------------------
-- Paradas compartidas por otros jugadores que tienen Bridge
---------------------------------------------------------------------------

local SHARE_PREFIX = "Bridge"

local function OnSharedStop(text, sender)
	local version, mapID, x, y, name = strsplit("\t", text, 5)
	if version ~= "1" then return end
	mapID, x, y = tonumber(mapID), tonumber(x), tonumber(y)
	if not (mapID and x and y) then return end
	local info = C_Map.GetMapInfo(mapID)
	if not info then return end
	name = (name and name ~= "") and name or info.name
	local who = Ambiguate and Ambiguate(sender, "short") or sender
	StaticPopupDialogs.BRIDGE_SHARED_STOP = StaticPopupDialogs.BRIDGE_SHARED_STOP or {
		text = L.SHARED_ASK,
		button1 = L.SHARED_ADD,
		button2 = L.SHARED_IGNORE,
		OnAccept = function(_, data)
			AddStop(data.mapID, data.x, data.y, data.name, false, false, { source = data.who })
		end,
		timeout = 60,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Show("BRIDGE_SHARED_STOP", who, string.format("%s (%s)", name, info.name), nil,
		{ mapID = mapID, x = x, y = y, name = name, who = who })
end

local function StartSharing()
	if not (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) then return end
	C_ChatInfo.RegisterAddonMessagePrefix(SHARE_PREFIX)
	local ev = CreateFrame("Frame")
	ev:RegisterEvent("CHAT_MSG_ADDON")
	ev:SetScript("OnEvent", function(_, _, prefix, text, _, sender)
		if prefix ~= SHARE_PREFIX or not DB or type(text) ~= "string" then return end
		-- Lo que mandas tú también te llega: lo ignoramos
		local me = UnitName("player")
		if sender == me or (Ambiguate and Ambiguate(sender or "", "none") == me) then return end
		OnSharedStop(text, sender or "?")
	end)
end

---------------------------------------------------------------------------
-- API pública: BridgeAPI (ver API.md)
---------------------------------------------------------------------------

local API = { version = 1 }
BridgeAPI = API

-- Eventos que se pueden escuchar con RegisterCallback
API.events = { "STOP_ADDED", "STOP_REMOVED", "STOP_CHANGED", "STOP_REACHED", "STOPS_REORDERED", "STOPS_CLEARED", "ACTIVE_ROUTE_CHANGED" }
local KNOWN_EVENTS = {}
for _, e in ipairs(API.events) do KNOWN_EVENTS[e] = true end

local function FindById(id)
	for i, st in ipairs(Stops()) do
		if st.id == id then return i, st end
	end
end

local function ValidPoint(mapID, x, y)
	return type(mapID) == "number" and type(x) == "number" and type(y) == "number"
		and x >= 0 and x <= 1 and y >= 0 and y <= 1
end

-- Añade una parada. x, y entre 0 y 1 (como C_Map). opts (opcional):
--   name = "texto", description = "texto" (sale en el tooltip),
--   exclusive = true (borra la ruta y deja solo esta),
--   source = "MiAddon", silent = true (no escribe en el chat).
-- Devuelve el id de la parada, o nil si no se pudo añadir.
function API.AddStop(mapID, x, y, opts)
	if not DB or not ValidPoint(mapID, x, y) then return nil end
	opts = type(opts) == "table" and opts or {}
	local stop = AddStop(mapID, x, y, opts.name, opts.exclusive, false, opts)
	return stop and stop.id
end

-- Borra la ruta y deja esta parada como única (como "Establecer ruta")
function API.RouteTo(mapID, x, y, opts)
	opts = type(opts) == "table" and opts or {}
	opts.exclusive = true
	return API.AddStop(mapID, x, y, opts)
end

function API.RemoveStop(id)
	local i = FindById(id)
	if not i then return false end
	RemoveStop(i)
	return true
end

function API.ClearStops()
	if DB then ClearStops() end
end

function API.RenameStop(id, name)
	local i = FindById(id)
	name = CleanName(name)
	if not (i and name) then return false end
	return RenameStop(i, name) or false
end

function API.MoveStop(id, mapID, x, y)
	local i = FindById(id)
	if not (i and ValidPoint(mapID, x, y)) then return false end
	return MoveStop(i, mapID, x, y) or false
end

-- Cambia la posición de una parada en la ruta (1 = la primera)
function API.ReorderStop(id, position)
	local i = FindById(id)
	if not (i and type(position) == "number") then return false end
	position = math.max(1, math.min(math.floor(position), #Stops()))
	if position == i then return true end
	return MoveStopTo(i, position) or false
end

function API.GetStop(id)
	local _, st = FindById(id)
	return PublicStop(st)
end

-- Todas las paradas, en el orden de la ruta (copias: cambiarlas no afecta a Bridge)
function API.GetStops()
	local list = {}
	if DB then
		for _, st in ipairs(Stops()) do table.insert(list, PublicStop(st)) end
	end
	return list
end

-- Abre el mapa del mundo en la parada y la hace parpadear
function API.ShowStop(id)
	local _, st = FindById(id)
	if not st then return false end
	NavigateToStop(st)
	return true
end

-- Distancia en yardas desde el jugador (nil si no se puede saber: otro continente,
-- mazmorra…)
function API.GetDistance(id)
	local _, st = FindById(id)
	return st and DistanceTo(st)
end

-- ¿Las paradas se convierten en ruta? (AzerothGPS instalado y cargado)
function API.HasAzerothGPS()
	return HasGPS()
end

-- Avisos: fn(evento, parada) — parada es una copia (en STOPS_REORDERED y
-- STOPS_CLEARED no hay parada). 'owner' identifica a quien escucha (p. ej. el
-- nombre de tu addon); una sola función por dueño y evento.
function API.RegisterCallback(owner, event, fn)
	if owner == nil or not KNOWN_EVENTS[event] or type(fn) ~= "function" then return false end
	callbacks[event] = callbacks[event] or {}
	callbacks[event][owner] = fn
	return true
end

function API.UnregisterCallback(owner, event)
	if event then
		if callbacks[event] then callbacks[event][owner] = nil end
	else
		for _, list in pairs(callbacks) do list[owner] = nil end
	end
end

---------------------------------------------------------------------------
-- Comandos y arranque
---------------------------------------------------------------------------

SLASH_BRIDGE1 = "/bridge"

-- Los comandos van siempre en inglés, sea cual sea el idioma del juego
local ALIASES = {
	clear = "clear", markers = "markers", size = "size", button = "button",
	version = "version", diag = "diag", debug = "debug", copy = "copy", manage = "manage",
	import = "import",
}

local HandleSlash
-- Estos comandos abren además la ventana para copiar
local COPYABLE = { diag = true }
SlashCmdList.BRIDGE = function(msg)
	msg = (msg or ""):lower():match("^%s*(.-)%s*$")
	local word, arg = msg:match("^(%S*)%s*(.-)$")
	local cmd = ALIASES[word]
	if cmd == "copy" then
		ShowLog(recentLines, L.LOG_RECENT)
		return
	end
	if COPYABLE[cmd] then captureBuf = {} end
	local ok, err = pcall(HandleSlash, cmd, arg)
	local captured = captureBuf
	captureBuf = nil
	if not ok then Print(L.ERROR:format(tostring(err))) end
	if captured and #captured > 0 then ShowLog(captured, "Bridge: /bridge " .. msg) end
end

HandleSlash = function(cmd, arg)
	if cmd == "clear" then
		ClearStops()
	elseif cmd == "markers" then
		DB.showPins = not DB.showPins
		RefreshPins()
		Print(DB.showPins and L.MARKERS_SHOWN or L.MARKERS_HIDDEN)
	elseif cmd == "button" and arg == "reset" then
		DB.buttonPos = nil
		if button then button:Place() end
		Print(L.BUTTON_RESET)
	elseif cmd == "button" then
		DB.showButton = not DB.showButton
		UpdateButton()
		Print(DB.showButton and L.BUTTON_SHOWN or L.BUTTON_HIDDEN)
	elseif cmd == "manage" then
		ToggleManager()
	elseif cmd == "import" then
		ShowImport()
	elseif cmd == "version" then
		Print(L.VERSION:format(VERSION))
	elseif cmd == "size" then
		local n = tonumber(arg)
		if n and n >= 30 and n <= 200 then
			DB.pinScale = n / 100
			RefreshPins()
			Print(L.SIZE_SET:format(n))
		else
			Print(L.SIZE_CURRENT:format(math.floor((DB.pinScale or 1) * 100 + 0.5), W.size))
		end
	elseif cmd == "debug" then
		DB.debug = not DB.debug
		Print(DB.debug and L.DEBUG_ON or L.DEBUG_OFF)
	elseif cmd == "diag" then
		Print(L.DIAG_HEADER:format(VERSION))
		Print(L.DIAG_CLIENT:format(tostring(select(4, GetBuildInfo()))))
		local api = AzerothGPS
		Print(type(api) == "table" and L.DIAG_AGPS_LOADED:format(tostring(api.version)) or L.DIAG_AGPS_MISSING)
		for _, slash in ipairs({ "/way", "/agps", "/tway" }) do
			local names = {}
			for _, h in ipairs(HandlersFor(slash)) do table.insert(names, h.key) end
			Print(slash .. " -> " .. (#names > 0 and table.concat(names, ", ") or L.DIAG_NOBODY))
		end
		if ChatFrame_ImportAllListsToHash then pcall(ChatFrame_ImportAllListsToHash) end
		local winner = hash_SlashCmdList and hash_SlashCmdList["/WAY"]
		if winner then
			for key, fn in pairs(SlashCmdList) do
				if fn == winner then Print(L.DIAG_WAY_WINNER:format(key)) end
			end
		end
		Print(L.DIAG_API:format(API.version))
		Print(L.DIAG_WAY_OWN:format(wayRegistered and L.YES
			or wayStatus == "agps" and L.DIAG_WAY_AGPS
			or wayStatus == "other" and L.DIAG_WAY_OTHER
			or L.NO))
		Print(L.DIAG_TOMTOM:format(type(TomTom) == "table" and (TomTom.isBridge and L.DIAG_TOMTOM_SHIM or L.DIAG_TOMTOM_REAL) or L.NO))
		Print(L.DIAG_QUESTIE:format(type(QuestieLoader) == "table" and L.DIAG_LOADED or L.NO))
		-- Iconos del mapa del mundo que Bridge escucha (para Alt + clic sobre ellos)
		local pins, hooked = 0, 0
		HookPins(WorldMapFrame)
		ForEachMapPin(WorldMapFrame, function() pins = pins + 1 end)
		for _ in pairs(hookedFrames) do hooked = hooked + 1 end
		Print(L.DIAG_PINS:format(pins, hooked))
		Print(L.DIAG_STOPS:format(#Stops(), DB.debug and L.YES or L.NO))
		local _, first = NextStopIndex()
		local d = first and DistanceTo(first)
		Print(L.DIAG_COMPASS:format(DB.showCompass and L.YES or L.NO,
			(BridgeCompass and BridgeCompass:IsShown()) and L.YES or L.NO,
			d and string.format("%d yd", math.floor(d + 0.5)) or "-"))
	else
		Print(L.HELP_HEADER:format(VERSION))
		local lines = {
			{ W.manage, L.HELP_MANAGE },
			{ W.import, L.HELP_IMPORT },
			{ W.clear, L.HELP_CLEAR },
			{ W.markers, L.HELP_MARKERS },
			{ W.size .. " N", L.HELP_SIZE },
			{ W.button, L.HELP_BUTTON },
			{ W.button .. " " .. W.reset, L.HELP_BUTTON_RESET },
			{ W.version, L.HELP_VERSION },
		}
		for _, l in ipairs(lines) do Print("  /bridge " .. l[1] .. " - " .. l[2]) end
		Print("  " .. L.HELP_DEV:format(W.copy))
		Print(L.HELP_MAP)
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("MODIFIER_STATE_CHANGED")
f:SetScript("OnEvent", function(_, event, name)
	if event == "ADDON_LOADED" then
		if name == ADDON then
			BridgeAddonDB = BridgeAddonDB or {}
			DB = BridgeAddonDB
			-- Rutas compartidas con todos tus personajes (datos de la cuenta)
			BridgeSharedDB = BridgeSharedDB or {}
			SharedDB = BridgeSharedDB
			SharedDB.routes = SharedDB.routes or {}
			MigrateData()
			if DB.showPins == nil then DB.showPins = true end
			if DB.showButton == nil then DB.showButton = true end
			-- Restos de versiones anteriores
			DB.method, DB.syncAGPS, DB.pinsSmallMaps, DB.lastLog, DB.count, DB.corpseStop = nil, nil, nil, nil, nil, nil
			for _, route in ipairs(DB.routes) do
				for _, st in ipairs(route.stops) do
					st.id = st.id or NewStopId()
					st.pendingUntil, st.sentAt, st.inAGPS, st.missingSince = nil, nil, nil, nil
					st.agpsCont, st.agpsX, st.agpsY, st.temporary = nil, nil, nil, nil
				end
			end
		elseif name == "Blizzard_BattlefieldMap" and BattlefieldMapFrame then
			AttachToMap(BattlefieldMapFrame) -- el mapa de zona que Leatrix también mejora
		end
	elseif event == "MODIFIER_STATE_CHANGED" then
		for provider in pairs(providers) do
			local map = provider:GetMap()
			if map then
				for _, pin in EachBridgePin(map) do pin:UpdatePassThrough() end
			end
		end
	elseif event == "PLAYER_LOGIN" then
		AttachToMap(WorldMapFrame)
		CreateMapButton()
		if BattlefieldMapFrame then AttachToMap(BattlefieldMapFrame) end
		HookArrivals()
		-- Un segundo de margen para que los addons terminen de registrar sus comandos
		C_Timer.After(1, function()
			HookWayCommands()
			RegisterWayCommand()
			RegisterCwayCommand()
		end)
		HookChatBoxes()
		HookQuestie()
		UpdateCompassShown()
		StartMinimapPins()
		StartCorpseWatch()
		StartSharing()
		Print(L.LOADED:format(VERSION))
	end
end)
