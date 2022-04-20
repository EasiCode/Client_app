import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

class Measurement {
  Measurement({required this.sendData});

  Future<void> Function(ByteBuffer) sendData;

  // ...........................................................................
  final maxNumMeasurements = 10;

  // ...........................................................................
  static const twoBytes = 2;
  static const oneKByte = 1024;
  static const oneMByte = oneKByte * oneKByte;
  static const tenMBytes = oneMByte * 10;
  static const fiftyMbytes = tenMBytes * 5;
  final packageSizes = [twoBytes, oneKByte, oneMByte, tenMBytes, fiftyMbytes];
  //final packageSizes = [oneByte, oneMByte, oneKByte];

  // ...........................................................................
  void run() async {
    for (final packageSize in packageSizes) {
      _initResultArray(packageSize);

      if (kDebugMode) {
        print('Measuring data for packageSize $packageSize ...');
      }

      for (var iteration = 0; iteration < maxNumMeasurements; iteration++) {
        _initBuffer(packageSize);
        _startTimeMeasurement();
        await _sendDataToServer();
        _stopTimeMeasurement();
        _writeMeasuredTimes(packageSize);
      }
    }

    if (kDebugMode) {
      print('Done.');
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
    assert(byteData.lengthInBytes >= 2);

    // Fill buffer with ones
    const one = 1;
    for (int offset = 0; offset < byteData.lengthInBytes; offset++) {
      byteData.setUint8(offset, one);
    }

    // Write start byte at the beginning
    const startByte = 0xFF;
    const firstBytePosition = 0;
    byteData.setUint8(firstBytePosition, startByte);

    // Write stop byte at the end
    const stopByte = 0xAA;
    final lastBytePosion = byteData.lengthInBytes - 1;
    byteData.setUint8(lastBytePosion, stopByte);
  }

  // ...........................................................................
  void _startTimeMeasurement() {
    _stopWatch.reset();
    _stopWatch.start();
  }

  // ...........................................................................
  Future<void> _sendDataToServer() async {
    final buf = _buffer!.buffer;
    print('Sending buffer of size ${buf.lengthInBytes}...');
    await sendData(buf);
  }

  // ...........................................................................
  void _stopTimeMeasurement() {
    print('Stop time measurement ...');
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

    // table header
    /* csvContent += "Byte Size";
    csvContent += ",";
    for (var i = 0; i < maxNumMeasurements; i++) {
      csvContent += "${i + 1}";
      if (i < maxNumMeasurements - 1) {
        csvContent += ",";
      }
    }
    csvContent += "\n"; */

    // for each serial number,
    //   iterate the measurement results.
    //   i.e
    //   iterate each byte size of the measurement results
    //   get the measurement array for each byte size
    //   get the measurement out of the array

    //create csv table
    csvContent += "Byte Sizes";
    csvContent += ",";
    for (var packageSize in packageSizes) {
      csvContent += "$packageSize";
      csvContent += ",";
    }
    csvContent += "\n";

    for (var i = 0; i < maxNumMeasurements; i++) {
      var numOfIterations = i + 1;

      csvContent += "$numOfIterations";
      csvContent += ",";
      print("Num: $numOfIterations");

      for (var packetSize in packageSizes) {
        var size = packetSize;
        var times = _measurementResults[packetSize]![i];

        csvContent += "$times";
        if (i <= maxNumMeasurements) {
          csvContent += ",";
        }

        print("$size: $times");
      }
      csvContent += "\n";
    }

    const path = '/Users/ajibade/Desktop/measurement_result.csv';
    var myFile = File(path);
    if (myFile.existsSync()) {
      myFile.deleteSync();
      myFile = File(path);
    }
    myFile.writeAsStringSync(csvContent);
  }

  // ...........................................................................
  final _stopWatch = Stopwatch();
}
