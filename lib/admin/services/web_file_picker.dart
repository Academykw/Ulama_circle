import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// A file chosen from the browser's native file dialog.
class PickedFile {
  const PickedFile(this.bytes, this.name, this.sizeBytes);
  final Uint8List bytes;
  final String name;
  final int sizeBytes;
}

/// Opens the browser file picker and returns the chosen file's bytes. Web-only
/// (this file is never reached by the mobile build). [accept] is an HTML accept
/// string, e.g. "audio/*" or "image/*". Resolves null if nothing usable came
/// back (the browser gives no reliable "cancel" event, so a cancel simply never
/// resolves — acceptable for an admin form).
Future<PickedFile?> pickFile(String accept) {
  final completer = Completer<PickedFile?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept;

  input.addEventListener(
    'change',
    (web.Event _) {
      final files = input.files;
      if (files == null || files.length == 0) {
        completer.complete(null);
        return;
      }
      final file = files.item(0)!;
      file.arrayBuffer().toDart.then((buffer) {
        completer.complete(
          PickedFile(buffer.toDart.asUint8List(), file.name, file.size),
        );
      });
    }.toJS,
  );

  input.click();
  return completer.future;
}
