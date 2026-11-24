--[[
Bridge: imitación de TomTom

Muchos addons (Questie, guías, buscadores de raros…) solo saben mandar puntos a
TomTom. Si el TomTom de verdad NO está activado, Bridge crea la tabla global
"TomTom" con las funciones que esos addons usan, y cada punto se convierte en una
parada de Bridge (y, con AzerothGPS, en ruta).

Si TomTom está activado, este archivo no hace nada: el de verdad manda.
Cualquier función de TomTom que no esté aquí existe, pero no hace nada (para que
los demás addons no den errores).
]]

local _, ns = ...

-- Bridge se carga después de TomTom (OptionalDeps en Bridge.toc): si TomTom está
-- activado, a estas alturas ya está cargado y existe su tabla global.
local function TomTomLoaded()
	if C_AddOns and C_AddOns.IsAddOnLoaded then return (C_AddOns.IsAddOnLoaded("TomTom")) end
	return IsAddOnLoaded and IsAddOnLoaded("TomTom")
end

if TomTom ~= nil or TomTomLoaded() or not BridgeAPI then return end

local API = BridgeAPI
local noop = function() end

-- Un "uid" de TomTom es una tabla { mapID, x, y, title = ... }. Algunos addons
-- leen uid[1], uid[2], uid[3] o uid.title, así que se respeta esa forma.
-- uidToId relaciona cada uid con el id de la parada de Bridge.
local uidToId = setmetatable({}, { __mode = "k" })

local function ValidUid(uid)
	local id = type(uid) == "table" and uidToId[uid]
	return id and API.GetStop(id) ~= nil, id
end

local Shim = {
	isBridge = true, -- para quien quiera saber que es la imitación de Bridge
	waypoints = {}, -- algunos addons miran esta tabla; Bridge no la usa
}

-- TomTom:AddWaypoint(mapID, x, y, opts) → uid
-- opts: title/desc, from/source, silent (el resto: crazy, persistent, minimap,
-- world, callbacks… no aplican en Bridge y se ignoran)
function Shim:AddWaypoint(mapID, x, y, opts)
	opts = type(opts) == "table" and opts or {}
	if type(mapID) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then return nil end
	local title = opts.title or opts.desc
	local id = API.AddStop(mapID, x, y, {
		name = type(title) == "string" and title or nil,
		source = opts.source or opts.from or "TomTom",
		silent = opts.silent,
	})
	if not id then return nil end
	local stop = API.GetStop(id)
	local uid = { mapID, x, y, title = stop and stop.name or title, from = opts.from or opts.source }
	uidToId[uid] = id
	return uid
end

-- Versión antigua con planta (floor): la planta no se usa
function Shim:AddMFWaypoint(mapID, floor, x, y, opts)
	return self:AddWaypoint(mapID, x, y, opts)
end

function Shim:RemoveWaypoint(uid)
	local valid, id = ValidUid(uid)
	if valid then API.RemoveStop(id) end
	if type(uid) == "table" then uidToId[uid] = nil end
end

function Shim:IsValidWaypoint(uid)
	return (ValidUid(uid))
end

-- ¿Hay ya una parada en ese punto (y con ese nombre, si se da)?
function Shim:WaypointExists(mapID, x, y, desc)
	for _, stop in ipairs(API.GetStops()) do
		if stop.mapID == mapID and math.abs(stop.x - x) < 0.0005 and math.abs(stop.y - y) < 0.0005
			and (desc == nil or stop.name == desc) then
			return true
		end
	end
	return false
end

function Shim:GetDistanceToWaypoint(uid)
	local valid, id = ValidUid(uid)
	if valid then return API.GetDistance(id) end
end

function Shim:ClearAllWaypoints()
	API.ClearStops()
end

-- La flecha de TomTom no existe en Bridge (la ruta la guía AzerothGPS): estas
-- funciones se aceptan pero no hacen nada.
Shim.SetCrazyArrow = noop
Shim.SetClosestWaypoint = noop
Shim.ShowHideCrazyArrow = noop
Shim.HideCrazyArrow = noop

-- Callbacks de TomTom: aceptados, sin efecto
Shim.RegisterCallback = noop
Shim.UnregisterCallback = noop

-- Cualquier otra función de TomTom (nombres que empiezan por mayúscula) existe
-- pero no hace nada. Los demás campos (p. ej. TomTom.db) siguen siendo nil.
setmetatable(Shim, {
	__index = function(_, key)
		if type(key) == "string" and key:match("^%u") then return noop end
	end,
})

TomTom = Shim
ns.TomTomShim = Shim
