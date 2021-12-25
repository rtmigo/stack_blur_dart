// SPDX-FileCopyrightText: (c) 2021 Artёm IG <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:image/image.dart';
import 'package:stack_blur/stack_blur.dart';
import 'package:test/test.dart';

void expectFilesEqual(String path1, String path2) {
  expect(File(path1).readAsBytesSync(), File(path2).readAsBytesSync());
}

void main() {
  test('road_300', () {
    String inputFilePath = 'test/images/1_source/road.jpg';
    String outputFilePath = 'test/images/3_output/road_blur_300.png';
    String goldenFilePath = 'test/images/2_expected/road_blur_300.png';
    final image = decodeImage(File(inputFilePath).readAsBytesSync())!;
    stackBlurRgba(image.data, image.width, image.height, 300);
    File(outputFilePath).writeAsBytesSync(encodePng(image));

    expectFilesEqual(outputFilePath, goldenFilePath);
  });

  test('road_50', () {
    String inputFilePath = 'test/images/1_source/road.jpg';
    String outputFilePath = 'test/images/3_output/road_blur_50.png';
    String goldenFilePath = 'test/images/2_expected/road_blur_50.png';
    final image = decodeImage(File(inputFilePath).readAsBytesSync())!;
    stackBlurRgba(image.data, image.width, image.height, 50);
    File(outputFilePath).writeAsBytesSync(encodePng(image));

    expectFilesEqual(outputFilePath, goldenFilePath);
  });

  test('radius 1 does not change image', () {
    String inputFilePath = 'test/images/1_source/road.jpg';
    final image = decodeImage(File(inputFilePath).readAsBytesSync())!;
    final oldData = image.data.toList();
    stackBlurRgba(image.data, image.width, image.height, 1);
    expect(image.data.toList(), oldData);     // not changed
  });

  test('radius errors', () {
    String inputFilePath = 'test/images/1_source/road.jpg';
    final image = decodeImage(File(inputFilePath).readAsBytesSync())!;
    expect(()=>stackBlurRgba(image.data, image.width, image.height, 0), throwsArgumentError);
    expect(()=>stackBlurRgba(image.data, image.width, image.height, -1), throwsArgumentError);
  });

  test('pixels count and size mismatch', () {
    String inputFilePath = 'test/images/1_source/road.jpg';
    final image = decodeImage(File(inputFilePath).readAsBytesSync())!;
    expect(()=>stackBlurRgba(image.data, image.width-1, image.height, 10), throwsArgumentError);
    expect(()=>stackBlurRgba(image.data, image.width, image.height+1, 10), throwsArgumentError);

  });

  test('negative size', () {
    String inputFilePath = 'test/images/1_source/road.jpg';
    final image = decodeImage(File(inputFilePath).readAsBytesSync())!;
    // although, w*h is positive and corresponds to the number of pixels,
    // the function throws error because of the negative argument(s)
    expect(()=>stackBlurRgba(image.data, -image.width, -image.height, 10), throwsArgumentError);
  });
}
