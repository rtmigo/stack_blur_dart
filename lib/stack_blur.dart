// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-FileCopyrightText: (c) 2012 Yahel Bouaziz <yahel@kayenko.com>
// SPDX-FileCopyrightText: (c) 2004 Mario Klingemann <mario@quasimondo.com>
// SPDX-License-Identifier: MIT

import 'dart:math';
import 'dart:typed_data';

/// Applies a image blur filter to a buffer containing RGBA pixels.
///
/// The buffer will be modified in place. The color channels will be blurred.
/// The alpha channel will remain intact.
void stackBlurRgba(Uint32List rgbaPixels, int width, int height, int radius) {
  // Stack Blur Algorithm v1.0 by Mario Klingemann <mario@quasimondo.com>
  //
  // Dart port: Artёm IG <ortemeo@gmail.com>
  // https://github.com/rtmigo
  // ported Dec 2021
  //
  // Android port: Yahel Bouaziz <yahel@kayenko.com>
  // http://www.kayenko.com
  // ported Apr 2012
  //
  // Java Author: Mario Klingemann <mario@quasimondo.com>
  // http://incubator.quasimondo.com
  // created Feb 2004
  //
  // This is a compromise between Gaussian Blur and Box blur
  // It creates much better looking blurs than Box Blur, but
  // much faster than Gaussian Blur.
  //
  // It is called Stack Blur because this describes best how this
  // filter works internally: it creates a kind of moving stack
  // of colors whilst scanning through the image. Thereby it
  // just has to add one new block of color to the right side
  // of the stack and remove the leftmost color. The remaining
  // colors on the topmost layer of the stack are either added on
  // or reduced by one, depending on if they are on the right or
  // on the left side of the stack.

  if (width < 0) {
    throw ArgumentError.value(width, 'width');
  }

  if (height < 0) {
    throw ArgumentError.value(height, 'height');
  }

  if (rgbaPixels.length != width * height) {
    throw ArgumentError('Image size does not correspond to the number of pixels');
  }

  if (radius < 1) {
    throw ArgumentError.value(radius, 'radius');
  }

  if (radius == 1) {
    return; // no need to blur
  }

  int wm = width - 1;
  int hm = height - 1;
  int wh = width * height;
  int div = radius + radius + 1;

  final r = Int16List(wh);
  final g = Int16List(wh);
  final b = Int16List(wh);
  int rSum, gSum, bSum, x, y, i, p, yp, yi, yw;
  final vMin = Int32List(max(width, height));

  int divSum = (div + 1) >> 1;
  divSum *= divSum;

  final dv = Int16List(256 * divSum);
  for (i = 0; i < 256 * divSum; i++) {
    int short = i ~/ divSum;
    assert(-32768 <= short && short <= 32767);
    dv[i] = short;
  }

  yw = yi = 0;

  //int[][] stack = new int[div][3];
  final stack = List<Int32List>.generate(div, (_) => Int32List(3), growable: false);

  int stackPointer;
  int stackStart;

  // assigning `sir` to temporary stub value. Not declaring 'late' to avoid
  // runtime checks, whether it really assigned
  Int32List sir = Int32List(0);

  int rbs;
  int r1 = radius + 1;
  int routSum, goutSum, boutSum;
  int rinSum, ginSum, binSum;

  for (y = 0; y < height; y++) {
    rinSum = ginSum = binSum = routSum = goutSum = boutSum = rSum = gSum = bSum = 0;
    for (i = -radius; i <= radius; i++) {
      p = rgbaPixels[yi + min(wm, max(i, 0))];
      sir = stack[i + radius];
      sir[0] = (p & 0xff0000) >> 16;
      sir[1] = (p & 0x00ff00) >> 8;
      sir[2] = (p & 0x0000ff);

      rbs = r1 - i.abs();
      rSum += sir[0] * rbs;
      gSum += sir[1] * rbs;
      bSum += sir[2] * rbs;

      if (i > 0) {
        rinSum += sir[0];
        ginSum += sir[1];
        binSum += sir[2];
      } else {
        routSum += sir[0];
        goutSum += sir[1];
        boutSum += sir[2];
      }
    }
    stackPointer = radius;

    for (x = 0; x < width; x++) {
      assert(yi >= 0);
      assert(rSum >= 0);
      assert(gSum >= 0);
      assert(bSum >= 0);

      r[yi] = dv[rSum];
      g[yi] = dv[gSum];
      b[yi] = dv[bSum];

      rSum -= routSum;
      gSum -= goutSum;
      bSum -= boutSum;

      stackStart = stackPointer - radius + div;
      sir = stack[stackStart % div];

      routSum -= sir[0];
      goutSum -= sir[1];
      boutSum -= sir[2];

      if (y == 0) {
        vMin[x] = min(x + radius + 1, wm);
      }
      p = rgbaPixels[yw + vMin[x]];

      sir[0] = (p & 0xff0000) >> 16;
      sir[1] = (p & 0x00ff00) >> 8;
      sir[2] = (p & 0x0000ff);

      rinSum += sir[0];
      ginSum += sir[1];
      binSum += sir[2];

      rSum += rinSum;
      gSum += ginSum;
      bSum += binSum;

      stackPointer = (stackPointer + 1) % div;
      sir = stack[(stackPointer) % div];

      routSum += sir[0];
      goutSum += sir[1];
      boutSum += sir[2];

      rinSum -= sir[0];
      ginSum -= sir[1];
      binSum -= sir[2];

      yi++;
    }
    yw += width;
  }
  for (x = 0; x < width; x++) {
    rinSum = ginSum = binSum = routSum = goutSum = boutSum = rSum = gSum = bSum = 0;
    yp = -radius * width;
    for (i = -radius; i <= radius; i++) {
      yi = max(0, yp) + x;

      final Int32List sir = stack[i + radius];

      sir[0] = r[yi];
      sir[1] = g[yi];
      sir[2] = b[yi];

      rbs = r1 - i.abs();

      rSum += r[yi] * rbs;
      gSum += g[yi] * rbs;
      bSum += b[yi] * rbs;

      if (i > 0) {
        rinSum += sir[0];
        ginSum += sir[1];
        binSum += sir[2];
      } else {
        routSum += sir[0];
        goutSum += sir[1];
        boutSum += sir[2];
      }

      if (i < hm) {
        yp += width;
      }
    }
    yi = x;
    stackPointer = radius;
    for (y = 0; y < height; y++) {
      // Preserve alpha channel: ( 0xff000000 & pix[yi] )
      rgbaPixels[yi] =
          (0xff000000 & rgbaPixels[yi]) | (dv[rSum] << 16) | (dv[gSum] << 8) | dv[bSum];

      rSum -= routSum;
      gSum -= goutSum;
      bSum -= boutSum;

      stackStart = stackPointer - radius + div;
      Int32List sir = stack[stackStart % div];

      routSum -= sir[0];
      goutSum -= sir[1];
      boutSum -= sir[2];

      if (x == 0) {
        vMin[y] = min(y + r1, hm) * width;
      }
      p = x + vMin[y];

      sir[0] = r[p];
      sir[1] = g[p];
      sir[2] = b[p];

      rinSum += sir[0];
      ginSum += sir[1];
      binSum += sir[2];

      rSum += rinSum;
      gSum += ginSum;
      bSum += binSum;

      stackPointer = (stackPointer + 1) % div;
      sir = stack[stackPointer];

      routSum += sir[0];
      goutSum += sir[1];
      boutSum += sir[2];

      rinSum -= sir[0];
      ginSum -= sir[1];
      binSum -= sir[2];

      yi += width;
    }
  }
}
