// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

String htmlContent(
  String filename,
  String csvContent,
) =>
    '''
<html>

<body>
  <h1>Biodun's Master Thesis Measurments</h1>
  <a style="cursor: pointer;"
    onclick="document.download('$filename', '$csvContent')">Download
    Measurments</a>

</body>

<script>

  document.download = (filename, text) => {
    var element = document.createElement('a');
    element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(text));
    element.setAttribute('download', filename);

    element.style.display = 'none';
    document.body.appendChild(element);

    element.click();

    document.body.removeChild(element);
  }

</script>

</html>
''';

class MeasurementHttpServer {
  MeasurementHttpServer({
    required this.fileName,
    required this.measurmentData,
  }) {
    _init();
  }

  late HttpServer _httpServer;
  final String fileName;
  final String Function() measurmentData;
  static int port = 8080;

  _init() async {
    _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port);

    await for (var request in _httpServer) {
      request.response
        ..headers.contentType = ContentType.html
        ..write(htmlContent(fileName, measurmentData()))
        ..close();
    }
  }
}
