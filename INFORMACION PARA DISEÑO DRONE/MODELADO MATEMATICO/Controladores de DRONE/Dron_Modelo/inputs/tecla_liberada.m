function tecla_liberada(figura, evento)
%TECLA_LIBERADA Registra cuándo una tecla deja de estar presionada.
%
% CONTROLES CONTINUOS
%
%   W / S
%       Al soltarlas se detiene la modificación manual de altura.
%
%   Flechas
%       Al soltarlas se neutraliza el movimiento horizontal.
%
%   A / D
%       Al soltarlas se neutraliza el mando de yaw.
%
% COMANDOS DISCRETOS
%
%   Shift
%       Libera el bloqueo del comando "subir 1 metro".
%
%   Espacio
%       Libera el bloqueo del comando "bajar 1 metro".
%
%   X
%       Libera el bloqueo de desarmado.
%
%   Enter
%       Libera el bloqueo de armado.
%
%   R
%       Libera el bloqueo de reinicio.
%
% IMPORTANTE:
%
% Esta función no elimina las solicitudes:
%
%   solicitudSubirUnMetro
%   solicitudBajarUnMetro
%
% Esas solicitudes permanecerán activas hasta que
% leer_comando_teclado las consuma.

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
    % COMPATIBILIDAD CON VERSIONES ANTERIORES
    % =============================================================

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
        'subirThrottle', ...
        false ...
    );

    estado = asegurar_campo( ...
        estado, ...
        'bajarThrottle', ...
        false ...
    );

    estado = asegurar_campo( ...
        estado, ...
        'rollIzquierda', ...
        false ...
    );

    estado = asegurar_campo( ...
        estado, ...
        'rollDerecha', ...
        false ...
    );

    estado = asegurar_campo( ...
        estado, ...
        'pitchAdelante', ...
        false ...
    );

    estado = asegurar_campo( ...
        estado, ...
        'pitchAtras', ...
        false ...
    );

    estado = asegurar_campo( ...
        estado, ...
        'yawIzquierda', ...
        false ...
    );

    estado = asegurar_campo( ...
        estado, ...
        'yawDerecha', ...
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
    % PROCESAR TECLA LIBERADA
    % =============================================================

    switch tecla

        %% --------------------------------------------------------
        % CONTROL MANUAL DE ALTURA
        % ---------------------------------------------------------

        case 'w'

            estado.subirThrottle = false;

        case 's'

            estado.bajarThrottle = false;

        %% --------------------------------------------------------
        % MOVIMIENTO LATERAL
        % ---------------------------------------------------------

        case 'leftarrow'

            estado.rollIzquierda = false;

        case 'rightarrow'

            estado.rollDerecha = false;

        %% --------------------------------------------------------
        % MOVIMIENTO FRONTAL
        % ---------------------------------------------------------

        case 'uparrow'

            estado.pitchAdelante = false;

        case 'downarrow'

            estado.pitchAtras = false;

        %% --------------------------------------------------------
        % ROTACIÓN YAW
        % ---------------------------------------------------------

        case 'a'

            estado.yawIzquierda = false;

        case 'd'

            estado.yawDerecha = false;

        %% --------------------------------------------------------
        % LIBERAR BLOQUEO DE SHIFT
        % ---------------------------------------------------------

        case {'shift', 'leftshift', 'rightshift'}

            estado.bloqueoShift = false;

        %% --------------------------------------------------------
        % LIBERAR BLOQUEO DE ESPACIO
        % ---------------------------------------------------------

        case 'space'

            estado.bloqueoEspacio = false;

        %% --------------------------------------------------------
        % LIBERAR BLOQUEO DE X
        % ---------------------------------------------------------

        case 'x'

            estado.bloqueoX = false;

        %% --------------------------------------------------------
        % LIBERAR BLOQUEO DE ENTER
        % ---------------------------------------------------------

        case {'return', 'enter'}

            estado.bloqueoEnter = false;

        %% --------------------------------------------------------
        % LIBERAR BLOQUEO DE REINICIO
        % ---------------------------------------------------------

        case 'r'

            estado.bloqueoR = false;

    end

    %% ============================================================
    % GUARDAR ESTADO ACTUALIZADO
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
%ASEGURAR_CAMPO Agrega un campo cuando todavía no existe.

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
% Permite usar eventos reales de MATLAB o estructuras de prueba.

    if isstruct(objeto)

        resultado = ...
            isfield(objeto, nombre);

    else

        resultado = ...
            isprop(objeto, nombre);

    end

end