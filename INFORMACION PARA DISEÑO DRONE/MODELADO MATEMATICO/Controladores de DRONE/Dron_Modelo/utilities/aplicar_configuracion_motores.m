function P = aplicar_configuracion_motores(P, G)
%APLICAR_CONFIGURACION_MOTORES Transfiere la geometría a P.

    P.motores.numero = G.numeroMotores;

    P.motores.posicion_B = ...
        G.posicionMotores_B;

    P.motores.sentidoGiro = ...
        G.sentidoGiro;

    P.motores.signoTorqueYawCuerpo = ...
        G.signoTorqueYawCuerpo;

end