# Blank Pixel Game — Mecánicas, estilos y sprites

Registro técnico de lo implementado en el componente de mecánicas del jugador, los estilos de combate,
la animación de enemigos y el flujo de sprites. Actualizado: 24-nov-2026.

Plataformero de acción 2D hack and slash con estilos de combate (inspiración: Devil May Cry, Sanabi, Sekiro).
GameMaker (GML). Repo: `Jhurtadopi/proyecto_videojuegos`, rama `main`.

---

## 1. Reglas del equipo

- **No se modifica código de otros colaboradores**: `obj_jugador`, `obj_hitbox`, `obj_hurtbox`, `obj_controladores`,
  `scr_estado_jugador`, `scr_estado_enemigo`, `scr_mec_parry`, `scr_mec_gancho`, `scr_mec_doble_salto`, `scr_mec_dash`,
  `obj_enemigo_*` (ligero, mediano, pesado, boss), `obj_torreta`, `obj_proyectil`, `obj_plataforma_desplazable`, y lo
  que agreguen en `obj_enemigo`. Desde código propio solo se **leen y escriben sus variables en tiempo de ejecución**.
  Si algo de ellos falla, se avisa; no se arregla.
- Cada mecánica nueva vive en un script propio `scr_mec_<nombre>` con funciones `_crear` / `_inicio` (Begin Step) /
  `_fin` (End Step) / `_dibujar`, llamadas desde el componente `obj_mecanicas_jugador`.
- **Cerrar GameMaker antes de editar archivos desde fuera.** Si el IDE está abierto, al guardar reescribe el `.yyp` y
  borra los recursos agregados (pasó con `scr_mec_ud_robot`).
- Los commits no llevan líneas de coautoría ni atribución a herramientas de IA.

## 2. Arquitectura

| Pieza | Qué hace |
|---|---|
| `obj_mecanicas_jugador` | Componente del jugador. Create crea cada mecánica; Begin Step (`Step_1`) inicia acciones antes del Step de `obj_jugador`; End Step (`Step_2`) corrige el movimiento después; Draw_0 / Draw_64 dibujan efectos y HUD. Fija `jugador.mask_index = spr_hurtbox` (colisión 32×64). F1–F4 cambian de room, R reinicia. |
| `obj_mec_golpe` | Golpe cuerpo a cuerpo. Mientras la ventana de `scr_mec_parry` está abierta mantiene un `obj_hitbox_golpe` y elige el golpe según el estilo (`mec_<estilo>_elegir_golpe`). Teclas 1–4 cambian de estilo (`global.estilo`). |
| `obj_hitbox_golpe` | Hitbox del golpe: alcanza a varios enemigos, cada uno una vez por golpe. Aplica `jugador_vsp`, hitstop, y carga las barras de ultimate (Swordmaster y robot del Underdog). |
| `obj_camara` | Cámara: fija en rooms del tamaño de la pantalla (1366×768); en rooms más grandes sigue al jugador (desplazamiento lateral suave, mira hacia delante, no se sale de la room). Temblor: `aplicar_temblor(px, frames)`; `saltar_a(x, y)` la recoloca sin suavizado. Lo crea el componente si la room no tiene uno. |
| `obj_fx_estampada` | Efecto de impacto (destello, anillos, grietas, escombros). Recibe `{ fuerza, radio }`. |
| `scr_estilos` | `enum Estilo { BASE, SWORDMASTER, UNDERDOG, SHIELD }`. |
| `scr_mec_comun` | Utilidades: `mec_en_suelo`, `mec_mover_con_choque`, `mec_mover_hasta_x`. |

**Struct de golpe** (lo devuelve `mec_<estilo>_elegir_golpe`):
`{ nombre, danio, kx, ky, stagger, hitstop, jugador_vsp, zona }`
- `kx` se multiplica por la dirección en que mira el jugador; `ky` negativo = hacia arriba.
- `jugador_vsp`: velocidad vertical que recibe el jugador solo si el golpe conecta (`undefined` = no lo mueve).
- `zona`: `[adelante_desde, adelante_hasta, arriba, abajo]` en px desde los pies del jugador.
- Opcionales: `kx_input` (A/D decide hacia dónde sale el enemigo), `rebote` (martillo del robot).

