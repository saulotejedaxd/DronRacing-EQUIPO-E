function [P, C, caso] = caso_base_teorico(P, C, R)
%CASO_BASE_TEORICO Genera un dron numérico provisional.
%
% Este caso NO representa todavía el dron real.
%
% Hipótesis:
%   - Masa igual al máximo reglamentario.
%   - Configuración X simétrica.
%   - Cuatro masas puntuales iguales ubicadas en los motores.
%   - Centro de masa en el origen corporal.
%   - Motores en el mismo plano vertical del centro de masa.
%
% El objetivo es disponer de parámetros coherentes para desarrollar
% y validar inicialmente las ecuaciones dinámicas.
%
% Entradas:
%   P - Estructura de parámetros físicos.
%   C - Estructura de parámetros de diseño.
%   R - Restricciones reglamentarias.
%
% Salidas:
%   P    - Parámetros físicos actualizados.
%   C    - Geometría actualizada.
%   caso - Información y resultados del caso teórico.

    %% Metadatos

    caso.meta.nombre = ...
        "Caso límite teórico reglamentario";

    caso.meta.version = "0.1";

    caso.meta.tipo = ...
        "PROVISIONAL";

    caso.meta.descripcion = ...
        "Modelo equivalente de cuatro masas puntuales";

    caso.meta.representaDronReal = false;

    %% Masa total

    m = R.masa.maxima;                     % kg

    %% Geometría

    % Distancia desde el centro de masa hasta cada motor.
    L = R.geometria.distanciaCentroMotorMax; % m

    % Componente X/Y de cada brazo para configuración X.
    a = L / sqrt(2);                       % m

    % Motores en el mismo plano del centro de masa.
    zMotor_B = 0;                          % m

    %% Modelo equivalente de masas

    numeroMotores = 4;

    % Para este modelo teórico, la masa total se divide en cuatro
    % masas puntuales iguales colocadas en los ejes de motores.
    masaPuntual = m / numeroMotores;        % kg

    %% Tensor de inercia

    % Posiciones:
    %
    % M1 = [ a; -a; 0]
    % M2 = [ a;  a; 0]
    % M3 = [-a;  a; 0]
    % M4 = [-a; -a; 0]
    %
    % Para una masa puntual:
    %
    % Ixx = m_i * (y_i^2 + z_i^2)
    % Iyy = m_i * (x_i^2 + z_i^2)
    % Izz = m_i * (x_i^2 + y_i^2)

    Ixx = m * a^2;
    Iyy = m * a^2;
    Izz = m * L^2;

    % Por simetría, los productos de inercia son cero.
    Ixy = 0;
    Ixz = 0;
    Iyz = 0;

    inercia_B = [
         Ixx, -Ixy, -Ixz
        -Ixy,  Iyy, -Iyz
        -Ixz, -Iyz,  Izz
    ];

    %% Transferencia a los parámetros físicos

    P.cuerpo.masa = m;

    P.cuerpo.centroMasa_B = [
        0
        0
        0
    ];

    P.cuerpo.inercia_B = inercia_B;

    % En esta primera aproximación se omite el arrastre.
    % Cero significa que conscientemente se está despreciando;
    % no que el parámetro esté pendiente.
    P.aerodinamica.arrastreLineal_B = zeros(3, 1);
    P.aerodinamica.arrastreAngular_B = zeros(3, 1);

    %% Transferencia a los parámetros de diseño

    C.geometria.distanciaCentroMotor = L;
    C.geometria.zMotor_B = zMotor_B;

    C.meta.estado = "CASO TEORICO";

    %% Resultados del caso

    caso.masaTotal_kg = m;
    caso.numeroMasasPuntuales = numeroMotores;
    caso.masaPuntual_kg = masaPuntual;

    caso.distanciaCentroMotor_m = L;
    caso.componenteDiagonal_m = a;

    caso.inercia_B_kgm2 = inercia_B;

    caso.empujeHoverTotal_N = ...
        m * P.entorno.g;

    caso.empujeHoverPorMotor_N = ...
        caso.empujeHoverTotal_N / numeroMotores;

end