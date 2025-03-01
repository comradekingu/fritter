import 'dart:io';

import 'package:file_picker_writable/file_picker_writable.dart';
import 'package:fritter/settings/settings_data.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

Future downloadUriToPickedFile(String uri, String fileName, { required Function(http.Response response) onError, required Function() onStart, required Function() onSuccess }) async {
  var sanitizedFilename = fileName.split("?")[0];

  var downloadFile = () async {
    var response = await http.get(Uri.parse(uri));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }

    onError(response);
    return null;
  };

  var isLegacy = await isLegacyAndroid();
  if (isLegacy) {
    // This platform is too old to support a directory picker, so we just save the file to a predefined location
    var fullPath = await getLegacyPath(sanitizedFilename);

    await Directory(path.dirname(fullPath)).create(recursive: true);

    var response = await downloadFile();
    if (response != null) {
      await File(fullPath).writeAsBytes(response);

      onSuccess();
    }
  } else {
    var fileInfo = await FilePickerWritable().openFileForCreate(fileName: sanitizedFilename, writer: (file) async {
      onStart();

      var response = await downloadFile();
      if (response != null) {
        await file.writeAsBytes(response);
      }
    });

    if (fileInfo != null) {
      onSuccess();
    }
  }
}