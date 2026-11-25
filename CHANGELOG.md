# Changelog

## [2.0.0](https://github.com/calderon/bridge/compare/v1.2.0...v2.0.0) (2026-11-25)


### ⚠ BREAKING CHANGES

* saved data moves from a single stop list to routes. Going back to 1.x after updating will not show the saved stops.

### Features

* activate a route from its radio button in Manage routes ([17de6c1](https://github.com/calderon/bridge/commit/17de6c1c8f6682f32e328354d20861a483b3b455)), closes [#35](https://github.com/calderon/bridge/issues/35)
* add /bridge route commands ([cf72128](https://github.com/calderon/bridge/commit/cf7212869c79d31860c9ac0b1ceda5cabed8e8a9)), closes [#45](https://github.com/calderon/bridge/issues/45)
* add a Quick route for temporary stops ([ccea238](https://github.com/calderon/bridge/commit/ccea238996023e2a97d3ef29d42295c6e471bff2)), closes [#41](https://github.com/calderon/bridge/issues/41)
* add an optional description to routes ([9bf136b](https://github.com/calderon/bridge/commit/9bf136bd4fbbc00fe1d5b9b26e1cc66dffdeafe4)), closes [#92](https://github.com/calderon/bridge/issues/92)
* add routes to the public API ([8efb331](https://github.com/calderon/bridge/commit/8efb3317298e1d21375f7ee002ad8bcd440ebab0)), closes [#46](https://github.com/calderon/bridge/issues/46)
* add stops to the route selected in Manage routes ([6688095](https://github.com/calderon/bridge/commit/66880957d3a77fd24d169f139b9de5d6393e13a8)), closes [#43](https://github.com/calderon/bridge/issues/43)
* advance the route on arrival instead of deleting the stop ([7334b6d](https://github.com/calderon/bridge/commit/7334b6da2f764c4d44a965b7403bea99626c9e51)), closes [#25](https://github.com/calderon/bridge/issues/25)
* close Manage routes together with the world map ([c97a1ec](https://github.com/calderon/bridge/commit/c97a1ececb05b45bc90810469a49650d02721838)), closes [#104](https://github.com/calderon/bridge/issues/104)
* copy a stop to another route in Manage routes ([fc882b4](https://github.com/calderon/bridge/commit/fc882b4764c84911974d3db40a5abe9cfd6e45c9)), closes [#37](https://github.com/calderon/bridge/issues/37)
* create routes from the Manage routes window ([be88bad](https://github.com/calderon/bridge/commit/be88bad9571da647e54fba373137c521269fce07)), closes [#30](https://github.com/calderon/bridge/issues/30)
* delete routes from the Manage routes window ([feb5ec6](https://github.com/calderon/bridge/commit/feb5ec68c498ad922d528becda338a81e344b433)), closes [#32](https://github.com/calderon/bridge/issues/32)
* duplicate routes from the Manage routes window ([2c4db26](https://github.com/calderon/bridge/commit/2c4db266d34848ca9765f947a49f8b0a484ec92b)), closes [#33](https://github.com/calderon/bridge/issues/33)
* edit a stop from its context menu in Manage routes ([bf603e7](https://github.com/calderon/bridge/commit/bf603e7f5329b0c687ccfa60477169ac36f0ebe1)), closes [#61](https://github.com/calderon/bridge/issues/61)
* empty the Current route from the Bridge menu and Manage routes ([db3d704](https://github.com/calderon/bridge/commit/db3d704e75938cec67f931cf343abb56d619cc40)), closes [#49](https://github.com/calderon/bridge/issues/49)
* export a route as a list of /way lines ([e920ebb](https://github.com/calderon/bridge/commit/e920ebbf4e068e53717aaf6239c42e87babeb9b4)), closes [#90](https://github.com/calderon/bridge/issues/90)
* import a /way list as a new route ([010318a](https://github.com/calderon/bridge/commit/010318af4f879ebea72237729555335aadd4afdc)), closes [#91](https://github.com/calderon/bridge/issues/91)
* keep your corpse stop in the Quick route ([89f78f9](https://github.com/calderon/bridge/commit/89f78f9c1fc7e2c6804a5efd5dab3df3c09d63fe)), closes [#71](https://github.com/calderon/bridge/issues/71)
* keep your corpse when the Current route is emptied ([42fe3d1](https://github.com/calderon/bridge/commit/42fe3d160e45e93449bbf567479c8127c17a1809)), closes [#42](https://github.com/calderon/bridge/issues/42)
* let BridgeAPI.CreateRoute take an optional description ([2f1b9e8](https://github.com/calderon/bridge/commit/2f1b9e8674d23058447e530e88c41c23e96680b9)), closes [#107](https://github.com/calderon/bridge/issues/107)
* load saved routes into the Current route ([e3dbf3a](https://github.com/calderon/bridge/commit/e3dbf3ad732260032876fc69706cf876539622fe)), closes [#75](https://github.com/calderon/bridge/issues/75)
* make the loaded route's play button bright green ([63022f0](https://github.com/calderon/bridge/commit/63022f0fe5c5300d635b9d4c623e7a43053d7000)), closes [#87](https://github.com/calderon/bridge/issues/87)
* make the route icons in Manage routes the same size as the buttons ([c4570db](https://github.com/calderon/bridge/commit/c4570db895da1f7494b4a36a6a3d77859d8328c0)), closes [#96](https://github.com/calderon/bridge/issues/96)
* move a stop to another route in Manage routes ([e31e321](https://github.com/calderon/bridge/commit/e31e3214356b94ffbcf83569cbf85d104a787b92)), closes [#36](https://github.com/calderon/bridge/issues/36)
* move New route to a + button above the routes list ([1c7d50f](https://github.com/calderon/bridge/commit/1c7d50f3e52c5e62cc9bf112aea0646f220b0cd4)), closes [#96](https://github.com/calderon/bridge/issues/96)
* remove a stop from its context menu in Manage routes ([d32c393](https://github.com/calderon/bridge/commit/d32c393d263545389ab96fb5302152845f54557b)), closes [#62](https://github.com/calderon/bridge/issues/62)
* rename "Import /way list" to "Import stops" ([7948a34](https://github.com/calderon/bridge/commit/7948a3496b828b2580ade2526077690f0e917ea1)), closes [#82](https://github.com/calderon/bridge/issues/82)
* rename routes from the Manage routes window ([2e223bf](https://github.com/calderon/bridge/commit/2e223bfb3398c17a5ca4cd4e226d591ec607d1c0)), closes [#31](https://github.com/calderon/bridge/issues/31)
* reorder stops by a drag handle and show the zone under the name ([6d117fa](https://github.com/calderon/bridge/commit/6d117fab50d857a451d6b43d764859b9011690fb)), closes [#96](https://github.com/calderon/bridge/issues/96)
* replace Manage stops with a Manage routes window ([b617894](https://github.com/calderon/bridge/commit/b6178946ec998521b565b79abfb7e4095ad31949)), closes [#29](https://github.com/calderon/bridge/issues/29)
* restart a route from the Manage routes window ([9e5e615](https://github.com/calderon/bridge/commit/9e5e615fd4191ebeb13c15a4dc15f081eca651ec)), closes [#27](https://github.com/calderon/bridge/issues/27)
* save waypoints in permanent routes ([d56f5d4](https://github.com/calderon/bridge/commit/d56f5d455cc61fdf998fac4ed22f4e59615ca8e8)), closes [#22](https://github.com/calderon/bridge/issues/22)
* search routes and stops in Manage routes ([e047875](https://github.com/calderon/bridge/commit/e047875e4ddadbd99d80d51e494b2f8bbe34c3ec)), closes [#50](https://github.com/calderon/bridge/issues/50)
* share a saved route with your characters from Manage routes ([1ae94ed](https://github.com/calderon/bridge/commit/1ae94edcd07f9c421d156f4d5a60d18604e031d4)), closes [#34](https://github.com/calderon/bridge/issues/34)
* share a whole route with your party, raid, guild or target ([dc91068](https://github.com/calderon/bridge/commit/dc91068569df790046a0ff7daa5882c70aab5ee3)), closes [#89](https://github.com/calderon/bridge/issues/89)
* show reached stops in grey until the route is restarted ([87a0fc1](https://github.com/calderon/bridge/commit/87a0fc107e20dce00425c9be8397196702126266)), closes [#26](https://github.com/calderon/bridge/issues/26)
* show stop descriptions in the Manage routes list ([c1c8640](https://github.com/calderon/bridge/commit/c1c86406857dc6bedcbc8d0355433e1c6f1e5ddc)), closes [#64](https://github.com/calderon/bridge/issues/64)
* show the route you are walking on the compass ([0eea9bf](https://github.com/calderon/bridge/commit/0eea9bfda803c4cc1197601d59b02ff64ec34085)), closes [#39](https://github.com/calderon/bridge/issues/39)
* split Import and Export into their own buttons ([941f64d](https://github.com/calderon/bridge/commit/941f64d4fe7314b30cc205aaf4d7d9ff14455b2a)), closes [#98](https://github.com/calderon/bridge/issues/98)
* store shared routes for all your characters ([745e1f8](https://github.com/calderon/bridge/commit/745e1f845a1c4590ce61c534567fec09a2af3bb8)), closes [#23](https://github.com/calderon/bridge/issues/23)
* use the game's window frame for Manage routes ([9aa4453](https://github.com/calderon/bridge/commit/9aa4453ded9f3dcbc42d4bd4e74eef0d278a398d)), closes [#96](https://github.com/calderon/bridge/issues/96)
* whisper a stop to your target from the stop menu ([42a2386](https://github.com/calderon/bridge/commit/42a2386db513575718f2f7ecc960e7794ba9fbaa)), closes [#106](https://github.com/calderon/bridge/issues/106)


### Bug Fixes

* keep Esc, tooltips and window layering inside Bridge windows ([f68ced1](https://github.com/calderon/bridge/commit/f68ced1eb12fef43f021fe23d3479bab9c625817)), closes [#101](https://github.com/calderon/bridge/issues/101)

## [1.2.0](https://github.com/calderon/bridge/compare/v1.1.0...v1.2.0) (2026-11-24)


### Features

* add an optional description to stops ([967511b](https://github.com/calderon/bridge/commit/967511bd4c6e1a9598a352231b6da3924dd6c85b)), closes [#16](https://github.com/calderon/bridge/issues/16)
* make the arrival notice option silence chat and sound too ([103f9a6](https://github.com/calderon/bridge/commit/103f9a61f26a3c404c8b9616878bca4f5d7fe1b5)), closes [#19](https://github.com/calderon/bridge/issues/19)

## [1.1.0](https://github.com/calderon/bridge/compare/v1.0.0...v1.1.0) (2026-11-24)


### Features

* **compass:** show estimated time of arrival ([e3da569](https://github.com/calderon/bridge/commit/e3da5696ed2520b39071d5e636f6ac631d996d5f)), closes [#1](https://github.com/calderon/bridge/issues/1)
* **way:** import a pasted list of /way lines as stops ([ad4ab31](https://github.com/calderon/bridge/commit/ad4ab31278ed9029586738607ab82fded9053106)), closes [#10](https://github.com/calderon/bridge/issues/10)

## 1.0.0 (2026-11-23)

First public release.

- Stops on the world map: add, move, rename and remove them with the mouse.
- Stops also show on the minimap.
- On-screen compass to the next stop, with its name and distance.
- On-screen message when you reach a stop.
- Your corpse becomes the first stop when you release your spirit.
- "Manage stops" window: search, reorder, rename and remove.
- Share stops with your party, raid or guild.
- `/way`, `/way reset` and `/cway` commands.
- Distances in yards or meters.
- Questie and AzerothGPS integration.
- Texts in Spanish and English.
