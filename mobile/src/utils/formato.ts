export const numero = (n: number) => n.toLocaleString('es-PE', { maximumFractionDigits: 4 });
export const fecha = (f: string) => new Date(f).toLocaleString('es-PE', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' });
