import * as SQLite from 'expo-sqlite';
export async function guardarComprobacion():Promise<number>{
 const db=await SQLite.openDatabaseAsync('acopio_desarrollo.db');
 await db.execAsync('CREATE TABLE IF NOT EXISTS comprobacion_local (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT NOT NULL)');
 await db.runAsync('INSERT INTO comprobacion_local(fecha) VALUES (?)',new Date().toISOString());
 const result=await db.getFirstAsync<{total:number}>('SELECT count(*) AS total FROM comprobacion_local');
 return result?.total??0;
}
