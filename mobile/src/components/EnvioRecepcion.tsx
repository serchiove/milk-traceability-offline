import { QrLote } from './QrLote';
import { useState } from 'react';
import { Alert, Modal, ScrollView, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import type { LoteLocal } from '../model/lote';
import type { SesionOperario } from '../services/authService';
import { useEnvioViewModel } from '../viewmodel/useEnvioViewModel';
import { CatalogosScreen } from '../view/CatalogosScreen';
import { Button } from './Button';
import { NoticeBox } from './NoticeBox';
import { screenStyles as s } from '../theme/screenStyles';
export function EnvioRecepcion({ lote, sesion, actualizado }: { lote: LoteLocal; sesion: SesionOperario | null; actualizado: () => void }) {
  const vm = useEnvioViewModel(lote, sesion, actualizado);
  const [catalogo, setCatalogo] = useState(false);
  const resultado = vm.envio?.resultado;
  function confirmar() {
    Alert.alert('Confirmar envío al servidor', `Operario: ${sesion?.usuario.nombre}\nCentro de destino: ${sesion?.usuario.centro}\nProveedor: ${vm.proveedor?.razonSocial ?? `ID ${vm.envio?.solicitud.idProveedor}`}\nVehículo: ${vm.vehiculo?.placa ?? `ID ${vm.envio?.solicitud.idVehiculo}`}\n\nConfirma que estos datos corresponden a la recepción local. El servidor evaluará su calidad.`, [
      {text: 'Cancelar', style: 'cancel'}, {text: 'Enviar', onPress: () => {void vm.enviar();}},
    ]);
  }
  return <View style={s.actions}>
    <Text style={s.sectionTitle}>Envío al servidor</Text>
    {!!vm.error && <NoticeBox variant="error" message={vm.error} />}
    {!vm.listo && <Button title="Leer estado del envío" variant="outline" onPress={vm.reintentar} />}
    {resultado ? <>
      <NoticeBox variant={resultado.estadoEvaluacion === 'RECHAZADO' ? 'warning' : 'success'} title="Recepción confirmada por el servidor" message={`Calidad: ${resultado.estadoEvaluacion}${resultado.motivo ? ` · ${resultado.motivo}` : ''}`} />
      <Text style={s.caption}>Reglas: {resultado.versionReglas ?? 'Sin evaluación'} · Recibido: {resultado.recibidoEn}</Text>
      {resultado.estadoEvaluacion==='APROBADO' && resultado.codigoQr && <QrLote codigo={resultado.codigoQr}/>}
    </> : !sesion ? <Text style={s.intro}>Inicia sesión para enviar esta recepción. Se conserva en este celular.</Text> : !vm.propio ? <NoticeBox variant="warning" message="El envío pertenece a otro operario o centro. Ingresa con la cuenta original para reintentarlo." /> : <>
      <Text style={s.caption}>Destino: {sesion.usuario.centro} · Operario: {sesion.usuario.nombre}</Text>
      {!vm.envio ? <>
        <Text style={s.intro}>Vincula el borrador con los datos oficiales antes del primer envío.</Text>
        <Text style={s.caption}>Proveedor: {vm.proveedor?.razonSocial ?? 'Por seleccionar'}</Text>
        <Text style={s.caption}>Vehículo: {vm.vehiculo?.placa ?? 'Por seleccionar'}</Text>
        <Button title="Seleccionar proveedor y vehículo" variant="outline" disabled={!vm.listo || vm.ocupado} onPress={() => setCatalogo(true)} />
      </> : <Text style={s.caption}>Envío preparado con los datos originales. El reintento conserva su identificador para evitar duplicados.</Text>}
      <Button title={vm.envio ? 'Enviar o confirmar recepción' : 'Enviar recepción'} loading={vm.ocupado} disabled={!vm.listo || vm.ocupado || (!vm.envio && (!vm.proveedor || !vm.vehiculo))} onPress={confirmar} />
    </>}
    <Modal visible={catalogo} animationType="slide" onRequestClose={() => setCatalogo(false)}>
      <SafeAreaView style={s.root}><ScrollView contentContainerStyle={s.page} keyboardShouldPersistTaps="handled">
        <Button title="Volver a la recepción" variant="outline" onPress={() => setCatalogo(false)} />
        <Text style={s.caption}>Proveedor: {vm.proveedor?.razonSocial ?? 'Pendiente'} · Vehículo: {vm.vehiculo?.placa ?? 'Pendiente'}</Text>
        <CatalogosScreen sesion={sesion} seleccionar={item => { if ('razonSocial' in item) vm.setProveedor(item); else vm.setVehiculo(item); }} />
      </ScrollView></SafeAreaView>
    </Modal>
  </View>;
}
