import React, { useEffect, useRef, useState } from 'react';

const todayLima = () => new Intl.DateTimeFormat('sv-SE', {
  timeZone: 'America/Lima', year: 'numeric', month: '2-digit', day: '2-digit'
}).format(new Date());
const number = value => Number(value || 0).toLocaleString('es-PE', { maximumFractionDigits: 2 });
const liters = value => `${number(value)} L`;
const localTime = value => new Date(value).toLocaleString('es-PE', { timeZone: 'America/Lima' });
async function check(response) {
  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    throw new Error(data.mensaje || `No se pudo completar la operación (HTTP ${response.status}).`);
  }
  return response;
}

export default function DailySummary({ apiFetch }) {
  const [date, setDate] = useState(todayLima);
  const [preview, setPreview] = useState(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState('');
  const [refresh, setRefresh] = useState(0);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const api = useRef(apiFetch);
  useEffect(() => { api.current = apiFetch; }, [apiFetch]);
  useEffect(() => {
    let active = true;
    const controller = new AbortController();
    setPreview(null); setError(''); setMessage('');
    if (!date) { setLoading(false); return () => controller.abort(); }
    setLoading(true);
    (async () => {
      try {
        const response = await check(await api.current(`/api/reportes/diario?fecha=${encodeURIComponent(date)}`, {
          signal: AbortSignal.any([controller.signal, AbortSignal.timeout(20000)])
        }));
        const data = await response.json();
        if (active) setPreview(data);
      } catch (e) { if (active) setError(e.message || 'No se pudo cargar el resumen.'); }
      finally { if (active) setLoading(false); }
    })();
    return () => { active = false; controller.abort(); };
  }, [date, refresh]);

  async function act(action) {
    setBusy(action); setError(''); setMessage('');
    try {
      if (action === 'send') {
        const response = await check(await api.current('/api/reportes/diario/correo', {
          method: 'POST', headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ fecha: date })
        }));
        const result = await response.json();
        setMessage(`${result.mensaje} Destinatario: ${result.destinatario}`);
      } else {
        const response = await check(await api.current(`/api/reportes/diario/pdf?fecha=${encodeURIComponent(date)}`));
        const url = URL.createObjectURL(await response.blob());
        const link = document.createElement('a');
        link.href = url; link.download = `acopio-resumen-${date}.pdf`;
        document.body.appendChild(link); link.click(); link.remove();
        setTimeout(() => URL.revokeObjectURL(url), 1000);
      }
    } catch (e) { setError(e.message); }
    finally { setBusy(''); }
  }
  const summary = preview?.resumen;
  const report = summary?.reporte;
  const disabled = loading || Boolean(busy);
  return <section className="daily-page" aria-labelledby="daily-summary-title">
    <div className="page-heading-row daily-heading">
      <div><span className="daily-eyebrow">CIERRE OPERATIVO</span><h2 id="daily-summary-title">Resumen diario</h2><p>Los resultados de tu centro, listos para revisar, descargar y compartir.</p></div>
      <div className="daily-date-tools"><label htmlFor="daily-date">Fecha de captura<input id="daily-date" className="form-control" type="date" value={date} max={todayLima()} disabled={Boolean(busy)} onChange={e => setDate(e.target.value)} /></label>
        <button className="btn btn-soft" disabled={disabled || !date} onClick={() => setRefresh(value => value + 1)}>Actualizar resumen</button></div>
    </div>
    {error && <div className="alert alert-danger" role="alert">{error}</div>}
    {message && <div className="alert alert-success" role="status">{message}</div>}
    {loading && <div className="panel daily-loading" role="status">Cargando resumen y configuración de correo…</div>}
    {summary && <>
      <section className="panel daily-mail" aria-label="Configuración de correo del centro">
        <div className="daily-mail-header"><div><span className="daily-eyebrow">ENVÍO MANUAL POR GMAIL</span><h3>Correo del resumen</h3></div><span className={`daily-mail-status ${preview.correoDisponible ? 'ready' : 'pending'}`}>{preview.correoDisponible ? 'Configuración disponible' : 'Configuración pendiente'}</span></div>
        <div className="daily-address-grid"><div><span>Remitente</span><strong>{preview.remitente || 'Sin configurar'}</strong><small>Cuenta que envía el reporte</small></div><div><span>Destinatario autorizado</span><strong>{summary.destinatario}</strong><small>Configurado para {summary.centro}</small></div></div>
        {!preview.correoDisponible && <p className="daily-mail-hint">Completa la configuración de Gmail en el equipo y reinicia el backend. La descarga PDF ya está disponible.</p>}
        <div className="daily-mail-actions"><p>El correo incluye los indicadores del día y el reporte PDF adjunto. Se envía únicamente al pulsar el botón.</p><div><button className="btn btn-soft" disabled={disabled} onClick={() => act('pdf')}>{busy === 'pdf' ? 'Descargando…' : 'Descargar resumen PDF'}</button><button className="btn btn-acopio" disabled={disabled || !preview.correoDisponible} onClick={() => act('send')}>{busy === 'send' ? 'Enviando…' : 'Enviar resumen por correo'}</button></div></div>
      </section>
      <div className="daily-cutoff"><strong>{summary.centro}</strong><span>Corte: {localTime(summary.corte)} · Lima</span></div>
      <div className="metrics-grid daily-metrics">
        {[['Recibido', report.total, report.volumenLitros, 'blue'], ['Aprobado', report.aprobados, report.volumenAprobadoLitros, 'green'], ['Rechazado', report.rechazados, report.volumenRechazadoLitros, 'red'], ['Pendiente', report.pendientes, report.volumenPendienteLitros, 'amber']].map(([label, count, volume, tone]) => <article className="metric-card" key={label}><div className={`metric-icon ${tone}`} aria-hidden="true">{tone === 'green' ? '✓' : tone === 'red' ? '×' : tone === 'amber' ? '◷' : '↘'}</div><div className="metric-title">{label}</div><div className="metric-value">{liters(volume)}</div><div className="metric-note">{number(count)} recepción(es)</div></article>)}
      </div>
      {report.total === 0 && <div className="info-note">No hay recepciones sincronizadas para esta fecha. Puedes elegir otro día para consultar registros anteriores.</div>}
      <div className="daily-detail-grid">
        <section className="panel"><div className="panel-title"><div><h3>Motivos de rechazo</h3><p>Recepciones que requieren revisión</p></div></div>{summary.motivosRechazo.length ? <ul className="daily-groups">{summary.motivosRechazo.map(g => <li key={g.nombre}><span>{g.nombre}<small>{g.recepciones} recepción(es)</small></span><strong>{liters(g.litros)}</strong></li>)}</ul> : <p className="muted">Sin rechazos registrados.</p>}</section>
        <section className="panel"><div className="panel-title"><div><h3>Distribución por tanque</h3><p>Litros de las recepciones de la fecha seleccionada</p></div></div>{summary.tanques.length ? <ul className="daily-groups">{summary.tanques.map(g => <li key={g.nombre}><span>{g.nombre}<small>{g.recepciones} recepción(es)</small></span><strong>{liters(g.litros)}</strong></li>)}</ul> : <p className="muted">Sin asignaciones para mostrar.</p>}</section>
      </div>
      <section className="panel daily-receipts"><div className="panel-title"><div><h3>Detalle de recepciones</h3><p>{report.total > 10 ? `Primeras 10 de ${report.total}. El PDF contiene el detalle completo.` : `${report.total} recepción(es) en el resumen.`}</p></div></div><div className="table-responsive"><table className="table lot-table"><thead><tr><th>LOTE / PRODUCTOR</th><th>HORA DE CAPTURA</th><th>LITROS</th><th>CALIDAD</th><th>TANQUE</th></tr></thead><tbody>{report.registros.slice(0, 10).map(lot => <tr key={lot.idLote}><td><strong>{lot.proveedor}</strong><small>{lot.idLote.slice(0, 8)}</small></td><td>{localTime(lot.fechaHora)}</td><td>{liters(lot.volumenLitros)}</td><td><span className={`status-badge ${lot.estadoEvaluacion.toLowerCase()}`}>{lot.estadoEvaluacion}</span></td><td>{lot.tanque || 'Sin asignar'}</td></tr>)}{!report.total && <tr><td colSpan="5" className="empty-cell">Sin recepciones en la fecha seleccionada.</td></tr>}</tbody></table></div></section>
      <p className="daily-footnote">Incluye capturas de esta fecha sincronizadas al consultar. No incluye registros pendientes en los teléfonos. El PDF y el envío consultan de nuevo y pueden incorporar nuevas sincronizaciones. Los litros por tanque no representan su ocupación acumulada.</p>
    </>}
  </section>;
}
