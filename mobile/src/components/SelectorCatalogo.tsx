import { useState } from 'react';
import { FlatList, Modal, Text, TextInput, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Button } from './Button';
import { screenStyles as s } from '../theme/screenStyles';
export function SelectorCatalogo({titulo,valor,opciones,seleccionar,disabled}:{titulo:string;valor:string;opciones:{id:number;nombre:string;detalle:string}[];seleccionar:(id:number,nombre:string)=>void;disabled:boolean}){
  const [abierto,setAbierto]=useState(false),[buscar,setBuscar]=useState('');
  return <View style={s.actions}><Text style={s.label}>{titulo}</Text><Button title={valor||`Seleccionar ${titulo.toLowerCase()}`} variant="outline" disabled={disabled} onPress={()=>{setBuscar('');setAbierto(true);}}/>
    <Modal visible={abierto} onRequestClose={()=>setAbierto(false)} animationType="slide"><SafeAreaView style={s.root}>
      <View style={s.page}><Button title="Cerrar catálogo" onPress={()=>setAbierto(false)}/><TextInput style={s.plainInput} placeholder="Buscar" accessibilityLabel={`Buscar ${titulo}`} value={buscar} onChangeText={setBuscar}/></View>
      <FlatList data={opciones.filter(o=>(o.nombre+' '+o.detalle).toLowerCase().includes(buscar.toLowerCase()))} keyExtractor={o=>String(o.id)} contentContainerStyle={s.page} keyboardShouldPersistTaps="handled" ListEmptyComponent={<Text>No hay coincidencias en el catálogo descargado.</Text>} renderItem={({item})=><View style={s.review}><Text>{item.nombre}</Text><Text style={s.caption}>{item.detalle}</Text><Button title="Seleccionar" onPress={()=>{seleccionar(item.id,item.nombre);setAbierto(false);}}/></View>}/>
    </SafeAreaView></Modal>
  </View>;
}
