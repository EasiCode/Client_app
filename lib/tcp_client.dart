// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'dart:typed_data';

class Client {
  Client(this.ip, this.port, this.log) {
    _receiveData = StreamController<String>.broadcast();
    receiveData = _receiveData.stream;
  }

  final String ip;
  final int port;
  late StreamController<String> _receiveData;
  late Stream<String> receiveData;
  final StreamController<String>? log;

  late Socket _socket;
  Future<void> init() async {
    try {
      // connect to the socket server
      _socket = await Socket.connect(ip, port);
    } on SocketException {
      await Future.delayed(const Duration(seconds: 2));
      init();
      return;
    }

    log?.add('Connected to Server: ${_socket.remoteAddress.address}:${_socket.remotePort}');

    // listen for responses from the server
    _socket.listen(
      // handle data from the server
      (Uint8List data) {
        final serverResponse = String.fromCharCodes(data);
        _checkForAcknowledgement(serverResponse);
        // final nom1 = int.parse(serverResponse);
        // _receiveData.add(serverResponse);
        // print('Server: $nom1');
      },

      // handle errors
      onError: (_) async {
        log?.add('Connection Error: $_');
        _socket.destroy();
        await Future.delayed(const Duration(seconds: 5));
        init();
      },

      // handle server ending connection
      onDone: () async {
        log?.add('Server left.');
        _socket.destroy();
        await Future.delayed(const Duration(seconds: 5));
        init();
      },
    );
  }

  //handling data transfer to server
  Future<void> sendMessage(String message) async {
    log?.add('Client: $message');
    _socket.write(message);
    await _socket.flush();
  }

  // ...........................................................................
  Future<void> sendBytes(ByteData byteData) async {
    _socket.add(byteData.buffer.asUint8List());
    await _socket.flush();
    await _waitForAcknowledgementReceived();
  }

  // ...........................................................................
  Completer? _acknowledgementCompleter;

  // ...........................................................................
  Future<void> _waitForAcknowledgementReceived() async {
    _acknowledgementCompleter ??= Completer();
    await _acknowledgementCompleter!.future;
    _acknowledgementCompleter = null;
  }

  // ...........................................................................
  _checkForAcknowledgement(String serverResponse) {
    if (serverResponse == 'Acknowledgement') {
      log?.add('Acknowledgement received ...');
      _acknowledgementCompleter?.complete();
    }
  }

  /* void initState() {
    init();
  } */
}
