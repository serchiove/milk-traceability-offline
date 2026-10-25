import '../core/config.dart';

class CatalogItem {
  final int id;
  final String label, description;
  final Map<String, dynamic> json;
  CatalogItem._(this.id, this.label, this.description, this.json);
  factory CatalogItem.parse(Map<String, dynamic> j, String type) {
    if (j['id'] is! int || j['id'] <= 0) {
      throw const AppFailure('El servidor devolvió un catálogo no válido.');
    }
    if (type == 'proveedores') {
      for (final k in [
        'razonSocial',
        'tipoDocumento',
        'numeroDocumento',
        'estadoCert',
      ]) {
        if (j[k] is! String) {
          throw const AppFailure('Proveedor no válido.');
        }
      }
      return CatalogItem._(
        j['id'],
        j['razonSocial'],
        '${j['tipoDocumento']}: ${j['numeroDocumento']} · ${j['estadoCert']}',
        j,
      );
    }
    if (j['placa'] is! String ||
        j['capacidadLitros'] is! num ||
        !(j['capacidadLitros'] as num).isFinite) {
      throw const AppFailure('Vehículo no válido.');
    }
    return CatalogItem._(
      j['id'],
      j['placa'],
      'Capacidad: ${j['capacidadLitros']} L',
      j,
    );
  }
}

class CatalogCache {
  final List<CatalogItem> suppliers, vehicles;
  final Map<String, dynamic> center;
  final String updated;
  CatalogCache(this.suppliers, this.vehicles, this.center, this.updated);
  Map<String, dynamic> toJson() => {
    'proveedores': suppliers.map((i) => i.json).toList(),
    'vehiculos': vehicles.map((i) => i.json).toList(),
    'centro': center,
    'actualizado': updated,
  };
  factory CatalogCache.fromJson(Map<String, dynamic> j) => CatalogCache(
    (j['proveedores'] as List)
        .map(
          (v) => CatalogItem.parse(Map<String, dynamic>.from(v), 'proveedores'),
        )
        .toList(),
    (j['vehiculos'] as List)
        .map(
          (v) => CatalogItem.parse(Map<String, dynamic>.from(v), 'vehiculos'),
        )
        .toList(),
    Map<String, dynamic>.from(j['centro']),
    j['actualizado'],
  );
}

class ApiPage<T> {
  final List<T> items;
  final int total, page, size;
  const ApiPage(this.items, this.total, this.page, this.size);
  bool get hasNext => (page + 1) * size < total;
  factory ApiPage.parse(
    Map<String, dynamic> j,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (j['elementos'] is! List ||
        (j['elementos'] as List).any((v) => v is! Map<String, dynamic>) ||
        j['total'] is! int ||
        j['total'] < 0 ||
        j['pagina'] is! int ||
        j['tamano'] is! int ||
        j['tamano'] <= 0) {
      throw const AppFailure('El servidor devolvió una página no válida.');
    }
    return ApiPage(
      (j['elementos'] as List)
          .map((v) => parse(Map<String, dynamic>.from(v)))
          .toList(),
      j['total'],
      j['pagina'],
      j['tamano'],
    );
  }
}
