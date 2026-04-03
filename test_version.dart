void main() {
  bool isVersionGreater(String latest, String current) {
    List<int> latestParts = latest.split('.').map(int.parse).toList();
    List<int> currentParts = current.split('.').map((s) => int.parse(s.split('+')[0])).toList();

    for (var i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  print('1.0.3 vs 1.0.3: ${isVersionGreater("1.0.3", "1.0.3")}');
  print('1.0.3 vs 1.0.3+4: ${isVersionGreater("1.0.3", "1.0.3+4")}');
}
