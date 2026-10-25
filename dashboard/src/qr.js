import QRCode from 'qrcode';

export function lotQrValue(lot) {
  const code = lot?.raw?.codigoQr;
  return lot?.quality === 'APROBADO' && typeof code === 'string' && code.trim() ? code : null;
}

export async function createQrImage(value) {
  if (typeof value !== 'string' || !value.trim()) throw new Error('El lote no tiene un QR confirmado.');
  return QRCode.toDataURL(value, { type: 'image/png', width: 256, margin: 4, errorCorrectionLevel: 'M' });
}