## 3. Mecánicas base del jugador

| Script | Mecánica |
|---|---|
| `scr_mec_doble_salto` | Doble salto (Espacio). |
| `scr_mec_dash` | Dash (Shift), uno por estancia en el aire. |
| `scr_mec_parry` | Click izq.: golpe; sus primeros frames reflejan proyectiles (parry). |
| `scr_mec_buffer` | Buffer del click para encadenar el combo. |
| `scr_mec_gancho` | Gancho (mantener click der.): A/D balancean, W retrae, S vuelve al punto. |
| `scr_mec_gancho_enemigo` | Click der. sobre un enemigo: lo atrae; mantener = arrastrarlo; soltar = lanzarlo hacia la mira. W + click der. = ir hacia él. |
| `scr_mec_pared` | Deslizamiento y salto en pared. |
| `scr_mec_animacion` | Elige el sprite del jugador por estado, voltea con `mirando`, volteretas (doble salto, pared, dash tras soltar el gancho), estela cian del dash, cable de gancho futurista con manos alternas y sprites opcionales por golpe. |

## 4. Estilos de combate (teclas 1–4)

### 4.1 Swordmaster (1) — `scr_mec_swordmaster` (corre en `obj_mec_golpe`)
- Combo de 3 en el suelo: Corte 1 → Corte 2 → Remate.
- **W + click en el suelo**: Lanzador (enemigo y jugador suben juntos).
- **Click en el aire**: corte aéreo direccional (A/D al golpear decide hacia dónde sale).
- **W + click en el aire**: corte ascendente.
- **S + click en el aire**: estampada; suspensión, caída en picada (hasta 36 px/frame) y onda expansiva al tocar el
  suelo (radio y daño según la altura).
- **F: ultimate "Juicio Dimensional"** — congela el mundo, cortes sobre los enemigos en 420 px y detonación.
  Barra provisional: se carga con el daño hecho (100) hasta que existan los rangos.
- Límite de juggle en `obj_enemigo` (los golpes aéreos repetidos levantan menos) y stagger que aturde.

### 4.2 Underdog (2) — `scr_mec_underdog` (contexto `obj_mecanicas_jugador`)
- **S**: excava. Bajo tierra es invulnerable (su hurtbox se desactiva) y se dibuja como silueta.
- Bajo tierra: A/D mover, **Shift** dash dirigible, **Espacio** emerge golpeando hacia arriba,
  **click** pinchazo (o **arrastre** si encima hay un enemigo recién estampado: conecta con la estampada del
  Swordmaster), **W + click** perforación (sube taladrando con el enemigo).
- Superficie: **click** taladrazo, **W + click** taladro hacia arriba con vaivén (multigolpe que sostiene al enemigo).
- Aire: **W + click** taladro hacia arriba suspendido en el aire (24 frames, mismo multigolpe y lanzamiento final).
- Aire: **S + click** taladro hacia abajo (`UdAccion.ABAJO`): cae a 9 px/frame taladrando; los enemigos bajo la
  punta reciben golpes cada 4 frames y bajan con él; al tocar el suelo los estampa (quedan derribados, listos para
  el arrastre). Sprite `spr_jugador_ud_abajo` (`hoja_underdog_abajo`, `--fila ud_abajo:3`).

### 4.3 Ultimate del Underdog: mini robot — `scr_mec_ud_robot` (nuevo)
- **F** se sube al robot (requiere al menos 20 % de barra); **F** otra vez se baja. La barra que sobra se puede
  volver a usar.
- **Barra**: se carga con el daño hecho en estilo Underdog (100 de daño = llena), se muestra donde va la del
  Swordmaster y **baja mientras el robot está activo**: llena dura 20 s. Si se vacía o se cambia de estilo, se baja.
