export type FormularioLote = {
  proveedor: string;
  vehiculo: string;
  centro: string;
  volumen: string;
  temperatura: string;
  acidez: string;
  densidad: string;
};
export type DatosLote = {
  proveedor: string;
  vehiculo: string;
  centro: string;
  volumen: number;
  temperatura: number;
  acidez: number;
  densidad: number;
};
export type LoteLocal = DatosLote & {
  id: string;
  fecha: string;
};
export type ErroresLote = Partial<Record<keyof FormularioLote, string>>;
export const formularioVacio = (): FormularioLote => ({
  proveedor: '', vehiculo: '', centro: '', volumen: '', temperatura: '', acidez: '', densidad: '',
});
export function validarLote(form: FormularioLote): {
  errores: ErroresLote;
  datos?: DatosLote;
} {
  const errores: ErroresLote = {};
  for(const campo of ['proveedor', 'vehiculo', 'centro'] as const) {
    if(!form[campo].trim())
      errores[campo] = 'Completa este campo.';
    else if(form[campo].trim().length > 180)
      errores[campo] = 'Usa como máximo 180 caracteres.';
  }
  const numeros = {} as Record<'volumen' | 'temperatura' | 'acidez' | 'densidad', number>;
  for(const campo of ['volumen', 'temperatura', 'acidez', 'densidad'] as const) {
    const valor = form[campo].trim().replace(',', '.');
    numeros[campo] = Number(valor);
    if(!/^-?\d+(?:\.\d+)?$/.test(valor) || !Number.isFinite(numeros[campo])) {
      errores[campo] = 'Ingresa un número válido, sin separadores de miles.';
    }
  }
  if(!errores.volumen && (numeros.volumen <= 0 || numeros.volumen > 9999999999.99))
    errores.volumen = 'Ingresa un volumen mayor que cero dentro del límite del modelo.';
  if(!errores.temperatura && (numeros.temperatura < -273.15 || numeros.temperatura > 9999.99))
    errores.temperatura = 'Temperatura fuera del límite numérico del modelo.';
  if(!errores.acidez && (numeros.acidez < 0 || numeros.acidez > 9999.99))
    errores.acidez = 'Ingresa una acidez entre 0 y 9999,99 °D.';
  if(!errores.densidad && (numeros.densidad <= 0 || numeros.densidad > 999.9999))
    errores.densidad = 'Ingresa una densidad mayor que cero dentro del límite del modelo.';
  for(const campo of ['volumen', 'temperatura', 'acidez', 'densidad'] as const) {
    const decimales = campo === 'densidad' ? 4 : 2;
    if(!errores[campo] && (form[campo].trim().replace(',', '.').split('.')[1]?.length ?? 0) > decimales)
      errores[campo] = `Usa como máximo ${decimales} decimales.`;
  }
  if(Object.keys(errores).length)
    return { errores };
  return { errores, datos: { proveedor: form.proveedor.trim(), vehiculo: form.vehiculo.trim().toUpperCase(), centro: form.centro.trim(), ...numeros } };
}
