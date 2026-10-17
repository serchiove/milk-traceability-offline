import { useRef, useState } from 'react';
import { Alert, Modal, Text, TextInput, View } from 'react-native';
import { CameraView, useCameraPermissions } from 'expo-camera';
import { SafeAreaView } from 'react-native-safe-area-context';
import type { SesionOperario } from '../services/authService';
import { useCentralViewModel } from '../viewmodel/useCentralViewModel';
import { Button } from '../components/Button';
import { NoticeBox } from '../components/NoticeBox';
import { QrLote } from '../components/QrLote';
import { screenStyles as s } from '../theme/screenStyles';
export function CentralScreen({sesion,modo}:{sesion:SesionOperario;modo:'calidad'|'tanque'|'trazabilidad'}) {
  const vm=useCentralViewModel(sesion.accessToken,modo);
  const [camara,setCamara]=useState(false),[permission,requestPermission]=useCameraPermissions();
  const escaneado=useRef(false);
  const d=vm.detalle;
  return <>
    <Text style={s.title}>{modo==='calidad'?'Resultados de calidad':modo==='tanque'?'Tanques de destino':'Trazabilidad y QR'}</Text>
    <Text style={s.caption}>Datos del servidor · {sesion.usuario.centro}</Text>
    <TextInput style={s.plainInput} value={vm.codigo} onChangeText={vm.setCodigo} placeholder="UUID o contenido del QR" accessibilityLabel="Código del lote" autoCapitalize="none"/>
    <Button title="Consultar lote" disabled={vm.busy} onPress={()=>{void vm.abrir(vm.codigo);}}/>
    <Button title="Escanear QR" variant="outline" disabled={vm.busy} onPress={async()=>{try{const p=permission?.granted?permission:await requestPermission();if(p.granted){escaneado.current=false;setCamara(true);}else Alert.alert('Cámara no autorizada','Puedes ingresar el código manualmente o habilitar la cámara en ajustes.');}catch{Alert.alert('Cámara no disponible','Ingresa el código manualmente.');}}}/>
    {!!vm.error&&<NoticeBox variant="error" message={vm.error}/>}
    {vm.busy&&<Text accessibilityLiveRegion="polite">Consultando servidor…</Text>}
    {d?<>
      <View style={s.review}><Text style={s.recordTitle}>{d.proveedor}</Text><Text>{d.placa} · {d.centro}</Text><Text>{d.operario} · {d.fechaHora}</Text><Text>{d.volumenLitros} L · {d.temperaturaC} °C · {d.acidezDornic} °D · {d.densidadGml} g/mL</Text></View>
      <NoticeBox variant={d.estadoEvaluacion==='APROBADO'?'success':'warning'} message={`Calidad: ${d.estadoEvaluacion}${d.motivo?' · '+d.motivo:''}`}/>
      <Text style={s.caption}>Reglas: {d.versionReglas??'Pendientes'}{d.versionReglas?.startsWith('DEMO')?' (demostración académica)':''}</Text>
      {d.estadoEvaluacion==='APROBADO'&&d.codigoQr&&<QrLote codigo={d.codigoQr}/>}
      <Text style={s.sectionTitle}>Destino: {d.tanque??'Sin asignar'}</Text>
      {d.asignadoEn&&<Text style={s.caption}>Confirmado: {d.asignadoEn}</Text>}
      {d.estadoEvaluacion==='APROBADO'&&!d.idTanque&&<Button title="Consultar tanques disponibles" disabled={vm.busy} onPress={()=>{void vm.cargarTanques();}}/>}
      {vm.tanques&&<>
        {!vm.tanques.elementos.length&&<Text>No hay tanques disponibles en esta página.</Text>}
        {vm.tanques.elementos.map(t=><View style={s.review} key={t.id}><Text style={s.recordTitle}>{t.codigo}</Text><Text>{t.disponibleLitros} L libres de {t.capacidadLitros} L</Text><Button title={t.disponibleLitros<d.volumenLitros?'Capacidad insuficiente':'Asignar este tanque'} disabled={vm.busy||t.disponibleLitros<d.volumenLitros} onPress={()=>Alert.alert('Confirmar destino',`${d.volumenLitros} L al tanque ${t.codigo}. No se permite reasignación.`,[{text:'Cancelar',style:'cancel'},{text:'Asignar',onPress:()=>{void vm.asignar(t.id);}}])}/></View>)}
        <Button title="Tanques anteriores" variant="outline" disabled={vm.busy||vm.paginaTanque===0} onPress={()=>{void vm.cargarTanques(vm.paginaTanque-1);}}/>
        <Button title="Más tanques" variant="outline" disabled={vm.busy||(vm.paginaTanque+1)*25>=vm.tanques.total} onPress={()=>{void vm.cargarTanques(vm.paginaTanque+1);}}/>
      </>}
      <Button title="Volver a la lista" variant="outline" disabled={vm.busy} onPress={()=>{vm.setDetalle(null);vm.recargar();}}/>
    </>:<>
      <Button title="Actualizar lista" variant="outline" disabled={vm.busy} onPress={vm.recargar}/>
      {vm.lista?.elementos.map(l=><View key={l.idLote} style={s.review}><Text style={s.recordTitle}>{l.proveedor}</Text><Text>{l.estadoEvaluacion} · {l.volumenLitros} L · {l.tanque??'Sin tanque'}</Text><Button title="Ver resultado y destino" disabled={vm.busy} variant="outline" onPress={()=>{void vm.abrir(l.idLote);}}/></View>)}
      {vm.lista?.total===0&&<Text>No hay recepciones para esta consulta.</Text>}
      <Button title="Página anterior" variant="outline" disabled={vm.busy||vm.pagina===0} onPress={()=>vm.setPagina(n=>n-1)}/>
      <Button title="Página siguiente" variant="outline" disabled={vm.busy||!vm.lista||(vm.pagina+1)*25>=vm.lista.total} onPress={()=>vm.setPagina(n=>n+1)}/>
    </>}
    <Modal visible={camara} onRequestClose={()=>setCamara(false)}><SafeAreaView style={s.root}><Button title="Cerrar cámara" onPress={()=>setCamara(false)}/>{camara&&<CameraView style={{flex:1}} barcodeScannerSettings={{barcodeTypes:['qr']}} onBarcodeScanned={({data})=>{if(escaneado.current)return;escaneado.current=true;setCamara(false);vm.setCodigo(data);void vm.abrir(data);}}/>}</SafeAreaView></Modal>
  </>;
}
