package pe.edu.utp.acopio.DTO.consulta;

import java.util.List;

public record Pagina<T>(List<T> elementos, long total, int pagina, int tamano) {
    public static void validar(int pagina, int tamano, String buscar) {
        if (pagina < 0 || pagina > 1_000_000 || tamano < 1 || tamano > 100 || buscar.length() > 180) {
            throw new IllegalArgumentException("Paginacion o busqueda invalida");
        }
    }
}
