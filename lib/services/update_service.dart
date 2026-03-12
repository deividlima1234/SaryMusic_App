import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final updateServiceProvider = Provider((ref) => UpdateService());

class AppUpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final bool hasUpdate;

  AppUpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.hasUpdate,
  });
}

class UpdateService {
  // Nota: Esto debe apuntar a un JSON raw en tu repositorio de GitHub
  // Ejemplo: https://raw.githubusercontent.com/TuUsuario/TuRepo/main/version.json
  static const String _versionUrl =
      'https://raw.githubusercontent.com/deividlima1234/SaryMusic_App/main/version.json';

  Future<AppUpdateInfo> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(_versionUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['version'] as String;
        final downloadUrl = data['url'] as String;

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        return AppUpdateInfo(
          latestVersion: latestVersion,
          downloadUrl: downloadUrl,
          hasUpdate: _isVersionGreater(latestVersion, currentVersion),
        );
      }
    } catch (e) {
      print('Error al buscar actualizaciones: $e');
    }
    return AppUpdateInfo(latestVersion: '', downloadUrl: '', hasUpdate: false);
  }

  bool _isVersionGreater(String latest, String current) {
    List<int> latestParts = latest.split('.').map(int.parse).toList();
    List<int> currentParts = current.split('.').map(int.parse).toList();

    for (var i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }
}
