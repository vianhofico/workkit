import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:workkit/core/errors/app_failure.dart';
import 'package:workkit/features/ocr/domain/ocr_engine.dart';

class MlKitOcrEngine implements OcrEngine {
  const MlKitOcrEngine();

  @override
  Future<String> recognizeImage(String imagePath) async {
    final TextRecognizer recognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );
    try {
      final InputImage image = InputImage.fromFilePath(imagePath);
      final RecognizedText result = await recognizer.processImage(image);
      return result.text.trim();
    } catch (error) {
      throw ProcessingFailure('Text recognition failed.', cause: error);
    } finally {
      await recognizer.close();
    }
  }
}
