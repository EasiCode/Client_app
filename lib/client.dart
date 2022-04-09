import 'dart:async';
import 'dart:io';

import 'dart:typed_data';

class Client {
  Client() {
    _receiveData = StreamController<String>.broadcast();
    receiveData = _receiveData.stream;
    init();
  }
  late StreamController<String> _receiveData;
  late Stream<String> receiveData;

  late Socket _socket;
  Future<void> init() async {
    try {
      // connect to the socket server
      _socket = await Socket.connect('127.0.0.1', 18910);
    } on SocketException {
      await Future.delayed(Duration(seconds: 2));
      init();
      return;
    }

    print(
        'Connected to Server: ${_socket.remoteAddress.address}:${_socket.remotePort}');

    // listen for responses from the server
    _socket.listen(
      // handle data from the server
      (Uint8List data) {
        final serverResponse = String.fromCharCodes(data);
        final nom1 = int.parse(serverResponse);
        _receiveData.add(serverResponse);
        print('Server: $nom1');
      },

      // handle errors
      onError: (_) async {
        print('Connection Error: $_');
        _socket.destroy();
        await Future.delayed(Duration(seconds: 5));
        init();
      },

      // handle server ending connection
      onDone: () async {
        print('Server left.');
        _socket.destroy();
        await Future.delayed(Duration(seconds: 5));
        init();
      },
    );

    // send some messages to the server
    /*  await sendMessage(socket, 'Knock, knock.');
    await sendMessage(socket, 'client');
    await sendMessage(socket, 'client');
    await sendMessage(
        socket, 'OK, it is enough Mr. server. Stop asking who hehe'); */
  }

  Future<void> sendMessage(String message) async {
    print('Client: $message');
    _socket.write(message);
  }

  void initState() {
    init();
  }
}
