import 'dart:async';
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
import 'package:shared_preferences/shared_preferences.dart';

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
  Measurement? _tcpMeasurments;
  Measurement? _nearbyMeasurments;
  // ...........................................................................
  @override
  void initState() {
    super.initState();

    _initSharedPreferences();
    _initIpAddresses();
    _initMeasurementServer();
    _initTcpConnection();
  }

  // ...........................................................................
  SharedPreferences? _sharedPreferences;
  _initSharedPreferences() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  // ...........................................................................
  _initTcpConnection() {
    // Init Bonjour Discovery
    _initDiscovery((ip, port) async {
      await _initClient(ip, port);
      _tcpMeasurments = Measurement(
        sendData: (data) {
          return _client.sendBytes(data.asByteData());
        },
        log: log,
      );
    });
  }

  // ...........................................................................
  _initMeasurementServer() {
    _measurementHttpServer = MeasurementHttpServer(
        fileName: 'Measurment1.csv',
        measurmentData: () {
          final data = _tcpMeasurments?.resultCsv ??
              _sharedPreferences?.getString('measurements.csv') ??
              'No measurments available';

          return data.replaceAll('\n', '\\n');
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
      } else if (event.type == BonsoirDiscoveryEventType.DISCOVERY_SERVICE_LOST) {
        debugger();
      }
    });
  }

  // ...........................................................................
  final log = StreamController<String>.broadcast();

  // ...........................................................................
  _initClient(String ip, int port) async {
    _client = Client(ip, port, log);
    await _client.init();

    _client.receiveData.listen((serverResponse) {});
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

  _startTcpMeasurements() {
    _tcpMeasurments?.run();
  }

  _startNearbyMeasurements() {
    _tcpMeasurments?.run();
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
            const Spacer(
              flex: 1,
            ),
            TextButton(
              child: const Text('Measure TCP'),
              onPressed: () => _startTcpMeasurements(),
            ),
            TextButton(
              child: const Text('Measure Nearby WIFY'),
              onPressed: () => _startNearbyMeasurements(),
            ),
            const Spacer(
              flex: 1,
            ),
            Text(_ipAddresses),
            const Spacer(
              flex: 1,
            ),
            StreamBuilder<String>(
              stream: log.stream,
              builder: (context, snapshot) {
                return Text(snapshot.data ?? '');
              },
            ),
            const Spacer(
              flex: 1,
            ),
          ],
        ),
      ),
    );
  }
}
