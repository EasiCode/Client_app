import 'dart:developer';

import 'package:bonsoir/bonsoir.dart';
//import 'package:client_app/service_listener.dart';
import 'package:flutter/material.dart';
import 'package:client_app/client.dart';
import 'package:client_app/bonsoir_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: const MyHomePage(title: 'Bonjour Client'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

typedef Callback = Function(String ip, int port);

class _MyHomePageState extends State<MyHomePage> {
  //final client = Client();
  late Client _client;
  // ...........................................................................
  @override
  void initState() {
    super.initState();
    _initDiscovery((ip, port) {
      _initClient(ip, port);
    });
  }

  // ...........................................................................
  _initDiscovery(Callback callback) async {
    // This is the type of service we're looking for :
    String type = AppService.type;

    // Once defined, we can start the discovery :
    BonsoirDiscovery discovery = BonsoirDiscovery(type: type);
    await discovery.ready;
    await discovery.start();

    // If you want to listen to the discovery :
    discovery.eventStream?.listen((event) {
      if (event.type == BonsoirDiscoveryEventType.DISCOVERY_SERVICE_RESOLVED) {
        final service = (event.service as ResolvedBonsoirService);
        final ip = service.ip;
        final port = service.port;
        if (ip != null) {
          callback(ip, port);
        }
      } else if (event.type ==
          BonsoirDiscoveryEventType.DISCOVERY_SERVICE_LOST) {
        debugger();
      }
    });
  }

  // ...........................................................................
  int _counter = 0;

  // ...........................................................................
  _initClient(String ip, int port) {
    _client = Client(ip, port);

    _client.receiveData.listen((serverResponse) {
      final nom1 = int.parse(serverResponse);
      setState(() {
        _counter = nom1;
      });
    });
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
      //send data to client
      _client.sendMessage('$_counter');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many time(s):',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
