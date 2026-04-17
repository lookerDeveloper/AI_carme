enum AIModel {
  glm4v('glm-4v', '智谱GLM-4V'),
  gpt4v('gpt-4v', 'GPT-4V'),
  claudeVision('claude-vision', 'Claude Vision'),
  geminiVision('gemini-vision', 'Gemini Vision');

  final String value;
  final String label;

  const AIModel(this.value, this.label);
}
