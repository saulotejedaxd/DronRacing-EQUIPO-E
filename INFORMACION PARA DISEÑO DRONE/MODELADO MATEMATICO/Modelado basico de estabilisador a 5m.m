clc
clear
close all

m = 1.2;
g = 9.81;

Kp = 12;
Ki = 2;
Kd = 6;

dt = 0.01;
t = 0:dt:40;

h_ref = 5;

h = 0;
v = 0;

integral = 0;
error_ant = 0;

altura = zeros(size(t));
empuje = zeros(size(t));

for i = 1:length(t)

    error = h_ref - h;

    integral = integral + error*dt;
    derivada = (error - error_ant)/dt;

    u = Kp*error + Ki*integral + Kd*derivada;

    T = m*g + u;

    if T < 0
        T = 0;
    end

    a = (T - m*g)/m;

    v = v + a*dt;
    h = h + v*dt;

    altura(i) = h;
    empuje(i) = T;

    error_ant = error;

end

figure
plot(t,altura,'b','LineWidth',2)
hold on
yline(h_ref,'r--')
xlabel('Tiempo (s)')
ylabel('Altura (m)')
title('Control de Altura del Dron')
grid on

figure
plot(t,empuje,'LineWidth',2)
xlabel('Tiempo (s)')
ylabel('Empuje (N)')
title('Empuje del Controlador')
grid on