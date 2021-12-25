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
