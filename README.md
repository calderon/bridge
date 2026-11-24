# Bridge

[https://www.curseforge.com/wow/addons/bridge](https://www.curseforge.com/wow/addons/bridge)

> *[Versión en español más abajo](#espanol)*

## English

**Bridge** is an addon for **building routes** on the map (*waypoints*): you mark the places you want to go, and Bridge takes you through them, one after another.

Each place you mark is a **stop**: add it with a click, give it a name and a description, and see it on the map and the minimap with its number. An on-screen compass shows you which way to go, how far it is and when you'll get there; when you arrive, it moves on to the next stop.

Stops are grouped into **routes**. The **Current route** is the one you are walking right now. Your **saved routes** (a herbalism circuit, the quests of a zone, your trainers…) stay saved and never change while you walk them: load one into the Current route whenever you want, as many times as you like, and share it with all your characters if you wish.

### ✨ Features

* **Stops on the world map**: add, move, rename and remove them with the mouse.
* **Routes**: save as many as you like and load one into the Current route with a click; walking a route never changes the saved one. The stops you reach turn grey until you restart the route.
* **Shared routes**: share a saved route with all the characters of your account; each one walks it on its own.
* **Descriptions**: give a stop an optional description; it shows in its tooltip on the map and the minimap.
* **Names**: each stop can have its own; drop a stop on a map icon and it takes the icon's name.
* **Minimap**: stops also show while you walk; far-away ones sit on the edge, pointing the way.
* **Compass**: an on-screen arrow with the next stop's name, distance and estimated time of arrival.
* **Arrival notice**: an on-screen banner, *"You have arrived at… · Next stop: …"*, with a line in chat and a sound. It can be turned off.
* **Your corpse**: when you die and release your spirit, the compass takes you to your body first; the stop goes away when you resurrect.
* **Manage routes**: a window with all your routes and their stops: create, rename, duplicate, delete, search, reorder, and move or copy stops between routes.
* **Sharing**: send a stop to your party, raid or guild; players with Bridge can add it with one click.
* **`/way` commands**: type coordinates in chat and they become stops.
* **Import stops**: paste a list of `/way` lines from a guide or website and they all become stops, in order.
* **Yards or meters**, your choice.
* **Everything is saved** between sessions.

---

### ⚙️ Installation

**With the CurseForge app (recommended):** search for **Bridge** in the CurseForge app, under World of Warcraft (WoW Forever), and click **Install**. The app keeps it up to date.

**By hand:**

1. Close the game.
2. Download the zip from the CurseForge page and copy the `Bridge` folder into `World of Warcraft/<your version>/Interface/AddOns/`. *(On WoW Forever, `<your version>` is the Forever folder, for example `_forever_`).*
   * **On Mac**, the folder is usually in `/Applications/World of Warcraft/`. If you can't find it: Battle.net app → game's gear icon → **Show in Finder**.
3. Start the game. The chat should show: `Bridge: Version … loaded`.

> **Note:** if the game flags it as "out of date", type `/dump select(4, GetBuildInfo())` and put that number on the `## Interface:` line of the `Bridge.toc` file.

---

### 🔄 Migration from v1

Version 2 organizes stops into routes. When you update from 1.x, **you don't lose anything**:

* Your stops become a saved route called **"My route"**, which is also loaded into the **Current route**, so you carry on where you were.
* The **"Keep stops between sessions"** option is gone: routes are always saved. To start from scratch, empty the Current route (Bridge button → **Empty Current route**).
* "Manage stops" is now **Manage routes**, and "Clear stops" is now **Empty Current route**.
* Your stops are converted the first time you log in with each character. If you go back to a 1.x version afterwards, it won't show them.

---

### 🖱️ Usage

Open the world map (**M** key).

| What you want to do | Windows | Mac |
|---|---|---|
| Add a stop | **Alt + click** on the map | **⌥ Option + click** |
| Add a stop named after a map icon *(wait for its tooltip)* | **Alt + click** on the icon | **⌥ + click** on the icon |
| Go only to that point (empties the Current route) | **Alt + Shift + click** | **⌥ + ⇧ + click** |
| Remove a stop | **Alt + click** on it | **⌥ + click** on it |
| Move a stop | **Alt + drag** | **⌥ + drag** |
| Stop menu (edit name and description, share, remove) | **Alt + right-click** | **⌥ + two-finger click** |
| See name, distance and coordinates | Hover over it | Same |

When you add a stop, a small box shows a suggested name: **Enter** accepts it (or type another one), **Esc** cancels.

> On Mac, **Ctrl** is the Control key (⌃), not Command (⌘). `Ctrl + click` places the game's own map pin, which Bridge leaves alone.

#### "Bridge" button

It sits at the top right of the world map. Click it to open its menu:

* **Turn on route mode**: while it is on (the button glows green), a plain click adds stops. It turns off when you close the map.
* **Manage routes…**: on the left, your routes (the Current route first, then the saved ones in alphabetical order); on the right, the stops of the route you select (each with its zone and coordinates and, below, its description).
  * The **Current route** is always first (with the compass icon): it is the route the compass, the map, the minimap and AzerothGPS follow. Stops you reach turn grey; ⟳ restarts it. It can't be renamed or deleted. Stops from `/way`, Questie, other addons and other players also go here; actions that "go only there" (Questie's "Set route", Alt+Shift+click) empty it first, but never a saved route, and your corpse stays.
  * Your **saved routes** are templates: they never change while you walk. Click a route's **▶** to **load** it into the Current route: its stops replace the ones there (it asks first if there were any; your corpse stays) and you start from its first stop. The ▶ of the last route you loaded stays green. Changes you make in the Current route are temporary; to keep them, duplicate it (+).
  * **Shared with my characters** (checkbox under a saved route's stops): the route is seen and edited by all the characters of your account, and shows in blue in the list. What each character walks is still its own, in its Current route. Unsharing it (after confirming) keeps it only for this character.
  * While this window is open, **Alt+click** on the map adds the stop to the saved route you have selected (with the window closed, or with the Current route selected, it goes to the Current route). **Alt+Shift+click** always goes to the Current route.
  * **New route** (under the list) asks for a name and an optional description (shown when you hover the route in the list) and creates an empty route. Next to the route's name: + duplicates it (a copy with all its stops); on the Current route, ⟳ restarts it and ✕ empties it (after confirming); on a saved route, ✎ edits its name and description and ✕ deletes it with its stops (after confirming).
  * The search box on top looks in route names and in the stops of every route (name, description and zone): the list shows the matching routes (e.g. (2/5): 2 of its 5 stops match), and matches are highlighted in gold.
  * Jump to a stop on the map (its pin flashes), edit its name and description, remove it, and reorder with ▲▼ or by dragging rows. To move a stop to another route, drag it onto that route in the list on the left, or right-click it and choose **Move to**. To copy it instead (the original stays), hold Shift when you drop it, or choose **Copy to**. The right-click menu also has **Edit name and description** and, at the end, **Remove**.
  * Two buttons at the top right: **Export route** (arrow going up) shows the route as a list of `/way` lines ready to copy (with the map number instead of the zone name, so it works in any game language; descriptions are not included). **Import stops** (arrow going down) opens a box where you can paste many `/way` lines at once: each one becomes a stop, in order (with or without `/way` in front). Lines repeating a stop you already have are skipped, and you can tick a box to clear the route's stops first, or **Import as a new route** (if the text starts with `# Bridge: <name>`, as exported routes do, that name is suggested and the box is ticked for you). Lines starting with `#` are ignored.
* **Empty Current route** (it asks first). Saved routes are never emptied from here, and your corpse stays.
* **Units** ▸ **Yards** or **Meters**. Meters by default (yards if the game is in US English).
* **Show compass** (off by default).
* **Arrival notice** (on by default): the banner, the chat line and the sound. Turn it off to reach stops silently: the route still advances.
* **Ask for a name when adding** (on by default). The box also has an optional **Description** field (Tab to move to it); the description shows in the stop's tooltip on the map and the minimap. You can add or change it later with **Edit name and description**.

To move the button: **Shift + drag** (`/bridge button reset` puts it back).

#### Compass and arrival

The compass points in a straight line to the next stop you haven't reached yet and shows, above the stop's name, the route you loaded and your position in it (e.g. Herbalism · 3/12; it says "(modified)" if the Current route no longer matches it), then the distance and the estimated time of arrival (ETA), worked out from how fast you are getting closer; it is hidden while you are standing still or moving away. Drag it to move it. Within 10 yards, the stop is marked as reached (it stays saved in its route and turns grey on the map, the minimap and the Manage routes list until you restart the route), the arrival notice shows up (if turned on) and the compass moves on to the next stop. After the last one, the notice says the route is completed. The compass is what detects your arrival: if it is turned off, the route doesn't advance.

#### Your corpse

If you die and release your spirit, the first thing you need is to get back to your body. So Bridge adds your corpse as the **first stop** (it is kept in the Current route, and the compass and AzerothGPS take you there first): the compass takes you to it and, when you resurrect, the stop goes away and you carry on with the stops you already had, in the same order. It doesn't matter how you resurrect: at your corpse, at the spirit healer, or when another player resurrects you. It is not added if you die inside a dungeon.

---

### ⌨️ Commands

Almost everything is done from the map and the button.

| Command | Result |
|---|---|
| `/bridge` | Help. |
| `/bridge manage` | Open the "Manage routes" window. |
| `/bridge import` | Paste a list of `/way` lines to add them as stops. |
| `/bridge route list` | List your routes. |
| `/bridge route load <name>` | Load a saved route into the Current route (part of the name is enough if only one route matches). |
| `/bridge route new <name>` | Create an empty route. |
| `/bridge route restart` | Restart the Current route. |
| `/bridge clear` | Empty the Current route (your corpse stays). |
| `/bridge markers` | Show or hide the markers (map and minimap). |
| `/bridge size N` | Marker size, 30 to 200 (%). |
| `/bridge button` | Show or hide the map button. |
| `/bridge button reset` | Put the button back in place. |
| `/bridge version` | Check the installed version. |
| `/way zone x y name` | Add a stop to the Current route (e.g. `/way Elwynn Forest 42 65 Goldshire`). |
| `/way reset all` | Empty the Current route. |
| `/way reset <zone>` | Remove the Current route's stops in that zone. |
| `/way reset not <zone>` | Remove the Current route's stops in other zones. |
| `/cway` | The closest stop becomes the next one. |

---

### 🤝 Synergies

Bridge works on its own, but it gets along with these addons:

* **Leatrix Maps**: Bridge works on the world map, so it works just the same with Leatrix Maps' enhanced map.
* **Questie**: right-click a quest in the tracker (or one of its objectives):
  * **Set route**: empties the Current route and leaves the nearest objective as its only stop.
  * **Add as stop**: adds the nearest objective at the end of the Current route.
* **AzerothGPS**: every change to the Current route updates its route right away; it follows the roads, is drawn on the minimap and gives directions.
  * With AzerothGPS running, Bridge draws nothing on the minimap or in its windows: AzerothGPS already marks the stops. It is also the one that detects when you arrive.
  * ⚠️ **Limitation:** information only flows from Bridge to AzerothGPS. AzerothGPS does not let other addons read its route, so if you remove a stop from the AzerothGPS map, Bridge won't know. Always remove them from the world map or the Manage routes window.
* **TomTom**: using it together with Bridge is not recommended, because you would see points twice and each would keep its own list. You don't need it either: many addons (leveling guides, rare scanners…) send their points to TomTom. When TomTom is not enabled, Bridge picks up those points instead and adds them to the Current route, so those addons keep working just the same.

---

### 🌍 Languages

* **Spanish**: when the game is in Spanish.
* **English**: in any other language.

---

### 🧩 For developers

* **API**: Bridge has a public API, `BridgeAPI`, so other addons or your macros (`/run`) can create and manage stops, work with routes (version 2) and get notified of changes. It is documented in [API.md](https://github.com/calderon/bridge/blob/main/API.md).
* **Diagnostics**: `/bridge diag` shows the addon's status; `/bridge debug` turns on debug messages; `/bridge copy` opens a window with the latest messages, already selected for copying (**Ctrl + C**, or **⌘ + C** on Mac).
* **Saved data**: `World of Warcraft/<your version>/WTF/Account/<ACCOUNT>/<realm>/<character>/SavedVariables/Bridge.lua` (shared routes: `World of Warcraft/<your version>/WTF/Account/<ACCOUNT>/SavedVariables/Bridge.lua`). The game writes it when you reload (`/reload`) or log out.
* **License**: Bridge is *All Rights Reserved*: its code may not be copied, modified or re-uploaded without permission. Using the public API from your own addon is free and needs no permission.

---

### 🐞 Contact and bug reports

* **Bugs**: please report them on GitHub, at [github.com/calderon/bridge/issues](https://github.com/calderon/bridge/issues). Tell us what you did and what happened, and include the output of `/bridge diag` (it opens in a window, ready to copy).
* **Ideas and comments**: open an issue there too, or leave a comment on the CurseForge project page.

<br>

---
---

<a name="espanol"></a>
## Español


**Bridge** es un addon para **crear rutas** en el mapa (*waypoints*): marcas los sitios a los que quieres ir y Bridge te lleva por ellos, uno detrás de otro.

Cada sitio que marcas es una **parada**: la pones con un clic, le das un nombre y una descripción, y la ves en el mapa y en el minimapa con su número. Una brújula en pantalla te indica hacia dónde ir, a qué distancia está y cuándo llegarás; al llegar, pasa a la siguiente parada.

Las paradas se agrupan en **rutas**. La **Ruta actual** es la que estás recorriendo ahora. Tus **rutas guardadas** (un circuito de herboristería, las misiones de una zona, tus instructores…) se quedan guardadas y no cambian al recorrerlas: carga una en la Ruta actual cuando quieras, tantas veces como quieras, y compártela con todos tus personajes si te apetece.

### ✨ Funciones

* **Paradas en el mapa del mundo**: añadir, mover, renombrar y quitar con el ratón.
* **Rutas**: guarda todas las que quieras y carga una en la Ruta actual con un clic; recorrer una ruta nunca cambia la guardada. Las paradas a las que llegas se ponen en gris hasta que reinicias la ruta.
* **Rutas compartidas**: comparte una ruta guardada con todos los personajes de tu cuenta; cada uno la recorre por su cuenta.
* **Descripciones**: añade a una parada una descripción opcional; sale en su tooltip del mapa y del minimapa.
* **Nombres**: cada parada puede tener el suyo; si pones la parada sobre un icono del mapa, toma su nombre.
* **Minimapa**: las paradas también se ven al ir caminando; las lejanas se quedan en el borde, señalando hacia dónde están.
* **Brújula**: flecha en pantalla con el nombre de la siguiente parada, la distancia y el tiempo estimado de llegada.
* **Aviso al llegar**: un cartel en pantalla, *"Has llegado a… · Siguiente parada: …"*, con una línea en el chat y un sonido. Se puede desactivar.
* **Tu cadáver**: al morir y liberar el espíritu, la brújula te lleva primero a tu cuerpo; la parada se quita al resucitar.
* **Gestionar rutas**: una ventana con todas tus rutas y sus paradas: crear, renombrar, duplicar, borrar, buscar, ordenar, y mover o copiar paradas entre rutas.
* **Compartir**: manda una parada a tu grupo, banda o hermandad; quien tenga Bridge puede añadirla con un clic.
* **Comandos `/way`**: escribe coordenadas en el chat y se convierten en paradas.
* **Importar paradas**: pega una lista de líneas `/way` de una guía o una web y todas se convierten en paradas, en orden.
* **Yardas o metros**, a tu elección.
* **Todo se guarda** entre sesiones.

---

### ⚙️ Instalación

**Con la app de CurseForge (recomendado):** busca **Bridge** en la app de CurseForge, dentro de World of Warcraft (WoW Forever), y pulsa **Instalar**. La app lo mantiene al día.

**A mano:**

1. Cierra el juego.
2. Descarga el zip desde la página de CurseForge y copia la carpeta `Bridge` en `World of Warcraft/<tu versión>/Interface/AddOns/`. *(En WoW Forever, `<tu versión>` es la carpeta de Forever, por ejemplo `_forever_`).*
   * **En Mac**, la carpeta suele estar en `/Aplicaciones/World of Warcraft/`. Si no la encuentras: app de Battle.net → rueda dentada del juego → **Mostrar en el Finder**.
3. Abre el juego. En el chat debe aparecer: `Bridge: Versión … cargada`.

> **Nota:** si el juego lo marca como "desactualizado", escribe `/dump select(4, GetBuildInfo())` y pon ese número en la línea `## Interface:` del archivo `Bridge.toc`.

---

### 🔄 Migración desde la v1

La versión 2 organiza las paradas en rutas. Al actualizar desde la 1.x **no pierdes nada**:

* Tus paradas pasan a una ruta guardada llamada **"Mi ruta"**, que además se carga en la **Ruta actual**, así que sigues por donde ibas.
* Desaparece la opción **"Guardar paradas entre sesiones"**: las rutas se guardan siempre. Para empezar de cero, vacía la Ruta actual (botón Bridge → **Vaciar Ruta actual**).
* "Gestionar paradas" ahora es **Gestionar rutas**, y "Borrar paradas" ahora es **Vaciar Ruta actual**.
* Tus paradas se convierten la primera vez que entras con cada personaje. Si después vuelves a una versión 1.x, no las verá.

---

### 🖱️ Uso

Abre el mapa del mundo (tecla **M**).

| Qué quieres hacer | Windows | Mac |
|---|---|---|
| Añadir una parada | **Alt + clic** en el mapa | **⌥ Opción + clic** |
| Añadir una parada con el nombre de un icono *(espera a que salga su tooltip)* | **Alt + clic** sobre el icono | **⌥ + clic** sobre el icono |
| Ir solo a ese punto (vacía la Ruta actual) | **Alt + Mayús + clic** | **⌥ + ⇧ + clic** |
| Quitar una parada | **Alt + clic** sobre ella | **⌥ + clic** sobre ella |
| Mover una parada | **Alt + arrastrar** | **⌥ + arrastrar** |
| Menú de la parada (editar nombre y descripción, compartir, quitar) | **Alt + clic derecho** | **⌥ + clic con dos dedos** |
| Ver nombre, distancia y coordenadas | Pasar el ratón por encima | Igual |

Al añadir una parada sale una cajita con un nombre propuesto: **Intro** acepta (o escribe otro), **Esc** cancela.

> En Mac, **Ctrl** es la tecla Control (⌃), no Comando (⌘). `Ctrl + clic` pone el pin normal del juego, que Bridge no toca.

#### Botón "Bridge"

Está arriba a la derecha del mapa del mundo. Haz clic para abrir su menú:

* **Activar modo ruta**: mientras está activo (el botón brilla en verde), basta un clic normal para añadir paradas. Se desactiva al cerrar el mapa.
* **Gestionar rutas…**: a la izquierda, tus rutas (la Ruta actual la primera y después las guardadas por orden alfabético); a la derecha, las paradas de la ruta que elijas (cada una con su zona y coordenadas y, debajo, su descripción).
  * La **Ruta actual** va siempre la primera (con el icono de la brújula): es la que siguen la brújula, el mapa, el minimapa y AzerothGPS. Las paradas a las que llegas se ponen en gris; ⟳ la reinicia. No se puede renombrar ni borrar. Las paradas de `/way`, Questie, otros addons y otros jugadores también van aquí; las acciones de "ir solo ahí" ("Establecer ruta" de Questie, Alt+Mayús+clic) la vacían antes, pero nunca una ruta guardada, y tu cadáver se queda.
  * Tus **rutas guardadas** son plantillas: no cambian mientras las recorres. Pulsa el **▶** de una ruta para **cargarla** en la Ruta actual: sus paradas sustituyen a las que hubiera (pregunta antes si había alguna; tu cadáver se queda) y empiezas por su primera parada. El ▶ de la última ruta que cargaste se queda en verde. Lo que cambies en la Ruta actual es temporal; para conservarlo, duplícala (+).
  * **Compartida con mis personajes** (casilla bajo las paradas de una ruta guardada): la ruta la ven y editan todos los personajes de tu cuenta, y sale en azul en la lista. Lo que recorre cada personaje sigue siendo suyo, en su Ruta actual. Al dejar de compartirla (tras confirmarlo), se queda solo para este personaje.
  * Con esta ventana abierta, **Alt+clic** en el mapa añade la parada a la ruta guardada que tengas elegida (con la ventana cerrada, o con la Ruta actual elegida, va a la Ruta actual). **Alt+Mayús+clic** va siempre a la Ruta actual.
  * **Nueva ruta** (bajo la lista) pide un nombre y una descripción opcional (sale al pasar el ratón por la ruta en la lista) y crea una ruta vacía. Junto al nombre de la ruta: + la duplica (una copia con todas sus paradas); en la Ruta actual, ⟳ la reinicia y ✕ la vacía (tras confirmarlo); en una ruta guardada, ✎ edita su nombre y descripción y ✕ la borra con sus paradas (tras confirmarlo).
  * El buscador de arriba mira en los nombres de las rutas y en las paradas de todas ellas (nombre, descripción y zona): la lista muestra las rutas que coinciden (p. ej. (2/5): coinciden 2 de sus 5 paradas) y las coincidencias se resaltan en dorado.
  * Puedes ir a una parada en el mapa (su pin parpadea), editar su nombre y descripción, quitarla y cambiar el orden con ▲▼ o arrastrando las filas. Para mover una parada a otra ruta, arrástrala sobre esa ruta en la lista de la izquierda, o haz clic derecho sobre ella y elige **Mover a**. Para copiarla (la original se queda), mantén pulsada Mayús al soltarla, o elige **Copiar a**. El menú del clic derecho tiene también **Editar nombre y descripción** y, al final, **Quitar**.
  * Dos botones arriba a la derecha: **Exportar ruta** (flecha hacia arriba) muestra la ruta como una lista de líneas `/way` lista para copiar (con el número de mapa en vez del nombre de la zona, para que sirva en cualquier idioma del juego; sin las descripciones). **Importar paradas** (flecha hacia abajo) abre un cuadro donde puedes pegar muchas líneas `/way` a la vez: cada una se convierte en una parada, en orden (con o sin `/way` delante). Las líneas que repiten una parada que ya tienes se saltan, y puedes marcar una casilla para borrar antes las paradas de la ruta, o **Importar como ruta nueva** (si el texto empieza por `# Bridge: <nombre>`, como las rutas exportadas, se propone ese nombre y la casilla se marca sola). Las líneas que empiezan por `#` se ignoran.
* **Vaciar Ruta actual** (pregunta antes). Desde aquí nunca se vacía una ruta guardada, y tu cadáver se queda.
* **Unidades** ▸ **Yardas** o **Metros**. De entrada, metros (yardas si el juego está en inglés de EE. UU.).
* **Mostrar brújula** (desactivada de entrada).
* **Aviso al llegar** (activado de entrada): el cartel, la línea en el chat y el sonido. Desactívalo para llegar a las paradas sin avisos: la ruta sigue avanzando.
* **Pedir nombre al añadir** (activado de entrada). La caja tiene además un campo opcional de **Descripción** (Tab para pasar a él); la descripción sale en el tooltip de la parada en el mapa y el minimapa. Puedes añadirla o cambiarla después con **Editar nombre y descripción**.

Para mover el botón: **Mayús + arrastrar** (`/bridge button reset` lo devuelve a su sitio).

#### Brújula y llegada

La brújula apunta en línea recta a la siguiente parada a la que aún no has llegado y muestra, sobre el nombre de la parada, la ruta que cargaste y en qué parada vas (p. ej. Herboristería · 3/12; pone "(modificada)" si la Ruta actual ya no coincide con ella), y después la distancia y el tiempo estimado de llegada, calculado según lo rápido que te acercas; no aparece si estás parado o te alejas. Arrástrala para moverla. Cuando estás a menos de 10 yardas, la parada queda marcada como alcanzada (sigue guardada en su ruta y se ve en gris en el mapa, el minimapa y la lista de Gestionar rutas hasta que reinicies la ruta), sale el aviso (si está activado) y la brújula pasa a la siguiente. Tras la última, el aviso dice que la ruta está completada. Es la brújula la que detecta la llegada: si está desactivada, la ruta no avanza.

#### Tu cadáver

Si mueres y liberas el espíritu, lo primero que necesitas es volver a por tu cuerpo. Por eso Bridge añade tu cadáver como **primera parada** (se guarda en la Ruta actual, y la brújula y AzerothGPS te llevan primero a él): la brújula te lleva hasta él y, cuando resucitas, la parada desaparece y sigues con las paradas que ya tenías, en el mismo orden. Da igual cómo resucites: en el cadáver, con el ángel o porque te resucita otro jugador. Si mueres dentro de una mazmorra no se añade.

---

### ⌨️ Comandos

Casi todo se hace desde el mapa y el botón. Los comandos se escriben siempre en inglés.

| Comando | Qué hace |
|---|---|
| `/bridge` | Ayuda. |
| `/bridge manage` | Abrir la ventana "Gestionar rutas". |
| `/bridge import` | Pegar una lista de líneas `/way` para añadirlas como paradas. |
| `/bridge route list` | Ver tus rutas. |
| `/bridge route load <nombre>` | Cargar una ruta guardada en la Ruta actual (basta con parte del nombre si solo coincide una ruta). |
| `/bridge route new <nombre>` | Crear una ruta vacía. |
| `/bridge route restart` | Reiniciar la Ruta actual. |
| `/bridge clear` | Vaciar la Ruta actual (tu cadáver se queda). |
| `/bridge markers` | Mostrar u ocultar los marcadores (mapa y minimapa). |
| `/bridge size N` | Tamaño de los marcadores, de 30 a 200 (%). |
| `/bridge button` | Mostrar u ocultar el botón del mapa. |
| `/bridge button reset` | Devolver el botón a su sitio. |
| `/bridge version` | Ver la versión instalada. |
| `/way zona x y nombre` | Añadir una parada a la Ruta actual (p. ej. `/way Bosque de Elwynn 42 65 Villadorada`). |
| `/way reset all` | Vaciar la Ruta actual. |
| `/way reset <zona>` | Quitar las paradas de la Ruta actual en esa zona. |
| `/way reset not <zona>` | Quitar las paradas de la Ruta actual en las demás zonas. |
| `/cway` | La parada más cercana pasa a ser la siguiente. |

---

### 🤝 Sinergias

Bridge funciona solo, pero se lleva bien con estos addons:

* **Leatrix Maps**: Bridge trabaja sobre el mapa del mundo, así que funciona igual con el mapa mejorado de Leatrix Maps.
* **Questie**: haz clic derecho en una misión del rastreador (o en uno de sus objetivos):
  * **Establecer ruta**: vacía la Ruta actual y deja el objetivo más cercano como su única parada.
  * **Añadir como parada**: añade el objetivo más cercano al final de la Ruta actual.
* **AzerothGPS**: cada cambio en la Ruta actual actualiza al momento su ruta, que va por carreteras, se dibuja en el minimapa y te da indicaciones.
  * Con AzerothGPS activo, Bridge no dibuja nada en el minimapa ni en sus ventanas: AzerothGPS ya marca las paradas. También es él quien detecta que has llegado.
  * ⚠️ **Limitación:** la información solo va de Bridge a AzerothGPS. AzerothGPS no deja que otros addons lean su ruta, así que si quitas una parada desde el mapa de AzerothGPS, Bridge no se entera. Quítalas siempre desde el mapa del mundo o desde la ventana Gestionar rutas.
* **TomTom**: no se recomienda usarlo junto con Bridge, porque verías los puntos repetidos y cada uno llevaría su propia lista. Tampoco hace falta: muchos addons (guías de subida de nivel, buscadores de raros…) mandan sus puntos a TomTom. Si TomTom no está activado, Bridge recoge esos puntos en su lugar y los añade a la Ruta actual, así que esos addons siguen funcionando igual.

---

### 🌍 Idiomas

* **Español**: si el juego está en español.
* **Inglés**: en cualquier otro idioma.

---

### 🧩 Para desarrolladores

* **API**: Bridge tiene una API pública, `BridgeAPI`, para que otros addons o tus macros (`/run`) creen y gestionen paradas, trabajen con rutas (versión 2) y se enteren de sus cambios. Está documentada en [API.md](https://github.com/calderon/bridge/blob/main/API.md).
* **Diagnóstico**: `/bridge diag` muestra el estado del addon; `/bridge debug` activa mensajes de depuración; `/bridge copy` abre una ventana con los últimos mensajes, ya seleccionados para copiarlos (**Ctrl + C**, o **⌘ + C** en Mac).
* **Datos guardados**: `World of Warcraft/<tu versión>/WTF/Account/<CUENTA>/<servidor>/<personaje>/SavedVariables/Bridge.lua` (rutas compartidas: `World of Warcraft/<tu versión>/WTF/Account/<CUENTA>/SavedVariables/Bridge.lua`). El juego lo escribe al recargar (`/reload`) o al salir.
* **Licencia**: Bridge es *All Rights Reserved* (todos los derechos reservados): su código no se puede copiar, modificar ni volver a subir sin permiso. Usar la API pública desde tu propio addon es libre y no necesita permiso.

---

### 🐞 Contacto y errores

* **Errores**: repórtalos en GitHub, en [github.com/calderon/bridge/issues](https://github.com/calderon/bridge/issues). Cuenta qué hiciste y qué pasó, e incluye lo que muestra `/bridge diag` (sale en una ventana, listo para copiar).
* **Ideas y comentarios**: abre también una issue allí, o déjalo en los comentarios de la página del proyecto en CurseForge.
