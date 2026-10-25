import React, { useEffect, useState } from 'react';
import { createQrImage, lotQrValue } from './qr.js';
import './qr.css';

export default function LotQr({ lot }) {
  const value = lotQrValue(lot);
  const [image, setImage] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    setImage(null);
    setError(null);
    if (value) {
      createQrImage(value).then(src => {
        if (!cancelled) setImage({ value, src });
      }).catch(() => {
        if (!cancelled) setError(value);
      });
    }
    return () => { cancelled = true; };
  }, [value]);

  if (!value) return <p className="muted">No hay código QR disponible para este lote.</p>;
  const ready = image?.value === value;
  return <div className="lot-qr">
    {ready ? <img src={image.src} width="256" height="256" alt={`Código QR del lote ${lot.id}`} />
      : error === value ? <p role="alert">No se pudo generar la imagen QR. Vuelve a consultar el lote.</p>
      : <p role="status">Generando código QR…</p>}
    <p className="qr-code-value">{value}</p>
    {ready && <a className="btn btn-sm btn-outline-secondary" href={image.src} download={`acopio-${lot.id}.png`}>Descargar QR</a>}
    <p className="qr-note">Escanéalo desde Central en la app para consultar este lote. El código corresponde al valor confirmado por el servidor.</p>
  </div>;
}
