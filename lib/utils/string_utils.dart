extension StringExtensions on String {
  String get initials {
    final partes = trim().split(' ');
    if (partes.length == 1) return partes[0][0].toUpperCase();
    return partes[0][0].toUpperCase() + partes.last[0][0].toUpperCase();
  }
}