- Golpes del robot (`mec_ud_robot_elegir_golpe`):

| Input | Golpe | Efecto |
|---|---|---|
| Click al lado | Robo-puñetazo | Daño 10, empuje lateral. En el aire mantiene un poco al robot. |
| W + click en el suelo | Robo-uppercut | Lanza alto al enemigo (ky −13) y el robot salta con él para seguir el combo. |
| W + click en el aire | Uppercut aéreo | Eleva poquito (ky −6, robot −5): suficiente para seguir combeando. |
| S + click en el aire | Martillo | Estampa al enemigo (ky 16); al tocar el suelo **rebota** un poco. El robot no se tira en picada. |

- **Defensa**: recibe **75 % menos de daño**, 70 % menos de empuje y no se aturde (súper armadura). Se hace
  reemplazando `jugador.recibir_impacto` en tiempo de ejecución por una versión envuelta; al bajarse se restaura.
- En el robot no se excava, no se taladra y no se usa el gancho.
- Valores ajustables en `mec_ud_robot_crear`: `ub_max`, `ub_duracion`, `ub_min_activar`, `ub_reduccion`,
  `ub_reduccion_empuje`, `ub_rebote_vsp`.

### 4.4 Shield (3) — `scr_mec_shield`
- **E (mantener)**: guardia. Primeros frames = parry: perfecto (naranja, aturde y no gasta guardia) o tardío
  (amarillo). Luego bloquea con resistencia usando el sistema de bloqueo de `obj_hitbox` (al agotarla se rompe).
  Los proyectiles los absorbe el escudo.
- **Shift**: estampida hacia el enemigo más cercano en la dirección en que mira.
- **Q**: lanza el escudo de sierra (`obj_escudo_lanzado`) que se clava, aturde y daña; Q otra vez lo hace volver.
- **Click**: escudazo (sin escudo: puñetazo).
- `obj_enemigo_atacante`: enemigo de prueba para el parry.

### 4.5 Base (4)
Golpe simple `golpe_base` de `obj_mec_golpe`.

## 5. Animación de enemigos — `scr_mec_animacion_enemigos` (nuevo)

Corre en el End Step del componente. No toca el código de los enemigos: en tiempo de ejecución escribe
`sprite_index`, `image_index`, `image_speed = 0` y `mask_index` (fijo en su sprite original, para que los sprites
nuevos no cambien la colisión con el suelo).

| Objeto | Sprites | Estados que se ven |
|---|---|---|
| `obj_enemigo_ligero`, `_mediano`, `_pesado` | `spr_enemigo_ligero_*` | quieto, correr, ataque (3 cuadros con contador propio, porque el ataque real dura 2 frames), en el aire, aturdido, derribado |
| `obj_enemigo_boss` | `spr_enemigo_jefe_*` | quieto, caminar, espadazo, disparo con el cañón, guardia (`bloqueando`), aturdido, en el aire, derribado |
| `obj_torreta` (centinela) | `spr_enemigo_centinela_*` | quieta, carga (`disparo_timer <= 15`), disparo, recuperación, aturdida |
| `obj_proyectil` | `spr_enemigo_centinela_bala` | girada hacia donde viaja; cian si el jugador la devolvió |

- La centinela ahora **mira hacia el jugador** (`mirando`); su código la dejaba siempre a la izquierda.
- La hurtbox del jefe se agranda a 44×88 para que coincida con su sprite.
- Si falta un sprite, ese enemigo se sigue viendo como antes.
- **Golpes huérfanos**: en el Begin Step del componente, los `obj_hitbox` cuyo dueño ya no existe se marcan
  `activo = false` (evita el crash de `obj_hitbox` con el jugador en guardia; ver bugs).

## 6. Niveles con desplazamiento lateral

