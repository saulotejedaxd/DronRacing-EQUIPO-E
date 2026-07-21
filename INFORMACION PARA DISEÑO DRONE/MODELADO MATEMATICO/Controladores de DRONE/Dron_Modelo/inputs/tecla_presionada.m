function tecla_presionada(figura, evento)
%TECLA_PRESIONADA Registra las teclas presionadas.
%
% CONTROLES CONTINUOS
%
%   W / S
%       Modifican manualmente la referencia de altura.
%
%   Flecha arriba / abajo
%       Movimiento hacia adelante / atrás.
%
%   Flecha izquierda / derecha
%       Movimiento lateral.
%
%   A / D
%       Rotación yaw izquierda / derecha.
%
% COMANDOS DISCRETOS
%
%   Shift
%       Solicita subir exactamente 1 metro.
%
%   Espacio
%       Solicita bajar exactamente 1 metro.
%
%   X
%       Desarma y apaga los motores.
%
%   Enter
%       Arma los motores.
%
%   R
%       Reinicia la simulación.
%
%   Escape
%       Cierra la simulación.
%
% Los comandos discretos utilizan bloqueos para generar una sola
% solicitud por cada pulsación física.

    %% ============================================================
    % VALIDAR FIGURA
    % =============================================================

    if ~isgraphics(figura, 'figure')

        return;

    end

    %% ============================================================
    % CREAR ESTADO SI NO EXISTE
    % =============================================================

    if ~isappdata(figura, 'estadoTeclado')

        setappdata( ...
            figura, ...
            'estadoTeclado', ...
            crear_estado_teclado() ...
        );

    end

    estado = getappdata( ...
        figura, ...
        'estadoTeclado' ...
    );

    %% ============================================================
    % COMPATIBILIDAD CON ESTADOS ANTERIORES
    % =============================================================

    % Esta sección evita errores si la figura todavía contiene un
    % estado creado por una versión anterior del teclado.

    estado = asegurar_campo( ...
        estado, ...
        'solicitudSubirUnMetro', ...
        false ...
    );

    estado = asegurar_campo( ...
        estado, ...
        'solicitudBajarUnMetro', ...
        false ...
    );

    estado = asegurar_campo( ...
        estado, ...
        'bloqueoShift', ...
        false ...
    );

    estado = asegurar_campo( ...
        estado, ...
        'bloqueoEspacio', ...
        false ...
    );

    estado = asegurar_campo( ...
        estado, ...
        'bloqueoX', ...
        false ...
    );

    estado = asegurar_campo( ...
        estado, ...
        'bloqueoEnter', ...
        false ...
    );

    estado = asegurar_campo( ...
        estado, ...
        'bloqueoR', ...
        false ...
    );

    estado = asegurar_campo( ...
        estado, ...
        'armado', ...
        false ...
    );

    estado = asegurar_campo( ...
        estado, ...
        'resetSolicitado', ...
        false ...
    );

    estado = asegurar_campo( ...
        estado, ...
        'salirSolicitado', ...
        false ...
    );

    %% ============================================================
    % VALIDAR EVENTO
    % =============================================================

    if isempty(evento) || ...
            ~isprop_o_campo(evento, 'Key')

        return;

    end

    tecla = lower( ...
        char(evento.Key) ...
    );

    %% ============================================================
    % PROCESAR TECLA
    % =============================================================

    switch tecla

        %% --------------------------------------------------------
        % CONTROL MANUAL DE ALTURA
        % ---------------------------------------------------------

        case 'w'

            estado.subirThrottle = true;

        case 's'

            estado.bajarThrottle = true;

        %% --------------------------------------------------------
        % MOVIMIENTO LATERAL
        % ---------------------------------------------------------

        case 'leftarrow'

            estado.rollIzquierda = true;

        case 'rightarrow'

            estado.rollDerecha = true;

        %% --------------------------------------------------------
        % MOVIMIENTO FRONTAL
        % ---------------------------------------------------------

        case 'uparrow'

            estado.pitchAdelante = true;

        case 'downarrow'

            estado.pitchAtras = true;

        %% --------------------------------------------------------
        % ROTACIÓN YAW
        % ---------------------------------------------------------

        case 'a'

            estado.yawIzquierda = true;

        case 'd'

            estado.yawDerecha = true;

        %% --------------------------------------------------------
        % SHIFT: SUBIR EXACTAMENTE 1 METRO
        % ---------------------------------------------------------

        case {'shift', 'leftshift', 'rightshift'}

            if ~estado.bloqueoShift

                % La solicitud queda activa hasta que
                % leer_comando_teclado la consuma.

                estado.solicitudSubirUnMetro = true;

                estado.bloqueoShift = true;

            end

        %% --------------------------------------------------------
        % ESPACIO: BAJAR EXACTAMENTE 1 METRO
        % ---------------------------------------------------------

        case 'space'

            if ~estado.bloqueoEspacio

                estado.solicitudBajarUnMetro = true;

                estado.bloqueoEspacio = true;

            end

        %% --------------------------------------------------------
        % X: APAGAR Y DESARMAR
        % ---------------------------------------------------------

        case 'x'

            if ~estado.bloqueoX

                estado.armado = false;

                estado.bloqueoX = true;

                % Eliminar órdenes pendientes para que no se ejecute
                % una maniobra automática después de desarmar.

                estado.solicitudSubirUnMetro = false;
                estado.solicitudBajarUnMetro = false;

                % Neutralizar controles continuos.

                estado.subirThrottle = false;
                estado.bajarThrottle = false;

                estado.rollIzquierda = false;
                estado.rollDerecha = false;

                estado.pitchAdelante = false;
                estado.pitchAtras = false;

                estado.yawIzquierda = false;
                estado.yawDerecha = false;

            end

        %% --------------------------------------------------------
        % ENTER: ARMAR
        % ---------------------------------------------------------

        case {'return', 'enter'}

            if ~estado.bloqueoEnter

                estado.armado = true;

                estado.bloqueoEnter = true;

            end

        %% --------------------------------------------------------
        % R: REINICIAR
        % ---------------------------------------------------------

        case 'r'

            if ~estado.bloqueoR

                estado.resetSolicitado = true;

                estado.bloqueoR = true;

            end

        %% --------------------------------------------------------
        % ESCAPE: SALIR
        % ---------------------------------------------------------

        case 'escape'

            estado.salirSolicitado = true;

    end

    %% ============================================================
    % GUARDAR ESTADO
    % =============================================================

    setappdata( ...
        figura, ...
        'estadoTeclado', ...
        estado ...
    );

end


function estructura = asegurar_campo( ...
    estructura, ...
    nombreCampo, ...
    valorPredeterminado ...
)
%ASEGURAR_CAMPO Agrega un campo únicamente cuando no existe.

    if ~isfield(estructura, nombreCampo)

        estructura.(nombreCampo) = ...
            valorPredeterminado;

    end

end


function resultado = isprop_o_campo( ...
    objeto, ...
    nombre ...
)
%ISPROP_O_CAMPO
% Permite utilizar tanto el evento real de MATLAB como una estructura
% creada manualmente durante las pruebas.

    if isstruct(objeto)

        resultado = ...
            isfield(objeto, nombre);

    else

        resultado = ...
            isprop(objeto, nombre);

    end

end