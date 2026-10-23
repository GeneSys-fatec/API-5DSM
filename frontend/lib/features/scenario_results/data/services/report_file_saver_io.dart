import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> saveReportFile(Uint8List bytes, String fileName) async {
  final savedPath = await FilePicker.platform.saveFile(
    dialogTitle: 'Salvar relatório do cenário',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
    bytes: bytes,
  );
  return savedPath != null;
}
