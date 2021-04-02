class PBInputFormatter {
  ///Formats input to destroy spaces and other intrusive characters
  static String formatLabel(String input,
      {bool isTitle = false,
      bool space_to_underscore = true,
      bool destroy_digits = false,
      bool destroy_special_sym = false}) {
    assert(input != null);
    var result = input;
    // TODO: set a temporal name
    result = (result.isEmpty) ? 'tempName' : result;
    result = _removeFirstDigits(result);
    result = result.trim();
    var space_char = (space_to_underscore) ? '_' : '';
    result = result.replaceAll(r'[\s\./_+?]+', space_char);
    result = result.replaceAll(RegExp(r'\s+'), space_char);
    result = (destroy_digits) ? result.replaceAll(RegExp(r'\d+'), '') : result;
    result = result.replaceAll(' ', '').replaceAll(RegExp(r'[^\s\w]'), '');
    (isTitle)
        ? result = result.replaceRange(0, 1, result[0].toUpperCase())
        : result = result.toLowerCase();
    return result;
  }

  static String _removeFirstDigits(String str) =>
      str.startsWith(RegExp(r'^[\d]+'))
          ? str.replaceFirstMapped(RegExp(r'^[\d]+'), (e) => '')
          : str;
}
