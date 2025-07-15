import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

Future<String?> downloadBase64File(
  String base64Data,
  String fileName,
  String extension,
) async {
  try {
    print("Decodificando base64...");
    Uint8List bytes = base64Decode(base64Data);

    // Diretório padrão de Downloads no Windows
    final downloadDir = Directory(
      '${Platform.environment['USERPROFILE']}\\Downloads',
    );

    if (!await downloadDir.exists()) {
      throw Exception("Pasta Downloads não encontrada.");
    }

    final filePath = '${downloadDir.path}\\$fileName.$extension';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    print("✅ Ficheiro salvo com sucesso em: $filePath");
    return filePath;
  } catch (e) {
    print("❌ Erro ao salvar ficheiro: $e");
    return null;
  }
}
