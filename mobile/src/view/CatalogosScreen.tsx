import { Text, TextInput, View } from 'react-native';
import { Button } from '../components/Button';
import { NoticeBox } from '../components/NoticeBox';
import type { Proveedor, Vehiculo } from '../services/catalogoService';
import type { SesionOperario } from '../services/authService';
import { useCatalogosViewModel } from '../viewmodel/useCatalogosViewModel';
import { screenStyles as s } from '../theme/screenStyles';

export function CatalogosScreen({ sesion, seleccionar }: { sesion: SesionOperario | null; seleccionar?: (item: Proveedor | Vehiculo) => void }) {
  const {tipo, setTipo, texto, setTexto, setBuscar, pagina, setPagina, setIntento, datos, centro, error, cargando} = useCatalogosViewModel(sesion);
  if (!sesion) return <NoticeBox variant="warning" message="Inicia sesión con tu cuenta de operario para consultar los catálogos del servidor. Puedes seguir creando borradores locales." />;
  return <>
    <Text style={s.title}>Catálogos de recepción</Text>
    <Text style={s.intro}>Consulta los datos activos del servidor.</Text>
    {centro && <View style={s.review}><Text style={s.caption}>Tu centro asignado</Text><Text style={s.detailValue}>{centro.nombre}</Text><Text style={s.caption}>{centro.region}</Text></View>}
    <View style={s.actions}>
      <Button title="Proveedores" variant={tipo === 'proveedores' ? 'primary' : 'outline'} onPress={() => { setTipo('proveedores'); setPagina(0); setBuscar(''); setTexto(''); }} />
      <Button title="Vehículos" variant={tipo === 'vehiculos' ? 'primary' : 'outline'} onPress={() => { setTipo('vehiculos'); setPagina(0); setBuscar(''); setTexto(''); }} />
    </View>
    <TextInput accessibilityLabel="Buscar en el catálogo" value={texto} onChangeText={setTexto} maxLength={180} placeholder={tipo === 'proveedores' ? 'Nombre o documento' : 'Placa del vehículo'} style={s.plainInput} autoCorrect={false} returnKeyType="search" onSubmitEditing={() => { setBuscar(texto.trim()); setPagina(0); setIntento(n => n + 1); }} />
    <Button title="Buscar" disabled={cargando} loading={cargando} onPress={() => { setBuscar(texto.trim()); setPagina(0); setIntento(n => n + 1); }} />
    {!!error && <><NoticeBox variant="error" message={error} /><Button title="Reintentar" variant="outline" onPress={() => setIntento(n => n + 1)} /></>}
    {datos && <>
      <Text accessibilityLiveRegion="polite" style={s.caption}>{datos.total} resultados · Página {pagina + 1}</Text>
      {datos.elementos.map(item => <View key={item.id} style={s.review}>
        <Text style={s.recordTitle}>{'razonSocial' in item ? item.razonSocial : item.placa}</Text>
        <Text style={s.caption}>{'razonSocial' in item ? `${item.tipoDocumento}: ${item.numeroDocumento} · Certificación: ${item.estadoCert}` : `Capacidad nominal: ${item.capacidadLitros} L`}</Text>
        {seleccionar && <Button title="Seleccionar" variant="outline" onPress={() => seleccionar(item)} />}
      </View>)}
      {!datos.elementos.length && <Text style={s.intro}>No se encontraron coincidencias.</Text>}
      <Button title="Página anterior" variant="outline" disabled={pagina === 0 || cargando} onPress={() => setPagina(n => n - 1)} />
      <Button title="Página siguiente" variant="outline" disabled={(pagina + 1) * datos.tamano >= datos.total || cargando} onPress={() => setPagina(n => n + 1)} />
    </>}
    <Text style={s.footnote}>Esta consulta no modifica ni envía los borradores guardados en el celular.</Text>
  </>;
}
