export type SolicitudLote = {
  idLote: string; idProveedor: number; idVehiculo: number; volumenLitros: number; fechaHora: string;
  mediciones: { temperaturaC: number; acidezDornic: number; densidadGml: number };
};
export type ResultadoEnvio = { idLote: string; estadoEvaluacion: 'APROBADO' | 'RECHAZADO' | 'PENDIENTE'; motivo: string | null; codigoQr: string | null; versionReglas: string | null; recibidoEn: string; idempotente: boolean };
export type EnvioLocal = { id: string; usuario: number; centro: number; solicitud: SolicitudLote; resultado: ResultadoEnvio | null };
