import 'dart:developer';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:client_app/http_server.dart';
import 'package:client_app/measurement.dart';
import 'package:client_app/wifi_direct_client.dart';
//import 'package:client_app/service_listener.dart';
import 'package:flutter/material.dart';
import 'package:client_app/tcp_client.dart';
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
  late MeasurementHttpServer _measurementHttpServer;
  final _nearbyClient = NearbyClient();
  Measurement? _measurement;
  // ...........................................................................
  @override
  void initState() {
    super.initState();

    _initIpAddresses();
    _initMeasurementServer();

    // Init Bonjour Discovery
    _initDiscovery((ip, port) async {
      await _initClient(ip, port);
      _measurement = Measurement(
        sendData: (data) {
          return _client.sendBytes(data.asByteData());
        },
      );
    });
  }

  _initMeasurementServer() {
    _measurementHttpServer = MeasurementHttpServer(
      fileName: 'Measurment1.csv',
      measurmentData: () => _measurement?.resultCsv ?? 'Measurement not yet started.',
    );
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
      } else if (event.type == BonsoirDiscoveryEventType.DISCOVERY_SERVICE_LOST) {
        debugger();
      }
    });
  }

  // ...........................................................................
  int _counter = 0;

  // ...........................................................................
  _initClient(String ip, int port) async {
    _client = Client(ip, port);
    await _client.init();

    _client.receiveData.listen((serverResponse) {
      final nom1 = int.parse(serverResponse);
      setState(() {
        _counter = nom1;
      });
    });
  }

  void _incrementCounter() {
    _measurement?.run();

    setState(() {
      _counter++;
      //send data to client
      // _client.sendMessage('$_counter');
      _nearbyClient.sendMessage('Hello World!');
    });
  }

  String _ipAddresses = '';
  _initIpAddresses() async {
    final networkInterface = await NetworkInterface.list();
    setState(() {
      _ipAddresses = '';
      for (final interface in networkInterface) {
        final addresses = interface.addresses.map(
          (e) => e.address,
        );
        final addressesString = addresses.map(((e) => '$e:${MeasurementHttpServer.port}')).join(", ");
        _ipAddresses += '$addressesString\n';
      }
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
            Text(_ipAddresses),
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
