extension StringUnescaping on String {
  String unescapeJson() {
    // First handle any double-escaped quotes
    String result = replaceAll('\\"', '"').replaceAll("\\'", "'");

    // Then handle any remaining escaped backslashes
    result = result.replaceAll('\\\\', '\\');

    return result;
  }
}
