const API = (process.env.EXPO_PUBLIC_API_URL || 'http://127.0.0.1:18080').replace(/\/$/, '');
export type Pagina<T> = { elementos: T[]; total: number; pagina: number; tamano: number };
export type Proveedor = { id: number; razonSocial: string; numeroDocumento: string; tipoDocumento: string; estadoCert: string };
export type Vehiculo = { id: number; placa: string; capacidadLitros: number };
export type Centro = { id: number; nombre: string; region: string; capacidadLitros: number };

export async function consultarCatalogo(token: string, tipo: 'proveedores' | 'vehiculos', buscar = '', pagina = 0): Promise<Pagina<Proveedor | Vehiculo>> {
  const datos = await consultar<Pagina<Proveedor | Vehiculo>>(token, `/api/catalogos/${tipo}?buscar=${encodeURIComponent(buscar)}&pagina=${pagina}&tamano=25`);
  if (!datos || !Array.isArray(datos.elementos) || !Number.isSafeInteger(datos.total) || datos.total < 0 || datos.pagina !== pagina || datos.tamano !== 25 ||
    !datos.elementos.every(item => item && Number.isSafeInteger(item.id) && item.id > 0 &&
      (tipo === 'proveedores' ? 'razonSocial' in item && typeof item.razonSocial === 'string' && typeof item.numeroDocumento === 'string' && typeof item.tipoDocumento === 'string' && typeof item.estadoCert === 'string'
        : 'placa' in item && typeof item.placa === 'string' && Number.isFinite(item.capacidadLitros))))
    throw new Error('El servidor devolvió un catálogo no válido.');
  return datos;
}
export async function consultarCentro(token: string): Promise<Centro> {
  const datos = await consultar<Centro>(token, '/api/catalogos/centro');
  if (!datos || !Number.isSafeInteger(datos.id) || datos.id <= 0 || typeof datos.nombre !== 'string' || typeof datos.region !== 'string' || !Number.isFinite(datos.capacidadLitros))
    throw new Error('El servidor devolvió un centro no válido.');
  return datos;
}
async function consultar<T>(token: string, ruta: string): Promise<T> {
  const control = new AbortController();
  const timer = setTimeout(() => control.abort(), 10000);
  try {
    const respuesta = await fetch(`${API}${ruta}`, {
      headers: { Authorization: `Bearer ${token}` }, signal: control.signal,
    });
    if (respuesta.status === 401) throw new Error('Tu sesión venció o dejó de ser válida. Vuelve al perfil, cierra sesión e ingresa nuevamente.');
    if (respuesta.status === 403) throw new Error('Tu cuenta no tiene permiso para consultar estos datos.');
    if (!respuesta.ok) throw new Error('No se pudo consultar el catálogo. Intenta nuevamente.');
    return await respuesta.json();
  } catch (error) {
    if (error instanceof Error && error.name === 'AbortError') throw new Error('El servidor tardó demasiado. Reintenta la consulta.');
    if (error instanceof TypeError) throw new Error('No se pudo contactar con el servidor. Tus borradores siguen en este celular.');
    if (error instanceof SyntaxError) throw new Error('El servidor devolvió una respuesta no válida.');
    throw error;
  } finally { clearTimeout(timer); }
}
