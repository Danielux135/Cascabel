# DISEÑO.md — TILT OS

Diseño de la capa roguelike. La capa de sensación —física, geometría,
*juice*— no se diseña aquí: se descubre jugando y vive en `PLAN.md`.

Este documento se cierra **antes** de construir la Fase 3.

---

## 1. El pilar

**La mesa es un menú de tiros.**

Cada tiro de la mesa da algo distinto. Tu build decide cuáles te compensan.
Los enemigos decidenter cuáles te dejan.

Sin esto no hay juego: si todos los tiros dan lo mismo, el jugador no elige
nada, solo sobrevive, y las reliquias se convierten en bonificaciones
pasivas que no cambian cómo juegas.

Todo lo que venga después se juzga contra este pilar. Una mecánica que no
haga que un tiro sea más o menos deseable que otro, sobra.

---

## 2. El skill se recompensa

**Aguantar la bola es lo mejor que puede hacer el jugador.** Un pinball
premia a quien controla; que esto sea un roguelike no significa morir a
todas horas.

Pero eso obliga a mover la presión fuera del drenaje. Si drenar fuese la
única amenaza, el jugador bueno sería invulnerable.

**El enemigo ataca por reloj.** Tiene un contador visible que carga
mientras juegas y pega cuando llega, drenes o no.

- Aguantar la bola sigue siendo lo mejor: es tiempo pegando
- Pero no es gratis: el reloj corre igual
- El combate es una carrera: ¿le matas antes de que te desgaste?
- Drenar deja de ser catastrófico y pasa a ser un tropiezo: pierdes el
  multiplicador y le regalas un golpe

Un jugador excelente gana con vida de sobra. Uno mediano llega justo. Uno
malo se queda sin vida. **El skill se paga en margen, no en inmortalidad.**

Corolario: la duración de bola no se acorta artificialmente. Quince
segundos o noventa, lo que salga del control del jugador.

---

## 3. Los tres relojes

| Escala | Duración | Qué decides |
|---|---|---|
| **La bola** | ~15 s | Qué tiro intentas ahora |
| **El combate** | 1-2 min | Cómo repartes riesgo: ir a por el tiro grande o acumular seguro |
| **El run** | 30-40 min | Qué build montas y qué camino tomas |

Si alguna de las tres no tiene decisión, esa escala está rota.

---

## 3. Los tiros de la mesa

Cada uno con identidad propia. Este es el contenido que hace falta antes de
tocar reliquias.

| Tiro | Dificultad | Qué da |
|---|---|---|
| Racimo de bumpers | Fácil, casi accidental | Multiplicador. Muchos golpes pequeños |
| Banco de targets | Media | Daño plano. Se agota y se resetea |
| Órbita | Difícil, pide tiro limpio | Salto de multiplicador de golpe |
| Carril izquierdo | Media | Daño grande de un solo impacto |
| Carril derecho | Media | Devuelve la bola a la pala: encadenar |
| Platillo | Difícil, hay que buscarlo | Recurso o efecto especial |

**La regla:** cuanto más difícil el tiro, más concentrada la recompensa.
Lo fácil da poco y muchas veces; lo difícil da mucho de una vez.

---

## 4. Los ejes de build

Cinco. Una partida buena empuja uno o dos, no los cinco.

1. **Combo.** El multiplicador escala más y más rápido. Frágil: drenar
   duele muchísimo. Premia al que controla la bola.
2. **Golpe único.** Un tiro concreto hace un daño enorme. Ignoras el resto
   de la mesa y pescas ese tiro una y otra vez.
3. **Supervivencia.** Protección de outlanes, vida extra, curación. Juegas
   a agotar al enemigo sin arriesgar.
4. **Escalado.** Te haces más fuerte a lo largo del run en vez de dentro de
   la bola. Débil al principio, brutal al final.
5. **Caos.** Multibola, bolas extra, efectos aleatorios. Pierdes control a
   cambio de volumen.

**Prueba de que el diseño funciona:** dos partidas con ejes distintos deben
sentirse como juegos distintos, no como el mismo juego con números más
grandes.

---

## 5. Recursos

