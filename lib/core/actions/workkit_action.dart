enum WorkKitContentType { image, pdf, text, audio, unknown }

class WorkKitInput {
  const WorkKitInput({required this.type, this.filePath, this.text});

  final WorkKitContentType type;
  final String? filePath;
  final String? text;
}

class WorkKitResult {
  const WorkKitResult({
    required this.success,
    this.outputPath,
    this.text,
    this.errorMessage,
  });

  final bool success;
  final String? outputPath;
  final String? text;
  final String? errorMessage;
}

abstract interface class WorkKitAction {
  String get id;
  String get label;
  bool supports(WorkKitInput input);
  Future<WorkKitResult> execute(WorkKitInput input);
}
