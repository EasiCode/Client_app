import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

class Measurement {
  Measurement({required this.sendData});

  Future<void> Function(ByteBuffer) sendData;

  // ...........................................................................
  final maxNumMeasurements = 10;

  // ...........................................................................
  static const oneByte = 1;
  static const oneKByte = 1024;
  static const oneMByte = oneKByte * oneKByte;
  static const tenMBytes = oneMByte * 10;
  static const fiftyMbytes = tenMBytes * 5;
  final packageSizes = [oneByte, oneKByte, oneMByte, tenMBytes, fiftyMbytes];
  //final packageSizes = [oneByte, oneMByte, oneKByte];

  // ...........................................................................
  void run() async {
    for (final packageSize in packageSizes) {
      _initResultArray(packageSize);

      if (kDebugMode) {
        print('Measuring data for packageSize $packageSize');
      }

      for (var iteration = 0; iteration < maxNumMeasurements; iteration++) {
        _initBuffer(packageSize);
        _startTimeMeasurement();
        await _sendDataToServer();
        _stopTimeMeasurement();
        _writeMeasuredTimes(packageSize);
      }
    }

    _exportMeasuredResults();
  }

  // ...........................................................................
  ByteData? _buffer;
  void _initBuffer(int packageSize) {
    _buffer = ByteData(packageSize);
    _fillBuffer(_buffer!);
  }

  // ...........................................................................
  void _fillBuffer(ByteData byteData) {
    for (int offset = 0; offset < byteData.lengthInBytes; offset++) {
      byteData.setUint8(offset, offset % 256);
    }
  }

  // ...........................................................................
  void _startTimeMeasurement() {
    _stopWatch.start();
  }

  // ...........................................................................
  Future<void> _sendDataToServer() async {
    final buf = _buffer!.buffer;
    if (kDebugMode) {
      print('Sending buffer of length ${buf.lengthInBytes}');
    }
    await sendData(buf);
  }

  // ...........................................................................
  void _stopTimeMeasurement() {
    _stopWatch.stop();
  }

  // ...........................................................................
  final Map<int, List<int>> _measurementResults = {};
  _initResultArray(int packageSize) {
    _measurementResults[packageSize] = [];
  }

  // ...........................................................................
  void _writeMeasuredTimes(int packageSize) {
    final elapsedTime = _stopWatch.elapsed.inMicroseconds;
    _measurementResults[packageSize]!.add(elapsedTime);
  }

  // ...........................................................................
  _exportMeasuredResults() {
    var csvContent = "";

    // create a table of 3 rows i.e
    //   serial number
    //   Byte Size
    //   and elapsed times respectively.

    // for each serial number,
    //   iterate the measurement results.
    //   i.e
    //   iterate each byte size of the measurement results
    //   get the measurement array for each byte size
    //   get the measurement out of the array
    // get the serial number for each byte size,
    //

    //   iterate each byte size of the measurement results
    _measurementResults.forEach((byteSize, elapsedTimes) {
      // get the measurement array for each byte size and times for each byte size
      int size = byteSize;
      List<int> times = elapsedTimes;
      // get the serial number for each byte size,
      dynamic num = packageSizes.indexOf(byteSize);
      //dynamic number = num + 1;

      //add elements into a container
      csvContent += '$num,$size, ${times.toString().replaceAll('[', '').replaceAll(']', '')}\n';
      //csvContent.add('$number, $size, $times\n');
    });

    var myFile = File('/Users/ajibade/Desktop/measurement_result.csv');
    if (myFile.existsSync()) {
      myFile.deleteSync();
      myFile = File('/Users/ajibade/Desktop/measurement_result.csv');
    }
    myFile.writeAsStringSync(csvContent);
  }

  // ...........................................................................
  final _stopWatch = Stopwatch();
}
