// Feature: Core
// Layer: AI

class JsonBlockExtractor {
  const JsonBlockExtractor._();

  static String? extractFirstObject(String text) {
    return _extractBalanced(text, '{', '}');
  }

  static String? extractFirstArray(String text) {
    return _extractBalanced(text, '[', ']');
  }

  static String removeFirstBlock(String text, String? block) {
    if (block == null || block.isEmpty) {
      return text.trim();
    }
    return text.replaceFirst(block, '').trim();
  }

  static String? _extractBalanced(String text, String open, String close) {
    final start = text.indexOf(open);
    if (start == -1) {
      return null;
    }

    var depth = 0;
    var inString = false;
    var isEscaped = false;

    for (var index = start; index < text.length; index++) {
      final char = text[index];

      if (isEscaped) {
        isEscaped = false;
        continue;
      }

      if (char == r'\') {
        isEscaped = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (inString) {
        continue;
      }

      if (char == open) {
        depth++;
      } else if (char == close) {
        depth--;
        if (depth == 0) {
          return text.substring(start, index + 1);
        }
      }
    }

    return null;
  }
}
