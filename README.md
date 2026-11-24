# Bridge

[https://www.curseforge.com/wow/addons/bridge](https://www.curseforge.com/wow/addons/bridge)

> *[Versión en español más abajo](#espanol)*

## English

**Bridge** is a **waypoint** addon: you mark the places you want to go on the map, and Bridge points you towards them.

Each place you mark is a **stop**: add it with a click, give it a name, and see it on the map and the minimap with its number. An optional on-screen arrow shows you which way to go and how far it is. When you get there, the arrow moves on to the next one; your stops stay saved.

### ✨ Features

* **Stops on the world map**: add, move, rename and remove them with the mouse.
* **Descriptions**: give a stop an optional description; it shows in its tooltip on the map and the minimap.
* **Names**: each stop can have its own; drop a stop on a map icon and it takes the icon's name.
* **Minimap**: stops also show while you walk; far-away ones sit on the edge, pointing the way.
* **Compass**: an on-screen arrow with the next stop's name, distance and estimated time of arrival.
* **Arrival notice**: an on-screen banner, *"You have arrived at… · Next stop: …"*, with a line in chat and a sound. It can be turned off.
* **Your corpse**: when you die and release your spirit, your body becomes the first stop; it goes away when you resurrect.
* **Manage routes**: a window with your routes and their stops: search, reorder, rename and remove stops.
* **Sharing**: send a stop to your party, raid or guild; players with Bridge can add it with one click.
* **`/way` commands**: type coordinates in chat and they become stops.
* **Import `/way` lists**: paste a list of `/way` lines from a guide or website and they all become stops, in order.
* **Yards or meters**, your choice.
* **Stops are kept** between sessions.

---

### ⚙️ Installation

1. Close the game.
2. Copy the `Bridge` folder into `World of Warcraft/<your version>/Interface/AddOns/`. *(On WoW Forever, `<your version>` is the Forever folder, for example `_forever_`).*
   * **On Mac**, the folder is usually in `/Applications/World of Warcraft/`. If you can't find it: Battle.net app → game's gear icon → **Show in Finder**.
3. Start the game. The chat should show: `Bridge: Version … loaded`.

> **Note:** if the game flags it as "out of date", type `/dump select(4, GetBuildInfo())` and put that number on the `## Interface:` line of the `Bridge.toc` file.

---

### 🖱️ Usage

Open the world map (**M** key).

| What you want to do | Windows | Mac |
|---|---|---|
| Add a stop | **Alt + click** on the map | **⌥ Option + click** |
| Add a stop named after a map icon *(wait for its tooltip)* | **Alt + click** on the icon | **⌥ + click** on the icon |
| Go only to that point (clears the other stops) | **Alt + Shift + click** | **⌥ + ⇧ + click** |
| Remove a stop | **Alt + click** on it | **⌥ + click** on it |
| Move a stop | **Alt + drag** | **⌥ + drag** |
| Stop menu (edit name and description, share, remove) | **Alt + right-click** | **⌥ + two-finger click** |
| See name, distance and coordinates | Hover over it | Same |

When you add a stop, a small box shows a suggested name: **Enter** accepts it (or type another one), **Esc** cancels.

> On Mac, **Ctrl** is the Control key (⌃), not Command (⌘). `Ctrl + click` places the game's own map pin, which Bridge leaves alone.

#### "Bridge" button

It sits at the top right of the world map. Click it to open its menu:

* **Turn on route mode**: while it is on (the button glows green), a plain click adds stops. It turns off when you close the map.
* **Manage routes…**: on the left, your routes (the active one has a green radio button: click another one's button to activate it); on the right, the stops of the route you select. **New route** (under the list) asks for a name and creates an empty route; the ✎ icon next to the route's name renames it, + duplicates it (a copy with all its stops), and ✕ deletes it with its stops (after confirming; the last route can't be deleted, and if you delete the active one another route is activated). Activating a route makes it the one the compass, the map, the minimap and AzerothGPS follow, starting from its first stop. Search by name or zone, jump to one on the map (its pin flashes), edit its name and description, remove it, and reorder with ▲▼ or by dragging rows. To move a stop to another route, drag it onto that route in the list on the left, or right-click it and choose **Move to**. The right-click menu also has **Edit name and description**. The **Import /way list** button opens a box where you can paste many `/way` lines at once: each one becomes a stop, in order (with or without `/way` in front). Lines repeating a stop you already have are skipped, and you can tick a box to clear your current stops first.
* **Clear stops** ▸ **In this zone** (the one shown on the map) or **All**.
* **Units** ▸ **Yards** or **Meters**. Meters by default (yards if the game is in US English).
* **Show compass** (off by default).
* **Arrival notice** (on by default): the banner, the chat line and the sound. Turn it off to reach stops silently: the route still advances.
* **Ask for a name when adding** (on by default). The box also has an optional **Description** field (Tab to move to it); the description shows in the stop's tooltip on the map and the minimap. You can add or change it later with **Edit name and description**.

To move the button: **Shift + drag** (`/bridge button reset` puts it back).

#### Compass and arrival

The compass points in a straight line to the next stop (number 1) and shows its name, how many are left, the distance and the estimated time of arrival (ETA), worked out from how fast you are getting closer; it is hidden while you are standing still or moving away. Drag it to move it. Within 10 yards, the stop is marked as reached (it stays saved in its route), the arrival notice shows up (if turned on) and the compass moves on to the next stop. After the last one, the notice says the route is completed. The compass is what detects your arrival: if it is turned off, the route doesn't advance.

#### Your corpse

If you die and release your spirit, the first thing you need is to get back to your body. So Bridge adds your corpse as the **first stop**: the compass takes you to it and, when you resurrect, the stop goes away and you carry on with the stops you already had, in the same order. It doesn't matter how you resurrect: at your corpse, at the spirit healer, or when another player resurrects you. It is not added if you die inside a dungeon.

---

### ⌨️ Commands

Almost everything is done from the map and the button.

| Command | Result |
|---|---|
| `/bridge` | Help. |
| `/bridge manage` | Open the "Manage routes" window. |
| `/bridge import` | Paste a list of `/way` lines to add them as stops. |
| `/bridge clear` | Clear all stops. |
| `/bridge markers` | Show or hide the markers (map and minimap). |
| `/bridge size N` | Marker size, 30 to 200 (%). |
| `/bridge button` | Show or hide the map button. |
| `/bridge button reset` | Put the button back in place. |
| `/bridge version` | Check the installed version. |
| `/way zone x y name` | Add a stop (e.g. `/way Elwynn Forest 42 65 Goldshire`). |
| `/way reset all` | Clear all stops. |
| `/way reset <zone>` | Clear the stops in that zone. |
| `/way reset not <zone>` | Clear the stops in other zones. |
| `/cway` | The closest stop becomes the next one. |

---

### 🤝 Synergies

Bridge works on its own, but it gets along with these addons:

* **Leatrix Maps**: Bridge works on the world map, so it works just the same with Leatrix Maps' enhanced map.
* **Questie**: right-click a quest in the tracker (or one of its objectives):
  * **Set route**: clears your stops and leaves the nearest objective as the only stop.
  * **Add as stop**: adds the nearest objective at the end of your stops.
* **AzerothGPS**: every change to your stops updates its route right away; it follows the roads, is drawn on the minimap and gives directions.
  * With AzerothGPS running, Bridge draws nothing on the minimap or in its windows: AzerothGPS already marks the stops. It is also the one that detects when you arrive.
  * ⚠️ **Limitation:** information only flows from Bridge to AzerothGPS. AzerothGPS does not let other addons read its route, so if you remove a stop from the AzerothGPS map, Bridge won't know. Always remove them from the world map.
* **TomTom**: using it together with Bridge is not recommended, because you would see points twice and each would keep its own list. You don't need it either: many addons (leveling guides, rare scanners…) send their points to TomTom. When TomTom is not enabled, Bridge picks up those points instead and turns them into stops, so those addons keep working just the same.

---

### 🌍 Languages

* **Spanish**: when the game is in Spanish.
* **English**: in any other language.

---

### 🧩 For developers

* **API**: Bridge has a public API, `BridgeAPI`, so other addons or your macros (`/run`) can create and manage stops and get notified of changes. It is documented in [API.md](API.md).
* **Diagnostics**: `/bridge diag` shows the addon's status; `/bridge debug` turns on debug messages; `/bridge copy` opens a window with the latest messages, already selected for copying (**Ctrl + C**, or **⌘ + C** on Mac).
* **Saved data**: `World of Warcraft/<your version>/WTF/Account/<ACCOUNT>/<realm>/<character>/SavedVariables/Bridge.lua`. The game writes it when you reload (`/reload`) or log out.
* **License**: Bridge is *All Rights Reserved*: its code may not be copied, modified or re-uploaded without permission. Using the public API from your own addon is free and needs no permission.

---

### 🐞 Feedback and bug reports

Found a bug or have an idea? Leave a comment on the CurseForge project page. For bugs, please include the output of `/bridge diag` (it opens in a window, ready to copy).

<br>

---
---

<a name="espanol"></a>
## Español


**Bridge** es un addon de **puntos de ruta** (*waypoints*): marcas en el mapa los sitios a los que quieres ir y Bridge te señala hacia ellos.

Cada sitio que marcas es una **parada**: la pones con un clic, le das un nombre y la ves en el mapa y en el minimapa con su número. Una flecha opcional en pantalla te indica hacia dónde ir y a qué distancia está. Al llegar, la flecha pasa a la siguiente; tus paradas siguen guardadas.

### ✨ Funciones

* **Paradas en el mapa del mundo**: añadir, mover, renombrar y quitar con el ratón.
* **Descripciones**: añade a una parada una descripción opcional; sale en su tooltip del mapa y del minimapa.
* **Nombres**: cada parada puede tener el suyo; si pones la parada sobre un icono del mapa, toma su nombre.
* **Minimapa**: las paradas también se ven al ir caminando; las lejanas se quedan en el borde, señalando hacia dónde están.
* **Brújula**: flecha en pantalla con el nombre de la siguiente parada, la distancia y el tiempo estimado de llegada.
* **Aviso al llegar**: un cartel en pantalla, *"Has llegado a… · Siguiente parada: …"*, con una línea en el chat y un sonido. Se puede desactivar.
* **Tu cadáver**: al morir y liberar el espíritu, tu cuerpo pasa a ser la primera parada; se quita al resucitar.
* **Gestionar rutas**: una ventana con tus rutas y sus paradas: buscar, ordenar, renombrar y quitar paradas.
* **Compartir**: manda una parada a tu grupo, banda o hermandad; quien tenga Bridge puede añadirla con un clic.
* **Comandos `/way`**: escribe coordenadas en el chat y se convierten en paradas.
* **Importar listas de `/way`**: pega una lista de líneas `/way` de una guía o una web y todas se convierten en paradas, en orden.
* **Yardas o metros**, a tu elección.
* **Las paradas se guardan** entre sesiones.

---

### ⚙️ Instalación

1. Cierra el juego.
2. Copia la carpeta `Bridge` en `World of Warcraft/<tu versión>/Interface/AddOns/`. *(En WoW Forever, `<tu versión>` es la carpeta de Forever, por ejemplo `_forever_`).*
   * **En Mac**, la carpeta suele estar en `/Aplicaciones/World of Warcraft/`. Si no la encuentras: app de Battle.net → rueda dentada del juego → **Mostrar en el Finder**.
3. Abre el juego. En el chat debe aparecer: `Bridge: Versión … cargada`.

> **Nota:** si el juego lo marca como "desactualizado", escribe `/dump select(4, GetBuildInfo())` y pon ese número en la línea `## Interface:` del archivo `Bridge.toc`.

---

### 🖱️ Uso

Abre el mapa del mundo (tecla **M**).

| Qué quieres hacer | Windows | Mac |
|---|---|---|
| Añadir una parada | **Alt + clic** en el mapa | **⌥ Opción + clic** |
| Añadir una parada con el nombre de un icono *(espera a que salga su tooltip)* | **Alt + clic** sobre el icono | **⌥ + clic** sobre el icono |
| Ir solo a ese punto (borra las demás paradas) | **Alt + Mayús + clic** | **⌥ + ⇧ + clic** |
| Quitar una parada | **Alt + clic** sobre ella | **⌥ + clic** sobre ella |
| Mover una parada | **Alt + arrastrar** | **⌥ + arrastrar** |
| Menú de la parada (editar nombre y descripción, compartir, quitar) | **Alt + clic derecho** | **⌥ + clic con dos dedos** |
| Ver nombre, distancia y coordenadas | Pasar el ratón por encima | Igual |

Al añadir una parada sale una cajita con un nombre propuesto: **Intro** acepta (o escribe otro), **Esc** cancela.

> En Mac, **Ctrl** es la tecla Control (⌃), no Comando (⌘). `Ctrl + clic` pone el pin normal del juego, que Bridge no toca.

#### Botón "Bridge"

Está arriba a la derecha del mapa del mundo. Haz clic para abrir su menú:

* **Activar modo ruta**: mientras está activo (el botón brilla en verde), basta un clic normal para añadir paradas. Se desactiva al cerrar el mapa.
* **Gestionar rutas…**: a la izquierda, tus rutas (la activa lleva el botón de opción en verde: pulsa el de otra para activarla); a la derecha, las paradas de la ruta que elijas. **Nueva ruta** (bajo la lista) pide un nombre y crea una ruta vacía; el icono ✎ junto al nombre de la ruta la renombra, + la duplica (una copia con todas sus paradas) y ✕ la borra con sus paradas (tras confirmarlo; la última ruta no se puede borrar, y si borras la activa se activa otra). Al activar una ruta, la brújula, el mapa, el minimapa y AzerothGPS pasan a seguirla, empezando por su primera parada. Puedes buscarlas por nombre o zona, ir a una en el mapa (su pin parpadea), editar su nombre y descripción, quitarla y cambiar el orden con ▲▼ o arrastrando las filas. Para mover una parada a otra ruta, arrástrala sobre esa ruta en la lista de la izquierda, o haz clic derecho sobre ella y elige **Mover a**. El menú del clic derecho tiene también **Editar nombre y descripción**. El botón **Importar lista /way** abre un cuadro donde puedes pegar muchas líneas `/way` a la vez: cada una se convierte en una parada, en orden (con o sin `/way` delante). Las líneas que repiten una parada que ya tienes se saltan, y puedes marcar una casilla para borrar antes tus paradas actuales.
* **Borrar paradas** ▸ **De la zona** (la que se ve en el mapa) o **Todas**.
* **Unidades** ▸ **Yardas** o **Metros**. De entrada, metros (yardas si el juego está en inglés de EE. UU.).
* **Mostrar brújula** (desactivada de entrada).
* **Aviso al llegar** (activado de entrada): el cartel, la línea en el chat y el sonido. Desactívalo para llegar a las paradas sin avisos: la ruta sigue avanzando.
* **Pedir nombre al añadir** (activado de entrada). La caja tiene además un campo opcional de **Descripción** (Tab para pasar a él); la descripción sale en el tooltip de la parada en el mapa y el minimapa. Puedes añadirla o cambiarla después con **Editar nombre y descripción**.

Para mover el botón: **Mayús + arrastrar** (`/bridge button reset` lo devuelve a su sitio).

#### Brújula y llegada

La brújula apunta en línea recta a la siguiente parada (la número 1) y muestra su nombre, cuántas quedan, la distancia y el tiempo estimado de llegada, calculado según lo rápido que te acercas; no aparece si estás parado o te alejas. Arrástrala para moverla. Cuando estás a menos de 10 yardas, la parada queda marcada como alcanzada (sigue guardada en su ruta), sale el aviso (si está activado) y la brújula pasa a la siguiente. Tras la última, el aviso dice que la ruta está completada. Es la brújula la que detecta la llegada: si está desactivada, la ruta no avanza.

#### Tu cadáver

Si mueres y liberas el espíritu, lo primero que necesitas es volver a por tu cuerpo. Por eso Bridge añade tu cadáver como **primera parada**: la brújula te lleva hasta él y, cuando resucitas, la parada desaparece y sigues con las paradas que ya tenías, en el mismo orden. Da igual cómo resucites: en el cadáver, con el ángel o porque te resucita otro jugador. Si mueres dentro de una mazmorra no se añade.

---

### ⌨️ Comandos

Casi todo se hace desde el mapa y el botón. Los comandos se escriben siempre en inglés.

| Comando | Qué hace |
|---|---|
| `/bridge` | Ayuda. |
| `/bridge manage` | Abrir la ventana "Gestionar rutas". |
| `/bridge import` | Pegar una lista de líneas `/way` para añadirlas como paradas. |
| `/bridge clear` | Borrar todas las paradas. |
| `/bridge markers` | Mostrar u ocultar los marcadores (mapa y minimapa). |
| `/bridge size N` | Tamaño de los marcadores, de 30 a 200 (%). |
| `/bridge button` | Mostrar u ocultar el botón del mapa. |
| `/bridge button reset` | Devolver el botón a su sitio. |
| `/bridge version` | Ver la versión instalada. |
| `/way zona x y nombre` | Añadir una parada (p. ej. `/way Bosque de Elwynn 42 65 Villadorada`). |
| `/way reset all` | Borrar todas las paradas. |
| `/way reset <zona>` | Borrar las paradas de esa zona. |
| `/way reset not <zona>` | Borrar las paradas de las demás zonas. |
| `/cway` | La parada más cercana pasa a ser la siguiente. |

---

### 🤝 Sinergias

Bridge funciona solo, pero se lleva bien con estos addons:

* **Leatrix Maps**: Bridge trabaja sobre el mapa del mundo, así que funciona igual con el mapa mejorado de Leatrix Maps.
* **Questie**: haz clic derecho en una misión del rastreador (o en uno de sus objetivos):
  * **Establecer ruta**: borra tus paradas y deja el objetivo más cercano como única parada.
  * **Añadir como parada**: añade el objetivo más cercano al final de tus paradas.
* **AzerothGPS**: cada cambio en tus paradas actualiza al momento su ruta, que va por carreteras, se dibuja en el minimapa y te da indicaciones.
  * Con AzerothGPS activo, Bridge no dibuja nada en el minimapa ni en sus ventanas: AzerothGPS ya marca las paradas. También es él quien detecta que has llegado.
  * ⚠️ **Limitación:** la información solo va de Bridge a AzerothGPS. AzerothGPS no deja que otros addons lean su ruta, así que si quitas una parada desde el mapa de AzerothGPS, Bridge no se entera. Quítalas siempre desde el mapa del mundo.
* **TomTom**: no se recomienda usarlo junto con Bridge, porque verías los puntos repetidos y cada uno llevaría su propia lista. Tampoco hace falta: muchos addons (guías de subida de nivel, buscadores de raros…) mandan sus puntos a TomTom. Si TomTom no está activado, Bridge recoge esos puntos en su lugar y los convierte en paradas, así que esos addons siguen funcionando igual.

---

### 🌍 Idiomas

* **Español**: si el juego está en español.
* **Inglés**: en cualquier otro idioma.

---

### 🧩 Para desarrolladores

* **API**: Bridge tiene una API pública, `BridgeAPI`, para que otros addons o tus macros (`/run`) creen y gestionen paradas y se enteren de sus cambios. Está documentada en [API.md](API.md).
* **Diagnóstico**: `/bridge diag` muestra el estado del addon; `/bridge debug` activa mensajes de depuración; `/bridge copy` abre una ventana con los últimos mensajes, ya seleccionados para copiarlos (**Ctrl + C**, o **⌘ + C** en Mac).
* **Datos guardados**: `World of Warcraft/<tu versión>/WTF/Account/<CUENTA>/<servidor>/<personaje>/SavedVariables/Bridge.lua`. El juego lo escribe al recargar (`/reload`) o al salir.
* **Licencia**: Bridge es *All Rights Reserved* (todos los derechos reservados): su código no se puede copiar, modificar ni volver a subir sin permiso. Usar la API pública desde tu propio addon es libre y no necesita permiso.

---

### 🐞 Comentarios y errores

¿Has encontrado un error o tienes una idea? Déjalo en los comentarios de la página del proyecto en CurseForge. Si es un error, incluye lo que muestra `/bridge diag` (sale en una ventana, listo para copiar).
