class RagPromptBuilder {
  const RagPromptBuilder._();

  static String build(String userQuestion, String context) {
    return '''
$context

## User Question
$userQuestion

Answer based on the expense data above.
Be specific with numbers and amounts.
Respond in Bengali.
Give actionable insights if possible.
''';
  }

  static String buildWithoutData(String userQuestion) {
    return userQuestion;
  }
}
