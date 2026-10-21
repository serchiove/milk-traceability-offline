import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import 'bootstrap/dist/css/bootstrap.min.css';
import './style.css';

function normalizeLot(item) {
  const supplier = item?.proveedor;
  const center = item?.centro;
  const operator = item?.operario;
  const tank = item?.tanque;

  const supplierName =
    typeof supplier === 'string'
      ? supplier
      : supplier?.razonSocial || supplier?.nombre || supplier?.id || '—';

  const centerName =
    typeof center === 'string'
      ? center
      : center?.nombre || center?.codigo || currentCenterLabel(item) || '—';

  const operatorName =
    typeof operator === 'string'
      ? operator
      : operator?.nombre || operator?.email || '—';

  const tankName =
    typeof tank === 'string'
      ? tank
      : tank?.codigo || tank?.nombre || '—';

  return {
    id: item?.idLote || item?.uuid || '—',
    supplier: supplierName,
    center: centerName,
    liters: Number(item?.volumenLitros ?? 0),
    quality: item?.estadoEvaluacion || item?.estado || 'PENDIENTE',
    tank: tankName,
    vehicle: item?.placa || item?.vehiculo?.placa || '—',
    operator: operatorName,
    date: item?.fechaHora || item?.fechaCaptura || item?.recibidoEn || '—',
    temperature: item?.temperaturaC ?? null,
    acidity: item?.acidezDornic ?? null,
    density: item?.densidadGml ?? null,
    destination: tankName,
    rule: [item?.motivo, item?.versionReglas].filter(Boolean).join(' · ') || 'Sin observación registrada',
    raw: item
  };
}

function currentCenterLabel(item) {
  return item?.centroNombre || item?.nombreCentro || '';
}

