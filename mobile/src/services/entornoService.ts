const API = process.env.EXPO_PUBLIC_API_URL || 'http://127.0.0.1:18080';

export async function consultarEstadoServidor(): Promise<{tablas: number}> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 10000);
  try {
    const respuesta = await fetch(`${API}/api/estado`, {signal: controller.signal});
    if (!respuesta.ok) throw new Error('Servidor no disponible');
    return await respuesta.json();
  } finally {
    clearTimeout(timer);
  }
}
