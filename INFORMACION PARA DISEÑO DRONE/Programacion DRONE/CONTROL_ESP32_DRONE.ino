// ESP32: recibe por USB los valores enviados desde Python
// Formato recibido: pin25,pin26,pin27,pin32
// Ejemplo: 170,85,0,170

const int PIN_ELEVACION  = 25;
const int PIN_ROTACION   = 26;
const int PIN_VERTICAL   = 27;
const int PIN_HORIZONTAL = 32;

// Valores PWM que ya mediste
const int PWM_0V  = 0;
const int PWM_1V1 = 0;
const int PWM_2V2 = 170;

unsigned long ultimoMensaje = 0;

void centrarTodo() {
  analogWrite(PIN_ELEVACION, PWM_1V1);
  analogWrite(PIN_ROTACION, PWM_1V1);
  analogWrite(PIN_VERTICAL, PWM_1V1);
  analogWrite(PIN_HORIZONTAL, PWM_1V1);
}

void procesarMensaje(String mensaje) {
  int valor25;
  int valor26;
  int valor27;
  int valor32;

  int datosLeidos = sscanf(
    mensaje.c_str(),
    "%d,%d,%d,%d",
    &valor25,
    &valor26,
    &valor27,
    &valor32
  );

  if (datosLeidos == 4) {
    valor25 = constrain(valor25, 0, 255);
    valor26 = constrain(valor26, 0, 255);
    valor27 = constrain(valor27, 0, 255);
    valor32 = constrain(valor32, 0, 255);

    analogWrite(PIN_ELEVACION, valor25);
    analogWrite(PIN_ROTACION, valor26);
    analogWrite(PIN_VERTICAL, valor27);
    analogWrite(PIN_HORIZONTAL, valor32);

    ultimoMensaje = millis();
  }
}

void setup() {
  Serial.begin(115200);
  Serial.setTimeout(20);

  pinMode(PIN_ELEVACION, OUTPUT);
  pinMode(PIN_ROTACION, OUTPUT);
  pinMode(PIN_VERTICAL, OUTPUT);
  pinMode(PIN_HORIZONTAL, OUTPUT);

  // Al encender, todos quedan en 1.1 V
  centrarTodo();

  ultimoMensaje = millis();
}

void loop() {
  if (Serial.available() > 0) {
    String mensaje = Serial.readStringUntil('\n');
    mensaje.trim();

    if (mensaje.length() > 0) {
      procesarMensaje(mensaje);
    }
  }

  // Seguridad: si Python se cierra o se desconecta,
  // después de 500 ms todo regresa a 1.1 V
  if (millis() - ultimoMensaje > 500) {
    centrarTodo();
  }
}