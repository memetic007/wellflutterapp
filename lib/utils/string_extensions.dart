extension StringUnescaping on String {
  String unescapeJson() {
    return replaceAll('\\"', '"')
        .replaceAll("\\'", "'")
        .replaceAll('\\\\', '\\');
  }
}
