![Generic badge](https://img.shields.io/badge/status-it_works-ok.svg)
[![Pub Package](https://img.shields.io/pub/v/stack_blur.svg)](https://pub.dev/packages/stack_blur)
[![pub points](https://badges.bar/stack_blur/pub%20points)](https://pub.dev/packages/stack_blur/score)

# [stack_blur](https://github.com/rtmigo/stack_blur_dart)

The Dart library for blurring images with the Stack blur algorithm.

The [Stack blur](https://underdestruction.com/2004/02/25/stackblur-2004/) works fast and looks good.
It is a compromise between [Gaussian blur](https://en.wikipedia.org/wiki/Gaussian_blur)
and [Box blur](https://en.wikipedia.org/wiki/Box_blur).

This library modifies a raw buffer containing RGBA pixels. This is "low-level", but universal and
does not impose external dependencies.

## Use with [image](https://pub.dev/packages/image) library

```dart
import 'dart:io';

import 'package:image/image.dart';
import 'package:stack_blur/stack_blur.dart';

void main() {
  // loading image from file
  final image = decodeImage(File('source.png').readAsBytesSync())!;
  Uint32List rgbaPixels = image.data;

  // blurring image pixels with blur radius 42
  stackBlurRgba(rgbaPixels, image.width, image.height, 42);

  // saving image to file
  File('blurred.png').writeAsBytesSync(encodePng(image));
}
```

## Use with Flutter and [bitmap](https://pub.dev/packages/bitmap) library

Flutter images have the same RGBA pixel buffer. You can [get it in a rather non-obvious
way](https://stackoverflow.com/a/60297917) through `ImageStreamListener`.

``` dart
Future<Image> blurAsset(String assetName) async {
  ImageProvider provider = ExactAssetImage(assetName);

  // Rain dance to get RGBA pixels from image
  final ImageStream stream = provider.resolve(ImageConfiguration.empty);
  final completer = Completer<ui.Image>();
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (frame, _) {
        stream.removeListener(listener);
        completer.complete(frame.image);
    },
    onError: (error, stack) {
        stream.removeListener(listener);
        completer.completeError(error, stack);
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
      rgbaPixels.buffer.asUint8List());
  return Image.memory(bitmap.buildHeaded());
}
```
