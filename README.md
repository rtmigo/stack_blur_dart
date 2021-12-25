# [stack_blur](https://github.com/rtmigo/stack_blur_dart)

Applies the [stack blur](https://underdestruction.com/2004/02/25/stackblur-2004/) algorithm to
a buffer with RGBA pixels.

This is a minimalist library with no external dependencies.  The library has no idea where the
pixel buffer comes from.

For example, in the case of using the [image](https://pub.dev/packages/image/example) library,
the filter can be used like this:

```dart
import 'dart:io';

import 'package:image/image.dart';
import 'package:stack_blur/stack_blur.dart';

void main() {
  // loading image from file
  final image = decodeImage(File('source.png').readAsBytesSync())!;

  // blurring image pixels with blur radius 42
  stackBlurRgba(image.data, image.width, image.height, 42);

  // saving image to file
  File('blurred.png').writeAsBytesSync(encodePng(image));
}
```

The Flutter has the same RGBA pixel buffer. You can [get it in a rather non-obvious
way](https://stackoverflow.com/a/60297917) through `ImageStreamListener`.

``` dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// sample code, do not try to compile :)

Future<Image> blurRgba(String assetName) async {
    ImageProvider provider = ExactAssetImage(assetName);

    ImageStream stream = provider.resolve(ImageConfiguration.empty);
    Completer completer = Completer<ui.Image>();
    ImageStreamListener listener = ImageStreamListener((frame, sync) {
        ui.Image image = frame.image;
        stream.removeListener(listener);
        completer.complete(image);
    })

    stream.addListener(listener);

    ui.Image image = await completer;
    ByteData data = await image.toByteData(format: ui.ImageByteFormat.rowRgba)!;
    Uint32List rgbaPixels = data.buffer.asUint32List();  // this is the pixels we need

    // we can the image buffer it now
    stackBlurRgba(rgbaPixels, image.width, image.height, 42);

    // Not the most efficient, but the generally accepted way to convert this into a widget
    final ByteData? pngData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return Image.memory(pngData!.buffer.asUint8List());
};
```
