# Modelado Matemático de la Estabilización de Altura de un Cuadricóptero

## 1. Descripción del sistema

Se considera un cuadricóptero que despega verticalmente y mantiene una altura constante. Para simplificar el análisis se supone que:

- El movimiento ocurre únicamente en el eje vertical `z`.
- El dron permanece completamente horizontal.
- No existen perturbaciones externas como el viento.
- La masa del dron permanece constante.
- El empuje total es generado por los cuatro motores.

## 2. Parámetros del sistema

| Parámetro | Descripción | Unidad |
|-----------|-------------|--------|
| `m` | Masa del dron | kg |
| `g` | Aceleración de la gravedad | m/s² |
| `T` | Empuje total de los motores | N |
| `z` | Altura | m |
| `v = ż` | Velocidad vertical | m/s |
| `a = z̈` | Aceleración vertical | m/s² |

## 3. Diagrama de cuerpo libre

Sobre el dron actúan únicamente dos fuerzas:

```
        ↑  Empuje (T)
          □  Dron
        ↓  Peso (mg)
```

## 4. Segunda Ley de Newton

La suma de fuerzas en el eje vertical es:

```
ΣF_z = m·z̈
```

Sustituyendo las fuerzas:

```
T − mg = m·z̈
```

Despejando la aceleración:

```
z̈ = (T − mg) / m
```

Esta es la ecuación diferencial que describe el movimiento vertical del dron.

## 5. Condición de equilibrio

Cuando el dron permanece suspendido sin subir ni bajar:

```
z̈ = 0
```

Por lo tanto:

```
T = mg
```

Esto significa que el empuje total debe ser igual al peso del dron para mantener una altura constante.

## 6. Modelo en espacio de estados

Se definen las variables de estado:

```
x1 = z
x2 = ż
```

El sistema queda:

```
ẋ1 = x2
ẋ2 = (T − mg) / m
```

## 7. Control de altura

Para mantener el dron en una altura deseada `z_ref`, se calcula el error:

```
e = z_ref − z
```

El controlador PID genera una señal de control:

```
u(t) = Kp·e(t) + Ki·∫e(t)dt + Kd·(de(t)/dt)
```

El empuje aplicado al dron es:

```
T = mg + u(t)
```

Así, el controlador aumenta o disminuye el empuje para corregir la altura.

## 8. Implementación en MATLAB

El modelo anterior se implementa mediante integración numérica utilizando un paso de tiempo `Δt`:

```
a = (T − mg) / m
v(k+1) = v(k) + a·Δt
z(k+1) = z(k) + v(k+1)·Δt
```

Estas ecuaciones son las que utiliza el código de MATLAB para simular el comportamiento del dron.

## 9. Diagrama de bloques del sistema

```
 Altura deseada
      │
      ▼
+-------------+
| Comparador  |
+-------------+
      │ Error
      ▼
+-------------+
| Control PID |
+-------------+
      │
      ▼
 Empuje (T)
      │
      ▼
+----------------+
| Modelo del     |
| dron           |
| T - mg = m·a   |
+----------------+
      │
      ▼
 Altura (z)
      │
      └─────────────── Retroalimentación ───────────────┘
```

## Conclusión

Este modelo matemático representa de forma simplificada la dinámica vertical de un cuadricóptero. A partir de la Segunda Ley de Newton se obtiene la ecuación que relaciona el empuje generado por los motores con la aceleración del dron. Sobre este modelo se diseña un controlador PID que ajusta el empuje para mantener la altura deseada.

Este nivel de modelado es adecuado para una introducción al control de drones y sirve como base para ampliar posteriormente el modelo a los otros movimientos del cuadricóptero (roll, pitch y yaw).
