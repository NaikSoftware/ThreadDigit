import 'dart:io';

import 'package:file_picker/file_picker.dart' as picker;
import 'package:flutter/cupertino.dart';

class FilePicker {
  Future<File?> pick(BuildContext context, {List<String>? allowedExtensions}) async {
    picker.FilePickerResult? result = await picker.FilePicker.platform.pickFiles(
      type: allowedExtensions != null ? picker.FileType.custom : picker.FileType.any,
      allowedExtensions: allowedExtensions,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }
}