### 6.1 Niveles
| Room | Tamaño | Contenido | Sale a |
|---|---|---|---|
| `Nivel_1` "Distrito de Neón" (F5) | 250×30 bloques (8000×960) | ligeros, 1 mediano, 3 centinelas; foso de pinchos; **grúa sobre un mar de pinchos** (botón → la plataforma avanza → gancho a la plataforma y a una columna colgante); saltos sobre suelo de pinchos; **compuerta** que se abre con un botón en una repisa alta; 3 checkpoints | `Nivel_2` |
| `Nivel_2` "Fundición" (F6) | 280×30 bloques (8960×960) | pesados, medianos, ligeros, 4 centinelas; tres fosos; **ascensor** (grúa que sube la plataforma hasta lo alto de un muro); **doble grúa** sobre un mar de pinchos (la segunda se activa desde una isla a la que solo se llega con la primera); plataformas sobre pinchos hasta el botón de la compuerta final; 3 checkpoints | `Room_Boss` |

Duración pensada: 2–4 minutos cada uno. F5 / F6 empiezan el nivel desde el principio; R reinicia desde el
último checkpoint.

### 6.2 Generador (`arte_generado/generar_niveles.py`)
Cada nivel es una función (`nivel_1()`, `nivel_2()`) en una cuadrícula de 32 px: `solido(c0, c1, r0, r1)`,
`pinchos(c0, c1, fila)`, `jugador(c, piso)`, `enemigo("L"|"M"|"H"|"T", c, piso)`, `checkpoint`, `boton(c, piso, canal)`,
`puerta(c, piso, canal)`, `grua(c, fila_riel, recorrido_cols, largo, canal, largo_final, velocidad, retraso, ciclo)`,
`meta(c, piso, "Room")`. `piso` = fila del bloque sobre el que se apoya. Con GameMaker cerrado:
`python3 generar_niveles.py` reescribe las rooms (une los sólidos en rectángulos, pone los parámetros en el código de
creación de cada instancia) y deja `arte_generado/niveles/preview_<nivel>.png`.
**No editar `Nivel_1`/`Nivel_2` a mano en el IDE**: el generador las sobrescribe.
Física de referencia: salto 144 px de alto / ~290 de largo; doble salto ~240 de alto; dash +90; gancho 420 px.

### 6.3 Elementos de nivel (`scr_nivel` + objetos propios, creados por `arte_generado/crear_objetos_nivel.py`)
| Objeto | Qué hace |
|---|---|
| `obj_nivel` | Controlador: coloca al jugador en el checkpoint, reaparición si cae, fondo de ciudad con parallax, terreno con tiles (oculta los `obj_solid` y los dibuja con `spr_nivel_tile`), cartel de inicio, cronómetro y "NIVEL COMPLETADO". |
| `obj_pinchos` | Tramo de pinchos (`image_xscale` = celdas). Jugador: vuelve al checkpoint con 20 de daño e invulnerabilidad breve. Enemigos lanzados a los pinchos: 12 de daño y rebote. |
| `obj_boton` | Se activa al pisarlo o golpearlo; activa su `canal`. Se rearma si su grúa-ascensor vuelve. |
| `obj_grua` + `obj_plataforma_grua` | Riel en el techo con plataforma colgante (sólida: se pisa y se le engancha el gancho). Con su canal activo lleva la plataforma `recorrido` px y cambia el cable de `largo` a `largo_final`; lleva al jugador que esté encima. Muestra el destino como silueta amarilla. `ciclo = true` (ascensor): vuelve si nadie la usa y rearma el botón. |
| `obj_puerta` | Compuerta sólida de energía: se abre (sube y se desvanece) con su canal. |
| `obj_checkpoint` | Guarda el punto de reaparición (`global.nivel_cp`, solo hacia delante) y cura 30. |
| `obj_meta` | Portal de salida: muestra el tiempo y va a `siguiente`. |

Canales: `nivel_activar_canal(c)` / `nivel_canal_activo(c)` (`global.nivel_canales`, se reinician al entrar a la room).
Las centinelas fuera de la pantalla no disparan (lo retiene `scr_mec_animacion_enemigos`).

