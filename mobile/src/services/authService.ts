export type SesionOperario = {
  accessToken: string;
  usuario: {
    id: number;
    nombre: string;
    rol: 'OPERARIO';
    idCentro: number;
    centro: string;
  };
};
const API = process.env.EXPO_PUBLIC_API_URL || 'http://127.0.0.1:18080';
const RUTA = process.env.EXPO_PUBLIC_AUTH_PATH || '/api/auth/login';
export async function iniciarSesion(email: string, password: string): Promise<SesionOperario> {
  if(!RUTA)
    throw new Error('El acceso de usuarios aún no está habilitado. Falta conectar la API de autenticación.');
  if(!RUTA.startsWith('/') || RUTA.startsWith('//'))
    throw new Error('La ruta de autenticación debe ser una ruta relativa de la API.');
  const control = new AbortController();
  const tiempo = setTimeout(() => control.abort(), 10000);
  try {
    const respuesta = await fetch(`${API}${RUTA}`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }), signal: control.signal,
    });
    if(respuesta.status === 401)
      throw new Error('Correo o contraseña incorrectos.');
    if(respuesta.status === 403)
      throw new Error('Tu cuenta no tiene acceso de operario. Consulta con el administrador.');
    if(respuesta.status === 404 || respuesta.status === 501)
      throw new Error('La API de autenticación todavía no está disponible.');
    if(respuesta.status === 429)
      throw new Error('Demasiados intentos. Espera antes de volver a intentar.');
    if(!respuesta.ok)
      throw new Error('No se pudo iniciar sesión. Intenta más tarde.');
    const datos = await respuesta.json();
    const usuario = datos?.usuario;
    if(typeof datos?.accessToken !== 'string' || !datos.accessToken.trim() ||
      !Number.isSafeInteger(usuario?.id) || usuario.id <= 0 ||
      typeof usuario?.nombre !== 'string' || !usuario.nombre.trim() ||
      !Number.isSafeInteger(usuario?.idCentro) || usuario.idCentro <= 0 ||
      typeof usuario?.centro !== 'string' || !usuario.centro.trim()) {
      throw new Error('La respuesta de acceso no coincide con el contrato acordado.');
    }
    if(usuario.rol !== 'OPERARIO')
      throw new Error('Esta aplicación requiere una cuenta de operario.');
    return datos as SesionOperario;
  }
  catch(error) {
    if(error instanceof Error && error.name === 'AbortError')
      throw new Error('El servidor tardó demasiado. Comprueba la conexión e intenta otra vez.');
    if(error instanceof TypeError)
      throw new Error('No se pudo contactar con el servidor. Revisa la conexión.');
    if(error instanceof SyntaxError)
      throw new Error('El servidor devolvió una respuesta de acceso no válida.');
    throw error;
  }
  finally {
    clearTimeout(tiempo);
  }
}
