import React, { useEffect, useMemo, useState } from 'react';
import { createRoot } from 'react-dom/client';
import 'bootstrap/dist/css/bootstrap.min.css';
import './style.css';

const DEMO_LOTS = [
  { id: 'L-001', supplier: 'G-001', center: 'CA-01', liters: 450, quality: 'APROBADO', tank: 'T-01', vehicle: 'ABC-123', operator: 'Operario de prueba', date: '2026-10-11 17:23:01', temperature: 4, acidity: 16, density: 1.03, destination: 'T-01', rule: 'Reglas DEMO-1 conformes' },
  { id: 'L-002', supplier: 'G-002', center: 'CA-01', liters: 280, quality: 'RECHAZADO', tank: '—', vehicle: 'XYZ-245', operator: 'Operario de prueba', date: '2026-10-11 17:23:01', temperature: 16, acidity: 22, density: 1.01, destination: '—', rule: 'Temperatura fuera del rango DEMO-1' }
];

const initialDemoUser = 'jefatura.demo';

function App() {
  const [page, setPage] = useState('login');
  const [username, setUsername] = useState(initialDemoUser);
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loginError, setLoginError] = useState('');
  const [apiData, setApiData] = useState(null);
  const [apiError, setApiError] = useState('');
  const [checking, setChecking] = useState(false);
  const [activeLotId, setActiveLotId] = useState('L-001');
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('Todos');
  const [centerFilter, setCenterFilter] = useState('Todos');
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');
  const [notice, setNotice] = useState('');

  const activeLot = DEMO_LOTS.find(lot => lot.id === activeLotId) || DEMO_LOTS[0];
  const filteredLots = useMemo(() => DEMO_LOTS.filter(lot => {
    const matchesSearch = `${lot.id} ${lot.supplier} ${lot.center} ${lot.vehicle}`.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'Todos' || lot.quality === statusFilter;
    const matchesCenter = centerFilter === 'Todos' || lot.center === centerFilter;
    const lotDate = lot.date.slice(0, 10);
    const matchesFrom = !fromDate || lotDate >= fromDate;
    const matchesTo = !toDate || lotDate <= toDate;
    return matchesSearch && matchesStatus && matchesCenter && matchesFrom && matchesTo;
  }), [search, statusFilter, centerFilter, fromDate, toDate]);

  async function checkApi() {
    setChecking(true);
    setApiError('');
    try {
      const response = await fetch('/api/estado', { signal: AbortSignal.timeout(10000) });
      if (!response.ok) throw new Error('Respuesta HTTP ' + response.status);
      setApiData(await response.json());
    } catch {
      setApiError('No se pudo consultar la API. Verifica que PostgreSQL y Spring Boot estén iniciados.');
      setApiData(null);
    } finally {
      setChecking(false);
    }
  }

  useEffect(() => { checkApi(); }, []);

  function signIn(event) {
    event.preventDefault();
    setLoginError('');
    if (username.trim() !== initialDemoUser || password.trim().length < 1) {
      setLoginError('Usa el usuario jefatura.demo e ingresa una contraseña de demostración.');
      return;
    }
    setPage('indicators');
    setNotice('Acceso de demostración iniciado como Jefatura de planta.');
  }

  function signOut() {
    setPage('login');
    setPassword('');
    setNotice('');
  }

  function exportCsv() {
    const rows = [
      ['Lote', 'Proveedor', 'Centro', 'Volumen (L)', 'Calidad', 'Tanque', 'Fecha'],
      ...filteredLots.map(lot => [lot.id, lot.supplier, lot.center, lot.liters, lot.quality, lot.tank, lot.date])
    ];
    const csv = '\uFEFF' + rows.map(row => row.map(value => `"${String(value).replaceAll('"', '""')}"`).join(';')).join('\r\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = 'reporte-operativo-demo.csv';
    anchor.click();
    URL.revokeObjectURL(url);
  }

  const pageTitle = { indicators: 'Resumen del acopio', incidents: 'Incidencias de calidad', traceability: 'Trazabilidad y calidad', reports: 'Reportes operativos' }[page];

  if (page === 'login') {
    return (
      <main className="login-shell">
        <section className="login-brand-panel">
          <div className="brand-mark"><span className="drop-mark">◆</span> ACOPIO</div>
          <p className="brand-subtitle">Trazabilidad de<br />Materia Prima Láctea</p>
          <div className="milk-art" aria-hidden="true">
            <span>ACOPIO</span><i>◒</i><b>◯</b></div>
          <p className="brand-foot">Recepción · Calidad · Trazabilidad</p>
        </section>
        <section className="login-form-panel">
          <form className="login-card" onSubmit={signIn}>
            <span className="demo-pill">Sesión de demostración</span>
            <h1>Iniciar sesión</h1>
            <p className="muted">Ingresa con la cuenta de prueba de este perfil. No utilices una contraseña personal.</p>
            <label htmlFor="username">Usuario</label>
            <input id="username" className="form-control" value={username} onChange={e => setUsername(e.target.value)} autoComplete="username" />
            <label htmlFor="password" className="mt-3">Contraseña</label>
            <div className="password-row">
              <input id="password" className="form-control" type={showPassword ? 'text' : 'password'} value={password} onChange={e => setPassword(e.target.value)} autoComplete="current-password" />
              <button className="btn btn-light reveal-button" type="button" onClick={() => setShowPassword(v => !v)}>{showPassword ? 'Ocultar' : 'Mostrar'}</button>
            </div>
            {loginError && <div className="alert alert-danger mt-3 mb-0">{loginError}</div>}
            <button className="btn btn-acopio w-100 mt-4" type="submit">Iniciar sesión</button>
            <details className="demo-details">
              <summary>Cuenta de prueba disponible</summary>
              <div className="demo-account"><strong>Usuario:</strong> jefatura.demo<br /><strong>Contraseña:</strong> cualquier texto de prueba</div>
            </details>
            <p className="login-note">El perfil se determina por la cuenta. Esta demo valida datos localmente; no autentica contra un servidor.</p>
          </form>
        </section>
      </main>
    );
  }

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="sidebar-brand"><span className="drop-mark">◆</span><span>ACOPIO</span></div>
        <div className="sidebar-caption">GESTIÓN DE PLANTA</div>
        <nav className="side-nav" aria-label="Navegación principal">
          <button className={page === 'indicators' ? 'active' : ''} onClick={() => setPage('indicators')}><span>▥</span> Indicadores</button>
          <button className={page === 'incidents' ? 'active' : ''} onClick={() => setPage('incidents')}><span>⚠</span> Incidencias</button>
          <button className={page === 'traceability' ? 'active' : ''} onClick={() => setPage('traceability')}><span>▧</span> Trazabilidad</button>
          <button className={page === 'reports' ? 'active' : ''} onClick={() => setPage('reports')}><span>▤</span> Reportes</button>
        </nav>
        <div className="sidebar-bottom"><span className="status-dot"></span> Modo demostración</div>
      </aside>

      <main className="main-area">
        <header className="topbar">
          <div><span className="topbar-label">SISTEMA DE ACOPIO</span><h1>{pageTitle}</h1></div>
          <div className="user-menu"><span className="avatar">J</span><span><strong>Jefatura de planta</strong><small>{initialDemoUser}</small></span><button className="btn btn-sm btn-outline-secondary" onClick={signOut}>Cerrar sesión</button></div>
        </header>

        <div className="content-area">
          <div className="demo-banner"><span>●</span><div><strong>Entorno de demostración</strong><small>Los lotes e indicadores de esta pantalla son ficticios y se usan para probar la interfaz.</small></div><button onClick={checkApi} disabled={checking}>{checking ? 'Comprobando…' : 'Comprobar API'}</button></div>
          {apiError && <div className="alert alert-warning mt-3" role="alert">{apiError}</div>}
          {notice && <div className="alert alert-success mt-3" role="status">{notice}<button className="notice-close" onClick={() => setNotice('')} aria-label="Cerrar">×</button></div>}

          {page === 'indicators' && (
            <>
              <div className="page-heading-row"><div><h2>Resumen del acopio</h2><p>Vista general · Solo registros de demostración confirmados</p></div><div className="toolbar-selects"><label>Período<select className="form-select form-select-sm" defaultValue="Hoy"><option>Hoy</option><option>Últimos 7 días</option><option>Últimos 30 días</option></select></label><label>Centro<select className="form-select form-select-sm" defaultValue="Todos"><option>Todos</option><option>CA-01</option><option>CA-02</option></select></label></div></div>
              <div className="metrics-grid">
                <Metric title="Recibido" value="730 L" icon="↘" tone="blue" note="Volumen de demostración" />
                <Metric title="Aprobado" value="450 L" icon="✓" tone="green" note="61.6% del volumen demo" />
                <Metric title="Rechazado" value="280 L" icon="×" tone="red" note="38.4% del volumen demo" />
                <Metric title="Tasa de rechazo" value="38.4%" icon="▥" tone="amber" note="Sobre 730 L ficticios" />
              </div>
              <div className="dashboard-grid">
                <section className="panel">
                  <PanelTitle title="Registros confirmados" subtitle="Lotes de ejemplo para probar la navegación" />
                  <LotTable lots={DEMO_LOTS} onSelect={id => { setActiveLotId(id); setPage('traceability'); }} />
                </section>
                <section className="panel">
                  <PanelTitle title="Ocupación de tanques" subtitle="Asignaciones de demostración" />
                  <TankBar name="T-01 · CA-01" current={450} capacity={1000} />
                  <TankBar name="T-02 · CA-01" current={0} capacity={2000} />
                  <TankBar name="T-03 · CA-02" current={0} capacity={1500} />
                  <p className="panel-footnote">La demo no modela vaciados, mezclas ni trasvases.</p>
                </section>
              </div>
            </>
          )}

          {page === 'incidents' && (
            <>
              <div className="page-heading-row"><div><h2>Incidencias de calidad</h2><p>Los lotes rechazados se conservan para consulta y reportes.</p></div><span className="count-chip">{DEMO_LOTS.filter(l => l.quality === 'RECHAZADO').length} incidencia demo</span></div>
              {DEMO_LOTS.filter(l => l.quality === 'RECHAZADO').map(lot => (
                <article className="incident-card" key={lot.id}>
                  <div className="incident-stripe"></div><div className="incident-content"><div className="incident-title-row"><h3>INC-{lot.id} · {lot.id}</h3><StatusBadge status={lot.quality} /></div><p className="incident-reason">{lot.rule}</p><p className="muted">{lot.supplier} · {lot.center} · {lot.liters} L</p><button className="btn btn-soft" onClick={() => { setActiveLotId(lot.id); setPage('traceability'); }}>Consultar lote</button></div>
                </article>
              ))}
              <div className="info-note">Las incidencias de esta vista son ficticias. La API de incidencias aún debe definirse e integrarse.</div>
            </>
          )}

          {page === 'traceability' && (
            <>
              <div className="page-heading-row"><div><h2>Trazabilidad y calidad</h2><p>Consulta la información y el historial de un lote.</p></div></div>
              <section className="panel trace-panel">
                <div className="trace-main">
                  <label htmlFor="lot-select" className="form-label">Seleccionar lote</label>
                  <select id="lot-select" className="form-select" value={activeLotId} onChange={e => setActiveLotId(e.target.value)}>{DEMO_LOTS.map(lot => <option key={lot.id} value={lot.id}>{lot.id} · {lot.supplier}</option>)}</select>
                  <div className="trace-lot-title"><h3>{activeLot.id}</h3><StatusBadge status={activeLot.quality} /></div>
                  <dl className="detail-list">
                    <Detail label="Proveedor" value={activeLot.supplier} />
                    <Detail label="Vehículo" value={activeLot.vehicle} />
                    <Detail label="Centro" value={activeLot.center} />
                    <Detail label="Operario" value={activeLot.operator} />
                    <Detail label="Fecha / hora" value={activeLot.date} />
                    <Detail label="Volumen" value={`${activeLot.liters} L`} />
                    <Detail label="Mediciones" value={`${activeLot.temperature} °C · ${activeLot.acidity} °D · ${activeLot.density.toFixed(2)} g/mL`} />
                    <Detail label="Destino" value={activeLot.destination} />
                  </dl>
                  <div className={activeLot.quality === 'APROBADO' ? 'rule-note good' : 'rule-note bad'}>{activeLot.rule}</div>
                </div>
                <div className="trace-side">
                  <h4>QR de identificación</h4><p className="muted">ACOPIO-DEMO-{activeLot.id}</p>
                  <div className="qr-placeholder" aria-label="Marcador de QR de demostración"><span>ACOPIO</span><b>{activeLot.id}</b><small>QR DEMO</small></div>
                  <p className="qr-note">Marcador visual de demostración; todavía no codifica una consulta real.</p>
                  <h4 className="history-title">Historial</h4>
                  <ol className="history-list"><li><strong>Registro recibido y evaluado: {activeLot.quality.toLowerCase()}</strong><small>{activeLot.date}</small></li>{activeLot.quality === 'APROBADO' && <li><strong>Asignado a {activeLot.destination}</strong><small>{activeLot.date}</small></li>}{activeLot.quality === 'RECHAZADO' && <li><strong>Incidencia registrada</strong><small>{activeLot.rule}</small></li>}</ol>
                </div>
              </section>
            </>
          )}

          {page === 'reports' && (
            <>
              <div className="page-heading-row"><div><h2>Reportes operativos</h2><p>Filtra y exporta los registros de demostración.</p></div></div>
              <section className="panel report-filters">
                <label>Estado<select className="form-select" value={statusFilter} onChange={e => setStatusFilter(e.target.value)}><option>Todos</option><option>APROBADO</option><option>RECHAZADO</option></select></label>
                <label>Centro<select className="form-select" value={centerFilter} onChange={e => setCenterFilter(e.target.value)}><option>Todos</option><option>CA-01</option><option>CA-02</option></select></label>
                <label>Desde<input className="form-control" type="date" value={fromDate} onChange={e => setFromDate(e.target.value)} /></label>
                <label>Hasta<input className="form-control" type="date" value={toDate} onChange={e => setToDate(e.target.value)} /></label>
                <label className="search-field">Buscar<input className="form-control" value={search} onChange={e => setSearch(e.target.value)} placeholder="Lote, proveedor, centro…" /></label>
                <div className="filter-actions"><button className="btn btn-acopio" onClick={() => setNotice(`${filteredLots.length} registro(s) de demostración encontrados.`)}>Aplicar filtros</button><button className="btn btn-soft" onClick={exportCsv}>Exportar CSV</button></div>
              </section>
              <section className="panel report-table-panel"><PanelTitle title="Resultados" subtitle={`${filteredLots.length} registro(s) · datos ficticios`} /><LotTable lots={filteredLots} onSelect={id => { setActiveLotId(id); setPage('traceability'); }} emptyMessage="No hay lotes que coincidan con los filtros." /></section>
            </>
          )}

          <footer className="app-footer"><span>ACOPIO · Sistema de trazabilidad de materia prima láctea</span><span>{apiData ? `API: ${apiData.baseDatos || 'conectada'}` : 'API sin confirmar'} · Interfaz de demostración</span></footer>
        </div>
      </main>
    </div>
  );
}

