# Simulaciones del dron

Este documento describe cómo ejecutar las simulaciones del dron, tanto la versión sin física como la versión con física.

## Requisitos previos

1. Descarga la carpeta `DRON_Modelo`.
2. Ábrela en MATLAB.
3. Ejecuta el archivo `startup` para inicializar el entorno.

## Primera ejecución

Para ejecutar la simulación del dron sin físicas, abre la carpeta `tests` y ejecuta el archivo:

- `test_visualizacion_dron_teclado`

Para ejecutar la simulación del dron con físicas, abre la carpeta `tests` y ejecuta el archivo:

- `simulacion_interactiva_fisica`

## Cambiar de simulación o volver a ejecutar

Si deseas cambiar de simulación o volver a ejecutar la misma, se recomienda ejecutar los siguientes comandos en MATLAB:

```matlab
clear
rehash
startup
```

Después, ejecuta la simulación que prefieras.

Este procedimiento se repite cada vez que quieras cambiar de simulación o volver a correr una distinta.
