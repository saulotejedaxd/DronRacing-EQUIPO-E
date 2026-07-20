import time
import threading
import serial
from pynput import keyboard

PUERTO = "COM3"
BAUDIOS = 115200

PWM_0V = 0
PWM_1V1 = 85
PWM_2V2 = 170

teclas = set()
ejecutando = True


def calcular_salidas():
    # Todos empiezan centrados en 1.1 V
    pin25 = PWM_1V1
    pin26 = PWM_1V1
    pin27 = PWM_1V1
    pin32 = PWM_1V1

    # GPIO 25: elevación
    if "w" in teclas and "s" not in teclas:
        pin25 = PWM_2V2
    elif "s" in teclas and "w" not in teclas:
        pin25 = PWM_0V

    # GPIO 26: rotación
    if "a" in teclas and "d" not in teclas:
        pin26 = PWM_2V2
    elif "d" in teclas and "a" not in teclas:
        pin26 = PWM_0V

    # GPIO 27: arriba y abajo
    if keyboard.Key.down in teclas and keyboard.Key.up not in teclas:
        pin27 = PWM_2V2
    elif keyboard.Key.up in teclas and keyboard.Key.down not in teclas:
        pin27 = PWM_0V

    # GPIO 32: derecha e izquierda
    if keyboard.Key.right in teclas and keyboard.Key.left not in teclas:
        pin32 = PWM_2V2
    elif keyboard.Key.left in teclas and keyboard.Key.right not in teclas:
        pin32 = PWM_0V

    return pin25, pin26, pin27, pin32


def enviar_continuamente():
    ultimo_valor = None

    while ejecutando:
        valores = calcular_salidas()

        mensaje = f"{valores[0]},{valores[1]},{valores[2]},{valores[3]}\n"
        esp32.write(mensaje.encode("utf-8"))

        if valores != ultimo_valor:
            print(
                f"GPIO25={valores[0]}  "
                f"GPIO26={valores[1]}  "
                f"GPIO27={valores[2]}  "
                f"GPIO32={valores[3]}"
            )
            ultimo_valor = valores

        # Manda datos 20 veces por segundo
        time.sleep(0.05)


def identificar_tecla(tecla):
    try:
        return tecla.char.lower()
    except AttributeError:
        return tecla


def presionar(tecla):
    global ejecutando

    if tecla == keyboard.Key.esc:
        ejecutando = False
        return False

    teclas.add(identificar_tecla(tecla))


def soltar(tecla):
    teclas.discard(identificar_tecla(tecla))


print("Conectando al ESP32 por COM3...")

try:
    esp32 = serial.Serial(PUERTO, BAUDIOS, timeout=0)
except serial.SerialException as error:
    print("No se pudo abrir COM3.")
    print("Cierra el Monitor Serie de Arduino.")
    print(error)
    raise SystemExit

# Espera a que el ESP32 termine de reiniciarse
time.sleep(2)

print()
print("CONTROL ACTIVO")
print("W/S = elevación")
print("A/D = rotación")
print("Flechas = movimiento")
print("ESC = cerrar")
print()

hilo = threading.Thread(target=enviar_continuamente, daemon=True)
hilo.start()

with keyboard.Listener(
    on_press=presionar,
    on_release=soltar
) as listener:
    listener.join()

ejecutando = False

# Centrar las cuatro señales antes de cerrar
for _ in range(5):
    esp32.write(b"85,85,85,85\n")
    time.sleep(0.05)

esp32.close()

print("Control detenido. Todo quedó en 1.1 V.")