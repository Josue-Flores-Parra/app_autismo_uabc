/// Archivo descargado de un módulo: nombre local y tamaño en bytes.
class OfflineFileEntry {
  const OfflineFileEntry({required this.file, required this.bytes});

  final String file;
  final int bytes;

  factory OfflineFileEntry.fromMap(Map<String, dynamic> data) {
    final bytes = data['bytes'];
    return OfflineFileEntry(
      file: data['file'] as String? ?? '',
      bytes: bytes is num ? bytes.toInt() : 0,
    );
  }

  Map<String, dynamic> toMap() => {'file': file, 'bytes': bytes};
}

/// Lista de archivos descargados de un módulo, guardada junto a ellos.
///
/// La clave de cada archivo es la URL remota original; así los lectores
/// buscan por la misma URL que ya traen los niveles.
class OfflineManifest {
  const OfflineManifest({required this.moduleId, this.files = const {}});

  final String moduleId;
  final Map<String, OfflineFileEntry> files;

  int get totalBytes =>
      files.values.fold(0, (total, entry) => total + entry.bytes);

  factory OfflineManifest.fromMap(Map<String, dynamic> data) {
    final raw = data['files'];
    final files = <String, OfflineFileEntry>{};
    if (raw is Map) {
      raw.forEach((url, value) {
        if (value is Map) {
          final entry = OfflineFileEntry.fromMap(
            Map<String, dynamic>.from(value),
          );
          if (entry.file.isNotEmpty) files['$url'] = entry;
        }
      });
    }
    return OfflineManifest(
      moduleId: data['moduleId'] as String? ?? '',
      files: files,
    );
  }

  Map<String, dynamic> toMap() => {
    'version': 1,
    'moduleId': moduleId,
    'files': {for (final e in files.entries) e.key: e.value.toMap()},
  };

  OfflineManifest copyWith({Map<String, OfflineFileEntry>? files}) {
    return OfflineManifest(moduleId: moduleId, files: files ?? this.files);
  }
}
