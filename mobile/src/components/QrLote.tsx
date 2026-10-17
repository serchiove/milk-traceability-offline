import { useMemo } from 'react';
import { View, Text } from 'react-native';
import qrcode from 'qrcode-generator';
export function QrLote({codigo}:{codigo:string}) {
  const qr=useMemo(()=>{const value=qrcode(0,'M');value.addData(codigo);value.make();return value;},[codigo]);
  const size=qr.getModuleCount(), cell=5;
  return <View style={{alignItems:'center',gap:8}}>
    <View accessible accessibilityLabel={`Código QR del lote: ${codigo}`} style={{padding:cell*4,backgroundColor:'#fff',alignSelf:'center'}}>
      {Array.from({length:size},(_,y)=><View key={y} style={{flexDirection:'row'}}>{Array.from({length:size},(_,x)=><View key={x} style={{width:cell,height:cell,backgroundColor:qr.isDark(y,x)?'#000':'#fff'}}/>)}</View>)}
    </View><Text selectable>{codigo}</Text>
  </View>;
}
