import { useRef, useState } from 'react';
import type { SesionOperario } from '../services/authService';
import { iniciarSesion } from '../services/authService';
export function useLoginViewModel() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [visible, setVisible] = useState(false);
  const [errores, setErrores] = useState<{
    email?: string;
    password?: string;
  }>({});
  const [error, setError] = useState('');
  const [ocupado, setOcupado] = useState(false);
  const bloqueo = useRef(false);
  async function entrar(): Promise<SesionOperario | null> {
    if(bloqueo.current)
      return null;
    const campos: {
      email?: string;
      password?: string;
    } = {};
    if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim()))
      campos.email = 'Ingresa un correo válido.';
    if(!password)
      campos.password = 'Ingresa tu contraseña.';
    setErrores(campos);
    setError('');
    if(Object.keys(campos).length)
      return null;
    bloqueo.current = true;
    setOcupado(true);
    try {
      const sesion = await iniciarSesion(email.trim(), password);
      setPassword('');
      return sesion;
    }
    catch(problema) {
      setError(problema instanceof Error ? problema.message : 'No se pudo iniciar sesión.');
      return null;
    }
    finally {
      setPassword('');
      bloqueo.current = false;
      setOcupado(false);
    }
  }
  return {
    email, password, visible, errores, error, ocupado, entrar,
    cambiarEmail: (valor: string) => { setEmail(valor); setErrores(anterior => ({ ...anterior, email: undefined })); setError(''); },
    cambiarPassword: (valor: string) => { setPassword(valor); setErrores(anterior => ({ ...anterior, password: undefined })); setError(''); },
    alternarVisible: () => setVisible(valor => !valor)
  };
}