## 7. Sprites

### 7.1 Generación (Higgsfield, `generate_image`)
`model: gpt_image_2_6`, `aspect_ratio: 21:9`, `count: 2`, `background: transparent`, `quality: high`, con una hoja
anterior como `image_references`. Prompt en inglés: una sola fila de N cuadros, vista lateral **mirando a la derecha**,
espacio entre cuadros, píxeles nítidos, sin halo, sin sombra, sin texto.
**Regla clave: el cuadro 1 es siempre un idle de pie** (referencia de escala: el script lo mide y lo descarta).
Máximo 4 generaciones simultáneas. Diseños con copyright se describen como diseño propio.
La descarga desde la IA está bloqueada: se descargan a mano a `arte_generado/originales/hoja_<nombre>.png`.
**Revisar el nombre al guardar**: dos veces se cruzaron hojas (Shield y robot).

### 7.2 Procesado (en `Blank Pixel Game/arte_generado`, con GameMaker cerrado)
```
python3 procesar_hoja.py [--salida enemigos] --fila NOMBRE:N[,NOMBRE2:N...] originales/hoja_X.png [alto_px]
python3 aplicar_sprites.py
```
- `procesar_hoja.py` corta la fila, separa poses pegadas, escala con el idle de referencia a `alto_px`
  (63 por defecto = jugador), paleta de 24 colores y origen abajo-centro. Deja los PNG en `jugador/`
  (o en `enemigos/` con `--salida enemigos`).
- `aplicar_sprites.py` crea/actualiza `spr_jugador_<nombre>` (desde `jugador/`) y `spr_enemigo_<nombre>`
  (desde `enemigos/`) y los registra en el `.yyp`. Un sprite nuevo hay que agregarlo a la lista correspondiente.
  Evitar nombres que empiecen igual que otro + `_` (ej. `corte_arriba`, no `aereo_arriba`).
- En el código los sprites opcionales se buscan con `asset_get_index("spr" + "_jugador_<nombre>")`.

### 7.3 Inventario

| Prefijo | Hoja(s) | Sprites | Alto |
|---|---|---|---|
| (ninguno) Swordmaster | `hoja_jugador`, `hoja_ataque`, `hoja_gancho`, `hoja_golpes`, `hoja_corte_arriba` | idle, correr, salto, dash, ataque, gancho, lanzador, aereo, estampada, corte_arriba | 63 |
| `ud_` Underdog | `hoja_underdog_superficie/combate/arriba`, `hoja_underdog_abajo` (`ud_abajo:3`) | ud_idle, ud_correr, ud_ataque, ud_excavar, ud_emerger, ud_arriba, ud_subir, ud_abajo | 63 |
| `ud_robot_` robot | `hoja_robot_mov` (`ud_robot_idle:2,ud_robot_correr:4`), `hoja_robot_golpes` (`ud_robot_puno:3,ud_robot_upper:3`), `hoja_robot_aire` (`ud_robot_salto:2,ud_robot_elevar:2,ud_robot_martillo:2`) | 7 sprites | 80 |
| `sh_` Shield | `hoja_shield_superficie` (`sh_idle:2,sh_correr:4`), `hoja_shield_combate` (`sh_dash:2,sh_parry:2,sh_lanzar:2`), `hoja_shield_escudo` (`sh_escudo:1,sh_sin_idle:1,sh_sin_correr:4`) | 8 sprites | 63 |
| `spr_enemigo_ligero_` | `hoja_ligero_mov` (`ligero_idle:2,ligero_correr:4`), `hoja_ligero_combate` (`ligero_ataque:3,ligero_aire:1,ligero_aturdido:1,ligero_derribado:1`) | 6 sprites | 54 |
| `spr_enemigo_jefe_` | `hoja_jefe_mov` (`jefe_idle:2,jefe_caminar:4`), `hoja_jefe_combate` (`jefe_ataque:3,jefe_disparo:2,jefe_guardia:1,jefe_aturdido:1,jefe_aire:1,jefe_derribado:1`) | 8 sprites | 92 |
| `spr_enemigo_centinela_` | `hoja_centinela` (`centinela_idle:2,centinela_disparo:3,centinela_aturdida:1,centinela_bala:1`) | 4 sprites | 34 |
| `spr_nivel_` | hechos por código: `generar_sprites_nivel.py` | pinchos, boton, checkpoint, plataforma, puerta, meta, tile | — |

