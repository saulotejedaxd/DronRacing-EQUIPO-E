# Linealización del Modelo Matemático

Para el modelo sencillo de estabilización de altura, la linealización es bastante simple. De hecho, es una buena introducción a la linealización antes de pasar a modelos no lineales más complejos.

## 1. Modelo no lineal

Del modelado matemático se obtuvo la ecuación:

```
m·z̈ = T − mg
```

o, despejando la aceleración:

```
z̈ = (T − mg) / m
```

donde:

- `z`: altura del dron.
- `T`: empuje total generado por los motores.
- `m`: masa del dron.
- `g`: aceleración de la gravedad.

## 2. Punto de equilibrio

Para realizar la linealización, primero se determina el punto de equilibrio.

En vuelo estacionario (hover), el dron mantiene una altura constante, por lo que:

```
ż = 0
z̈ = 0
```

Sustituyendo en la ecuación:

```
0 = (Te − mg) / m
```

Despejando:

```
Te = mg
```

Este resultado indica que, en equilibrio, el empuje total es igual al peso del dron.

## 3. Variables de perturbación

Ahora se consideran pequeñas variaciones alrededor del equilibrio.

Se define:

```
T = Te + ΔT
```

donde:

- `Te`: empuje de equilibrio.
- `ΔT`: pequeña variación del empuje.

También:

```
z = ze + Δz
```

Como el sistema trabaja cerca del punto de equilibrio, únicamente interesan esas pequeñas variaciones.

## 4. Sustitución

Sustituyendo:

```
m·z̈ = (Te + ΔT) − mg
```

Como `Te = mg`, queda:

```
m·z̈ = ΔT
```

Finalmente:

```
z̈ = ΔT / m
```

## 5. Modelo lineal

El sistema linealizado queda:

```
z̈ = (1/m)·ΔT
```

Este modelo es lineal porque la salida (`z̈`) depende de forma proporcional de la entrada (`ΔT`).

## 6. Espacio de estados

Definiendo:

```
x1 = Δz
x2 = Δż
```

se obtiene:

```
ẋ1 = x2
ẋ2 = (1/m)·ΔT
```

En forma matricial:

```
⎡ẋ1⎤   ⎡0  1⎤ ⎡x1⎤   ⎡ 0  ⎤
⎢  ⎥ = ⎢    ⎥ ⎢  ⎥ + ⎢    ⎥ · ΔT
⎣ẋ2⎦   ⎣0  0⎦ ⎣x2⎦   ⎣1/m⎦
```

y la salida es:

```
y = [1  0] x
```

## 7. Función de transferencia

Aplicando la transformada de Laplace (condiciones iniciales nulas):

```
s²Z(s) = (1/m)·ΔT(s)
```

Entonces:

```
G(s) = Z(s) / ΔT(s) = 1 / (m·s²)
```

## ¿Por qué es importante esta linealización?

La mayoría de los controladores clásicos (como el PID) se diseñan a partir de modelos lineales. Al linealizar el sistema alrededor del punto de equilibrio (vuelo estacionario), se obtiene un modelo sencillo que permite analizar la estabilidad y diseñar el controlador sin perder la esencia del comportamiento del dron.

## Nota importante

En realidad, el modelo de altura aislado:

```
m·z̈ = T − mg
```

ya es lineal respecto a la entrada `T`. La "linealización" consiste principalmente en expresar el sistema alrededor del punto de equilibrio (`Te = mg`) y trabajar con perturbaciones (`ΔT` y `Δz`). Este procedimiento es útil porque es el mismo que se empleará más adelante cuando se modele el cuadricóptero completo, cuyo modelo sí es no lineal.
