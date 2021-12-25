# [stack_blur](https://github.com/rtmigo/stack_blur_dart)

Applies the [stack blur](https://underdestruction.com/2004/02/25/stackblur-2004/) algorithm to
a buffer with RGBA pixels.

Stack blur is a compromise between Gaussian Blur and Box blur. It is faster than Gaussian Blur
and better looking than Box Blur.


## Use with [image](https://pub.dev/packages/image) library

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

## Use with Flutter and [bitmap](https://pub.dev/packages/bitmap) library

Flutter images have the same RGBA pixel buffer. You can [get it in a rather non-obvious
way](https://stackoverflow.com/a/60297917) through `ImageStreamListener`.

``` dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:bitmap/bitmap.dart';

Future<Image> blurAsset(String assetName) async {
  ImageProvider provider = ExactAssetImage(assetName);

  // Rain dance to get RGBA pixels from image
  final ImageStream stream = provider.resolve(ImageConfiguration.empty);
  final completer = Completer<ui.Image>();
  late ImageStreamListener listener;
  listener = ImageStreamListener((frame, sync) {
    ui.Image image = frame.image;
    stream.removeListener(listener);
    completer.complete(image);
  });
  stream.addListener(listener);
  ui.Image image = await completer.future;
  ByteData rgbaData = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;

  // This is the pixels we need
  Uint32List rgbaPixels = rgbaData.buffer.asUint32List();

  // We can blur the image buffer
  stackBlurRgba(rgbaPixels, image.width, image.height, 42);

  // We need a third-party 'bitmap' library to turn the buffer into a widget
  final bitmap = Bitmap.fromHeadless(
      image.width, image.height,
      rgbaData.buffer.asUint8List());
  return Image.memory(bitmap.buildHeaded());
}
```
