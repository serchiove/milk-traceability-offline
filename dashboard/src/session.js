export const SESSION_KEY = 'acopio.dashboard.session.v1';
const pages = ['indicators', 'incidents', 'traceability', 'reports'];

function browserStorage() {
  try { return globalThis.sessionStorage; } catch { return null; }
}

export function tokenExpiresAt(token) {
  try {
    if (typeof token !== 'string' || token.split('.').length !== 3) return 0;
    const payload = token.split('.')[1].replaceAll('-', '+').replaceAll('_', '/');
    const { exp } = JSON.parse(atob(payload.padEnd(Math.ceil(payload.length / 4) * 4, '=')));
    return typeof exp === 'number' && Number.isFinite(exp) && exp > 0 ? exp * 1000 : 0;
  } catch { return 0; }
}

function validSession(data, now) {
  const user = data?.usuario;
  return tokenExpiresAt(data?.accessToken) > now &&
    user?.rol === 'JEFATURA' && Number.isInteger(user.id) && user.id > 0 &&
    Number.isInteger(user.idCentro) && user.idCentro > 0 &&
    typeof user.nombre === 'string' && user.nombre.trim() &&
    typeof user.centro === 'string' && user.centro.trim();
}

function cleanSession(data) {
  const user = data.usuario;
  const view = data.view || {};
  return {
    accessToken: data.accessToken,
    usuario: { id: user.id, nombre: user.nombre, email: user.email, rol: user.rol, idCentro: user.idCentro, centro: user.centro },
    view: {
      page: pages.includes(view.page) ? view.page : 'indicators',
      activeLotId: typeof view.activeLotId === 'string' ? view.activeLotId : '',
      search: typeof view.search === 'string' ? view.search : '',
      statusFilter: ['Todos', 'APROBADO', 'RECHAZADO', 'PENDIENTE'].includes(view.statusFilter) ? view.statusFilter : 'Todos',
      fromDate: /^\d{4}-\d{2}-\d{2}$/.test(view.fromDate || '') ? view.fromDate : '',
      toDate: /^\d{4}-\d{2}-\d{2}$/.test(view.toDate || '') ? view.toDate : '',
      lotsPage: Number.isInteger(view.lotsPage) && view.lotsPage >= 0 ? view.lotsPage : 0
    }
  };
}

export function clearDashboardSession(storage = browserStorage()) {
  try { storage?.removeItem(SESSION_KEY); } catch { /* La sesión en memoria se cierra igualmente. */ }
}

export function readDashboardSession(storage = browserStorage(), now = Date.now()) {
  try {
    const data = JSON.parse(storage?.getItem(SESSION_KEY) || 'null');
    if (validSession(data, now)) return cleanSession(data);
  } catch { /* Una copia inválida no autoriza el acceso. */ }
  clearDashboardSession(storage);
  return null;
}

export function saveDashboardSession(data, storage = browserStorage(), now = Date.now()) {
  if (!validSession(data, now)) {
    clearDashboardSession(storage);
    return false;
  }
  try {
    if (!storage) return false;
    storage.setItem(SESSION_KEY, JSON.stringify(cleanSession(data)));
    return true;
  } catch { return false; }
}