Respaldos de cada cambio en `arte_generado/respaldo/` (ignorado por git).

## 8. Rooms de prueba
F1 Room1 (ligeros + centinelas), F2 Room2 (pesados), F3 Room_Underdog, F4 Room_Shield, F5 Nivel_1, F6 Nivel_2.
También existen Room3 (medianos y plataformas desplazables) y Room_Boss. El juego arranca en la primera room del
orden (hoy Room3); para que arranque en el Nivel 1 hay que moverlo al principio del orden de rooms en el IDE.

## 9. Pendiente
- Descargar y procesar `hoja_underdog_abajo` (taladro hacia abajo).
- Sprites propios del enemigo mediano y pesado (hoy usan los del ligero).
- Más niveles (el generador ya lo permite); música y sonidos; menú y pantalla de muerte.
- Rangos de estilo tipo DMC (D→S; recargan dash/gancho; el rango S habilita los ultimates).
- Estilos Boxer, Gunner y Doppelganger. Underdog: atravesar paredes y trampas.

## 10. Bugs de otros colaboradores (avisar, no arreglar)
- **`obj_hitbox` (Collision con obj_hurtbox)**: `alarm[0] = 3` se renueva en cada colisión ANTES de comprobar el
  objetivo, así que un golpe que toca la hurtbox de su propio dueño nunca se destruye. Si el dueño muere, el golpe
  queda huérfano y, con el jugador en guardia, la línea `sign(owner.x - _target.x)` crashea ("Unable to find
  instance"). Arreglo sugerido: mover la alarma después de las comprobaciones y añadir
  `if (!instance_exists(owner)) { instance_destroy(); exit; }`. Mitigado desde el componente (ver sección 5).
- En `obj_enemigo`, el bonus por estilo compara `global.estilo` (número) con `estilo_favorecido` (texto), y
  `_mult_d` / `_mult_s` no se usan.
- `obj_enemigo_ligero`: `ataque_enemigo_timer` no se inicia con `ataque_preparacion` al empezar el ataque, así que
  el golpe sale sin preparación (la animación muestra la preparación igual, con su propio contador).
- El estado HURT del jugador nunca vuelve a NORMAL y no hay invencibilidad tras recibir daño.
- `recibir_impacto` del jugador destruye la instancia con vida ≤ 0 en el mismo golpe (sin animación de muerte).
- Manuela movió Room3 antes que Room2 en el orden de rooms: el juego arranca en Room3.

## 11. Historial
- **22-nov**: Underdog básico funcional.
- **23-nov**: estilo Shield funcional (guardia/parry, estampida, escudo lanzado) y sus 8 sprites; merge con las
  plataformas desplazables de Manuela.
- **23/24-nov**: ultimate del Underdog (mini robot) con 7 sprites; sprites y animación de enemigos (ligero, jefe,
  centinela, balas); `procesar_hoja.py --salida` y sprites de enemigos en `aplicar_sprites.py`.
- **24-nov**: hojas de combate del ligero y del jefe (ataque, disparo, guardia, aturdido, aire, derribado);
  Underdog: taladro arriba en el aire y taladro abajo cayendo; mitigación del crash de golpes huérfanos.
- **24-nov**: cámara con desplazamiento lateral; elementos de nivel (pinchos, botón, grúa, compuerta,
  checkpoint, meta, terreno y fondo); generador de niveles; `Nivel_1` y `Nivel_2`.