function Metric({ title, value, icon, tone, note }) {
  return <article className="metric-card"><div className={`metric-icon ${tone}`}>{icon}</div><div className="metric-title">{title}</div><div className="metric-value">{value}</div><div className="metric-note">{note}</div></article>;
}
function PanelTitle({ title, subtitle }) { return <div className="panel-title"><div><h3>{title}</h3>{subtitle && <p>{subtitle}</p>}</div></div>; }
function StatusBadge({ status }) { return <span className={`status-badge ${status.toLowerCase()}`}>{status}</span>; }
function Detail({ label, value }) { return <><dt>{label}</dt><dd>{value}</dd></>; }
function TankBar({ name, current, capacity }) {
  const percentage = Math.min(100, Math.round((current / capacity) * 100));
  return <div className="tank-row"><div className="tank-label"><strong>{name}</strong><span>{current.toLocaleString('es-PE')} / {capacity.toLocaleString('es-PE')} L</span></div><div className="tank-track"><div className="tank-fill" style={{ width: `${percentage}%` }} /></div></div>;
}
function LotTable({ lots, onSelect, emptyMessage = 'No hay registros disponibles.' }) {
  return <div className="table-responsive"><table className="table lot-table align-middle"><thead><tr><th>LOTE / PROVEEDOR</th><th>CENTRO</th><th>VOLUMEN</th><th>CALIDAD</th><th>TANQUE</th><th>DETALLE</th></tr></thead><tbody>{lots.length ? lots.map(lot => <tr key={lot.id}><td><strong>{lot.id}</strong><small>{lot.supplier}</small></td><td>{lot.center}</td><td>{lot.liters.toLocaleString('es-PE')} L</td><td><StatusBadge status={lot.quality} /></td><td>{lot.tank}</td><td><button className="btn btn-sm btn-soft" onClick={() => onSelect(lot.id)}>Consultar</button></td></tr>) : <tr><td colSpan="6" className="empty-cell">{emptyMessage}</td></tr>}</tbody></table></div>;
}

createRoot(document.getElementById('root')).render(<App />);
