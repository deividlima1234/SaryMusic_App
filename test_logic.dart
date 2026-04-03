bool isVersionGreater(String latest, String current) {
  List<int> latestParts = latest.split('.').map(int.parse).toList();
  List<int> currentParts = current.split('.').map(int.parse).toList();

  for (var i = 0; i < latestParts.length; i++) {
    if (i >= currentParts.length) return true;
    if (latestParts[i] > currentParts[i]) return true;
    if (latestParts[i] < currentParts[i]) return false;
  }
  return false;
}
void main() {
  print(isVersionGreater("1.0.3", "1.0.3"));
}