| Recurso | Vive | Se pierde |
|---|---|---|
| **Vida** | Todo el run | Al drenar. No se cura sola entre combates |
| **Multiplicador** | Una bola | Al drenar |
| **Chatarra** | Todo el run | Al gastarla en la tienda |
| **Reliquias** | Todo el run | Nunca |

Solo cuatro. Si aparece un quinto, hay que justificar por qué no puede ser
uno de estos.

---

## 6. Ganchos de reliquia

Las reliquias no se inventan una a una: se diseñan contra esta rejilla. Si
una reliquia no encaja en ningún gancho, o sobra o falta un gancho.

- Al golpear un **bumper**
- Al golpear un **target** / al agotar un banco
- Al completar un **recorrido concreto**
- Al **subir de tramo** de multiplicador
- Al **empezar** la bola
- Al **drenar**
- Al **matar** un enemigo
- Al **entrar en combate**
- **Pasivos condicionales** (si el multiplicador ≥ ×3, si la vida < 50%…)

Las quince primeras reliquias deben cubrir los cinco ejes y al menos seis
ganchos distintos. Nada de quince variantes de "+2 de daño".

---

## 7. Enemigos que cambian cómo juegas

Un enemigo con más vida no es un enemigo nuevo. Cada uno debe alterar qué
tiro te compensa:

- **Bloquea un recorrido** hasta que le pegas por otro sitio
- **Se cura** si no le tocas en N segundos: prohíbe jugar a lo seguro
- **Refleja** si repites el mismo tiro dos veces seguidas: obliga a variar
- **Ataca por tiempo** además de por drenaje: prohíbe acumular sin pegar
- **Blindaje** que solo rompe el daño concentrado: mata al build de combo
- **Castiga el multiplicador alto**: obliga a gastarlo en vez de guardarlo

Cada uno es una respuesta directa a un eje de build. Ahí nace la variedad
real de la partida.

---

## 8. Estructura del run

Tres actos. Doce a quince combates. Treinta a cuarenta minutos.

```
Acto I    combate → combate → élite → tienda → combate → JEFE
Acto II   igual, con enemigos que responden a los ejes
Acto III  igual, más corto y más duro
```

**Nodos:** combate, élite, tienda, descanso, evento, jefe.

**Decisiones del run:** qué rama tomas en el mapa, cuál de tres reliquias
eliges, qué compras, si descansas o mejoras.

La vida no se cura entre combates. El descanso es la única cura, y compite
con mejorar. Ahí está la tensión del mapa.

---

## 9. Lo que este juego NO es

Cerca de la mitad del trabajo de diseño es decir que no.

- **No es un simulador de pinball.** No hay tabla de puntuaciones, ni
  modos multibola de máquina real, ni misiones de mesa.
- **No hay mesas procedurales.** Tres mesas hechas a mano, como biomas.
- **No hay meta-progresión hasta que el run sea divertido sin ella.**
- **No hay modo historia.** Escribir, guionizar, arte de personajes y una
  segunda estructura de progresión es de lo más caro que existe y no
  mejora el núcleo. **La narrativa va en la cáscara**, que sale gratis:
  mensajes de error que cambian según la profundidad, archivos de registro
  abribles en el escritorio, correos sin leer del operador de la máquina, y
  el sistema degradándose acto a acto — más ventanas rotas, más avisos, el
  fondo corrompiéndose. Atmósfera sin deuda.
- **Sí hay dificultades acumulables**, estilo Slay the Spire: más vida
  enemiga, reloj más rápido, outlanes más anchos. Se desbloquean ganando.
  Es el sitio para recompensar al que domina el juego. Fase 7.
- **No hay más de un jugador.**

---

## 10. Preguntas abiertas

Se responden jugando, no discutiendo. Pero hay que tenerlas a la vista:

- ¿Cuánto debe durar la carga del reloj del enemigo? Es el dial que decide
  si el combate es una carrera tensa o un paseo. Se calibra jugando.
- ¿El jugador debería poder elegir la mesa, o va ligada al acto?
- ¿La chatarra se gana por daño, por tiro difícil o por combate ganado?
  Lo que premies es lo que la gente jugará.