function App() {
  const [page, setPage] = useState('login');
  const [email, setEmail] = useState('jefatura@gloria.com.pe');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loginError, setLoginError] = useState('');
  const [loginLoading, setLoginLoading] = useState(false);
  const [accessToken, setAccessToken] = useState(null);
  const [currentUser, setCurrentUser] = useState(null);
  const [apiData, setApiData] = useState(null);
  const [apiError, setApiError] = useState('');
  const [checking, setChecking] = useState(false);
  const [lots, setLots] = useState([]);
  const [lotsLoading, setLotsLoading] = useState(false);
  const [lotsError, setLotsError] = useState('');
  const [totalLots, setTotalLots] = useState(0);
  const [lotsPage, setLotsPage] = useState(0);
  const lotsPageSize = 25;

  const [activeLotId, setActiveLotId] = useState('');
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('Todos');
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');
  const [notice, setNotice] = useState('');
  const [report, setReport] = useState(null);
  const [reportLoading, setReportLoading] = useState(false);
  const [reportError, setReportError] = useState('');
  const [tanks, setTanks] = useState([]);
  const [tanksLoading, setTanksLoading] = useState(false);
  const [tanksError, setTanksError] = useState('');
  const activeLot = lots.find(lot => lot.id === activeLotId) || lots[0] || null;
  const filteredLots = lots;

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

  async function signIn(event) {
    event.preventDefault();
    setLoginError('');

    const normalizedEmail = email.trim();
    if (!normalizedEmail || !password) {
      setLoginError('Ingresa tu correo electrónico y contraseña.');
      return;
    }

    setLoginLoading(true);
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: normalizedEmail, password })
      });

      const data = await response.json().catch(() => null);
      if (!response.ok) {
        throw new Error(data?.message || data?.error || `No se pudo iniciar sesión (HTTP ${response.status}).`);
      }

      const token = data?.accessToken;
      const usuario = data?.usuario;
      if (!token || !usuario) {
        throw new Error('La respuesta del servidor no contiene el token o los datos del usuario esperados.');
      }

      if (usuario.rol !== 'JEFATURA') {
        setAccessToken(null);
        setCurrentUser(null);
        setPassword('');
        throw new Error('Tu cuenta no tiene permisos de JEFATURA para acceder a este dashboard.');
      }

      setAccessToken(token);
      setCurrentUser(usuario);
      setPage('indicators');
      setNotice(`Sesión iniciada como ${usuario.nombre || 'Jefatura'}.`);
      setPassword('');
    } catch (error) {
      setLoginError(
        error instanceof TypeError
          ? 'No se pudo conectar con la API. Verifica que el backend esté iniciado.'
          : (error.message || 'Ocurrió un error al iniciar sesión.')
      );
    } finally {
      setLoginLoading(false);
    }
  }

  function signOut(message = '') {
    setAccessToken(null);
    setCurrentUser(null);
    setLots([]);
    setTotalLots(0);
    setPage('login');
    setPassword('');
    setLoginError(message);
    setNotice('');
  }

  // Usar esta función para todas las consultas privadas del dashboard.
  // Las rutas siguen siendo relativas para aprovechar el proxy de Vite.
  async function apiFetch(url, options = {}) {
    const headers = new Headers(options.headers || {});
    if (accessToken) headers.set('Authorization', `Bearer ${accessToken}`);

    const response = await fetch(url, { ...options, headers });
    if (response.status === 401) {
      signOut('Tu sesión venció o dejó de ser válida. Inicia sesión nuevamente.');
      throw new Error('Sesión no válida (HTTP 401).');
    }
    if (response.status === 403) {
      throw new Error('No tienes permisos para realizar esta operación (HTTP 403).');
    }
    return response;
  }

  // Consulta real de lotes: paginación y filtros se procesan en el servidor.
  useEffect(() => {
    if (!accessToken) {
      setLots([]);
      setTotalLots(0);
      setLotsError('');
      return;
    }

    const controller = new AbortController();

    async function loadLots() {
      setLotsLoading(true);
      setLotsError('');

      try {
        const params = new URLSearchParams({
          pagina: String(lotsPage),
          tamano: String(lotsPageSize)
        });

        if (statusFilter !== 'Todos') params.set('estado', statusFilter);
        if (fromDate) params.set('desde', fromDate);
        if (toDate) params.set('hasta', toDate);
        if (search.trim()) params.set('buscar', search.trim());

        const response = await apiFetch(`/api/lotes?${params.toString()}`, {
          signal: controller.signal
        });

        if (!response.ok) {
          const errorBody = await response.json().catch(() => null);
          throw new Error(
            errorBody?.message ||
            errorBody?.error ||
            `No se pudieron cargar los lotes (HTTP ${response.status}).`
          );
        }

        const data = await response.json();
        const items = Array.isArray(data?.elementos) ? data.elementos : [];

        const normalizedLots = items.map(normalizeLot);
        setLots(normalizedLots);
        setTotalLots(Number(data?.total ?? normalizedLots.length));

        setActiveLotId(currentId =>
          normalizedLots.some(lot => lot.id === currentId)
            ? currentId
            : (normalizedLots[0]?.id || '')
        );
      } catch (error) {
        if (error.name === 'AbortError') return;
        setLots([]);
        setTotalLots(0);
        setLotsError(error.message || 'No se pudieron cargar los lotes.');
      } finally {
        if (!controller.signal.aborted) setLotsLoading(false);
      }
    }

    loadLots();
    return () => controller.abort();
  }, [accessToken, lotsPage, search, statusFilter, fromDate, toDate]);

  // Indicadores e incidencias: mismos filtros que la tabla, calculados por el backend.
  useEffect(() => {
    if (!accessToken) {
      setReport(null);
      setReportError('');
      return;
    }
    const controller = new AbortController();
    async function loadReport() {
      setReportLoading(true);
      setReportError('');
      try {
        const params = new URLSearchParams();
        if (statusFilter !== 'Todos') params.set('estado', statusFilter);
        if (fromDate) params.set('desde', fromDate);
        if (toDate) params.set('hasta', toDate);
        if (search.trim()) params.set('buscar', search.trim());
        const suffix = params.toString() ? `?${params.toString()}` : '';
        const response = await apiFetch(`/api/reportes${suffix}`, { signal: controller.signal });
        if (!response.ok) throw new Error(`No se pudieron cargar los indicadores (HTTP ${response.status}).`);
        setReport(await response.json());
      } catch (error) {
        if (error.name !== 'AbortError') setReportError(error.message || 'No se pudo cargar el reporte.');
      } finally {
        if (!controller.signal.aborted) setReportLoading(false);
      }
    }
    loadReport();
    return () => controller.abort();
  }, [accessToken, search, statusFilter, fromDate, toDate]);

  // Tanques del centro autorizado de la sesión.
  useEffect(() => {
    if (!accessToken) {
      setTanks([]);
      setTanksError('');
      return;
    }
    const controller = new AbortController();
    async function loadTanks() {
      setTanksLoading(true);
      setTanksError('');
      try {
        const response = await apiFetch('/api/tanques?pagina=0&tamano=25', { signal: controller.signal });
        if (!response.ok) throw new Error(`No se pudieron cargar los tanques (HTTP ${response.status}).`);
        const data = await response.json();
        setTanks(Array.isArray(data?.elementos) ? data.elementos : []);
      } catch (error) {
        if (error.name !== 'AbortError') setTanksError(error.message || 'No se pudieron cargar los tanques.');
      } finally {
        if (!controller.signal.aborted) setTanksLoading(false);
      }
    }
    loadTanks();
    return () => controller.abort();
  }, [accessToken]);

  async function exportCsv() {
    try {
      const params = new URLSearchParams();
      if (statusFilter !== 'Todos') params.set('estado', statusFilter);
      if (fromDate) params.set('desde', fromDate);
      if (toDate) params.set('hasta', toDate);
      if (search.trim()) params.set('buscar', search.trim());
      const suffix = params.toString() ? `?${params.toString()}` : '';
      const response = await apiFetch(`/api/reportes/csv${suffix}`);
      if (!response.ok) throw new Error(`No se pudo descargar el CSV (HTTP ${response.status}).`);
      const blob = await response.blob();
      const url = URL.createObjectURL(blob);
      const anchor = document.createElement('a');
      anchor.href = url;
      anchor.download = 'acopio-reporte.csv';
      document.body.appendChild(anchor);
      anchor.click();
      anchor.remove();
      URL.revokeObjectURL(url);
      setNotice('Reporte CSV descargado desde el servidor.');
    } catch (error) {
      setNotice(error.message || 'No se pudo descargar el reporte CSV.');
    }
  }


  useEffect(() => {
    setLotsPage(0);
  }, [search, statusFilter, fromDate, toDate]);

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
            <span className="demo-pill">Acceso mediante API</span>
            <h1>Iniciar sesión</h1>
            <p className="muted">Ingresa con tu cuenta autorizada de Jefatura.</p>
            <label htmlFor="email">Correo electrónico</label>
            <input id="email" className="form-control" type="email" value={email} onChange={e => setEmail(e.target.value)} autoComplete="username" required />
            <label htmlFor="password" className="mt-3">Contraseña</label>
            <div className="password-row">
              <input id="password" className="form-control" type={showPassword ? 'text' : 'password'} value={password} onChange={e => setPassword(e.target.value)} autoComplete="current-password" />
              <button className="btn btn-light reveal-button" type="button" onClick={() => setShowPassword(v => !v)}>{showPassword ? 'Ocultar' : 'Mostrar'}</button>
            </div>
            {loginError && <div className="alert alert-danger mt-3 mb-0">{loginError}</div>}
            <button className="btn btn-acopio w-100 mt-4" type="submit" disabled={loginLoading}>
              {loginLoading ? 'Verificando acceso…' : 'Iniciar sesión'}
            </button>
            <details className="demo-details">
              <summary>Cuenta ficticia de desarrollo</summary>
              <div className="demo-account"><strong>Correo:</strong> jefatura@gloria.com.pe<br /><strong>Contraseña:</strong> 123456</div>
            </details>
            <p className="login-note">El servidor valida las credenciales y el rol. Usa esta cuenta únicamente en el entorno local de desarrollo.</p>
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
          <button className={page === 'indicators' ? 'active' : ''} onClick={() => setPage('indicators')}><span>◈</span> Indicadores</button>
          <button className={page === 'incidents' ? 'active' : ''} onClick={() => setPage('incidents')}><span>⚠ </span> Incidencias</button>
          <button className={page === 'traceability' ? 'active' : ''} onClick={() => setPage('traceability')}><span>◧</span> Trazabilidad</button>
          <button className={page === 'reports' ? 'active' : ''} onClick={() => setPage('reports')}><span>▤</span> Reportes</button>
        </nav>
        <div className="sidebar-bottom"><span className="status-dot"></span> Centro autorizado</div>
      </aside>

      <main className="main-area">
        <header className="topbar">
          <div><span className="topbar-label">SISTEMA DE ACOPIO</span><h1>{pageTitle}</h1></div>
          <div className="user-menu"><span className="avatar">{(currentUser?.nombre || 'J').charAt(0).toUpperCase()}</span><span><strong>{currentUser?.nombre || 'Jefatura de planta'}</strong><small>{currentUser?.centro || currentUser?.email || email}</small></span><button className="btn btn-sm btn-outline-secondary" onClick={() => signOut()}>Cerrar sesión</button></div>
        </header>

        <div className="content-area">
          <div className="demo-banner"><span>●</span><div><strong>Conexión con API</strong><small>Lotes, indicadores, tanques, incidencias y exportación consultan el backend.</small></div><button onClick={checkApi} disabled={checking}>{checking ? 'Comprobando…' : 'Comprobar API'}</button></div>
          {apiError && <div className="alert alert-warning mt-3" role="alert">{apiError}</div>}
          {lotsError && <div className="alert alert-danger mt-3" role="alert">{lotsError}</div>}
          {lotsLoading && <div className="alert alert-info mt-3" role="status">Cargando lotes desde el servidor…</div>}
          {notice && <div className="alert alert-success mt-3" role="status">{notice}<button className="notice-close" onClick={() => setNotice('')} aria-label="Cerrar">×</button></div>}

          {page === 'indicators' && (
            <>
              <div className="page-heading-row"><div><h2>Resumen del acopio</h2><p>Vista general · Lotes del centro autorizado de la sesión</p></div><div className="toolbar-selects"><label>Período<select className="form-select form-select-sm" defaultValue="Hoy"><option>Hoy</option><option>Últimos 7 días</option><option>Últimos 30 días</option></select></label><label>Centro<input className="form-control form-control-sm" value={currentUser?.centro || 'Centro autorizado'} readOnly /></label></div></div>
              <div className="metrics-grid">
                <Metric title="Recibido" value={`${formatNumber(report?.volumenLitros)} L`} icon="↘" tone="blue" note={reportLoading ? 'Actualizando…' : `${report?.total ?? 0} lotes del filtro actual`} />
                <Metric title="Aprobado" value={`${formatNumber(report?.volumenAprobadoLitros)} L`} icon="✓" tone="green" note={`${formatNumber(report?.porcentajeVolumenAprobado)}% del volumen`} />
                <Metric title="Rechazado" value={`${formatNumber(report?.volumenRechazadoLitros)} L`} icon="×" tone="red" note={`${formatNumber(report?.porcentajeVolumenRechazado)}% del volumen`} />
                <Metric title="Tasa de aprobación" value={`${formatNumber(report?.tasaAprobacion)}%`} icon="◈" tone="amber" note="Por cantidad de lotes, no por litros" />
              </div>
              {reportError && <div className="alert alert-danger" role="alert">{reportError}</div>}
              <div className="dashboard-grid">
                <section className="panel">
                  <PanelTitle title="Lotes recibidos" subtitle={`${totalLots} lote(s) encontrados en el servidor`} />
                  <LotTable lots={filteredLots} loading={lotsLoading} onSelect={id => { setActiveLotId(id); setPage('traceability'); }} />
                  <Pagination page={lotsPage} pageSize={lotsPageSize} total={totalLots} onChange={setLotsPage} />
                </section>
                <section className="panel">
                  <PanelTitle title="Ocupación de tanques" subtitle="Datos del centro autorizado" />
                  {tanksLoading ? <p className="empty-cell">Cargando tanques…</p> : tanksError ? <p className="text-danger">{tanksError}</p> : tanks.length ? tanks.map(tank => <TankBar key={tank.id} name={tank.codigo || `Tanque ${tank.id}`} current={Number(tank.volumenAsignadoLitros || 0)} capacity={Number(tank.capacidadLitros || 0)} available={Number(tank.disponibleLitros || 0)} />) : <p className="empty-cell">No hay tanques registrados para este centro.</p>}
                </section>
              </div>
            </>
          )}

          {page === 'incidents' && (
            <section className="panel">
              <PanelTitle title="Incidencias de calidad" subtitle={`${report?.incidencias?.length ?? 0} incidencia(s) en el filtro actual`} />
              {reportError && <div className="alert alert-danger">{reportError}</div>}
              {reportLoading ? <p className="empty-cell">Cargando incidencias…</p> : (report?.incidencias || []).length ? (
                <div className="table-responsive"><table className="table align-middle"><thead><tr><th>FECHA</th><th>LOTE</th><th>TIPO</th><th>DESCRIPCIÓN</th></tr></thead><tbody>
                  {report.incidencias.map((inc, index) => <tr key={`${inc.idLote}-${inc.id ?? index}`}><td>{formatDate(inc.fecha)}</td><td>{inc.idLote || '—'}</td><td>{inc.tipo || '—'}</td><td>{inc.descripcion || '—'}</td></tr>)}
                </tbody></table></div>
              ) : <p className="empty-cell">No hay incidencias para los filtros actuales.</p>}
            </section>
          )}

          {page === 'traceability' && (
            <>
              <div className="page-heading-row">
                <div>
                  <h2>Trazabilidad y calidad</h2>
                  <p>Consulta la información de un lote recibido.</p>
                </div>
              </div>

              {!activeLot ? (
                <section className="panel">
                  <p className="empty-cell">
                    {lotsLoading ? 'Cargando lotes…' : 'No hay lotes disponibles para consultar.'}
                  </p>
                </section>
              ) : (
                <section className="panel trace-panel">
                  <div className="trace-main">
                    <label htmlFor="lot-select" className="form-label">Seleccionar lote</label>
                    <select
                      id="lot-select"
                      className="form-select"
                      value={activeLotId}
                      onChange={event => setActiveLotId(event.target.value)}
                    >
                      {lots.map(lot => (
                        <option key={lot.id} value={lot.id}>
                          {lot.id} · {lot.supplier}
                        </option>
                      ))}
                    </select>

                    <div className="trace-lot-title">
                      <h3>{activeLot.id}</h3>
                      <StatusBadge status={activeLot.quality} />
                    </div>

                    <dl className="detail-list">
                      <Detail label="Proveedor" value={activeLot.supplier} />
                      <Detail label="Vehículo" value={activeLot.vehicle} />
                      <Detail label="Centro" value={activeLot.center} />
                      <Detail label="Operario" value={activeLot.operator} />
                      <Detail label="Fecha / hora" value={activeLot.date} />
                      <Detail label="Volumen" value={`${activeLot.liters} L`} />
                      <Detail
                        label="Mediciones"
                        value={`${activeLot.temperature ?? '—'} °C · ${activeLot.acidity ?? '—'} °D · ${activeLot.density == null ? '—' : Number(activeLot.density).toFixed(4)} g/mL`}
                      />
                      <Detail label="Destino" value={activeLot.destination} />
                    </dl>

                    <div className={activeLot.quality === 'APROBADO' ? 'rule-note good' : 'rule-note bad'}>
                      {activeLot.rule}
                    </div>
                  </div>

                  <div className="trace-side">
                    <h4>Identificación QR</h4>
                    {activeLot.raw?.codigoQr && activeLot.quality === 'APROBADO' ? (
                      <p className="muted">{activeLot.raw.codigoQr}</p>
                    ) : (
                      <p className="muted">No hay código QR disponible para este lote.</p>
                    )}
                    <p className="qr-note">
                      El detalle completo del lote y sus eventos se conectará mediante GET /api/lotes/{'{UUID}'}.
                    </p>
                  </div>
                </section>
              )}
            </>
          )}

          {page === 'reports' && (
            <>
              <div className="page-heading-row"><div><h2>Reportes operativos</h2><p>Filtra los lotes y descarga el reporte completo desde el servidor.</p></div></div>
              <section className="panel report-filters">
                <label>Estado<select className="form-select" value={statusFilter} onChange={e => setStatusFilter(e.target.value)}><option>Todos</option><option>APROBADO</option><option>RECHAZADO</option><option>PENDIENTE</option></select></label>
                <label>Centro autorizado<input className="form-control" value={currentUser?.centro || 'Centro de la sesión'} readOnly /></label>
                <label>Desde<input className="form-control" type="date" value={fromDate} onChange={e => setFromDate(e.target.value)} /></label>
                <label>Hasta<input className="form-control" type="date" value={toDate} onChange={e => setToDate(e.target.value)} /></label>
                <label className="search-field">Buscar<input className="form-control" value={search} onChange={e => setSearch(e.target.value)} placeholder="Lote, proveedor, centro…" /></label>
                <div className="filter-actions"><button className="btn btn-acopio" onClick={() => { setLotsPage(0); setNotice('Filtros consultados en el servidor.'); }}>Aplicar filtros</button><button className="btn btn-soft" onClick={exportCsv}>Exportar CSV</button></div>
              </section>
              <section className="panel report-table-panel"><PanelTitle title="Resultados" subtitle={`${totalLots} registro(s) en el servidor`} /><LotTable lots={filteredLots} loading={lotsLoading} onSelect={id =>{ setActiveLotId(id); setPage('traceability'); }} emptyMessage="No hay lotes que coincidan con los filtros." /><Pagination page={lotsPage} pageSize={lotsPageSize} total={totalLots} onChange={setLotsPage} /></section>
            </>
          )}

          <footer className="app-footer"><span>ACOPIO · Sistema de trazabilidad de materia prima láctea</span><span>{apiData ? `API: ${apiData.baseDatos || 'conectada'}` : 'API sin confirmar'} · Dashboard conectado</span></footer>
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
function formatNumber(value) {
  const number = Number(value ?? 0);
  return number.toLocaleString('es-PE', { maximumFractionDigits: 2 });
}
function formatDate(value) {
  if (!value) return '—';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? String(value) : date.toLocaleString('es-PE');
}
function TankBar({ name, current, capacity, available }) {
  const percentage = capacity > 0 ? Math.min(100, Math.round((current / capacity) * 100)) : 0;
  return <div className="tank-row"><div className="tank-label"><strong>{name}</strong><span>{formatNumber(current)} / {formatNumber(capacity)} L</span></div><div className="tank-track"><div className="tank-fill" style={{ width: `${percentage}%` }} /></div><small className="text-muted">Disponible: {formatNumber(available ?? Math.max(0, capacity - current))} L</small></div>;
}
function LotTable({ lots, onSelect, loading = false, emptyMessage = 'No hay registros disponibles.' }) {
  return (
    <div className="table-responsive">
      <table className="table lot-table align-middle">
        <thead>
          <tr>
            <th>LOTE / PROVEEDOR</th>
            <th>CENTRO</th>
            <th>VOLUMEN</th>
            <th>CALIDAD</th>
            <th>TANQUE</th>
            <th>DETALLE</th>
          </tr>
        </thead>
        <tbody>
          {loading ? (
            <tr><td colSpan="6" className="empty-cell">Cargando lotes…</td></tr>
          ) : lots.length ? (
            lots.map(lot => (
              <tr key={lot.id}>
                <td><strong>{lot.id}</strong><small>{lot.supplier}</small></td>
                <td>{lot.center}</td>
                <td>{Number(lot.liters || 0).toLocaleString('es-PE')} L</td>
                <td><StatusBadge status={lot.quality || 'PENDIENTE'} /></td>
                <td>{lot.tank}</td>
                <td><button className="btn btn-sm btn-soft" onClick={() => onSelect(lot.id)}>Consultar</button></td>
              </tr>
            ))
          ) : (
            <tr><td colSpan="6" className="empty-cell">{emptyMessage}</td></tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

function Pagination({ page, pageSize, total, onChange }) {
  const pageCount = Math.max(1, Math.ceil(total / pageSize));

  return (
    <div className="d-flex justify-content-between align-items-center px-3 pb-3">
      <small className="text-muted">
        Página {page + 1} de {pageCount} · {total} registro(s)
      </small>
      <div className="d-flex gap-2">
        <button
          className="btn btn-sm btn-outline-secondary"
          disabled={page <= 0}
          onClick={() => onChange(current => Math.max(0, current - 1))}
        >
          Anterior
        </button>
        <button
          className="btn btn-sm btn-outline-secondary"
          disabled={(page + 1) * pageSize >= total}
          onClick={() => onChange(current => current + 1)}
        >
          Siguiente
        </button>
      </div>
    </div>
  );
}

createRoot(document.getElementById('root')).render(<App />);