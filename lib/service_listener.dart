// ignore_for_file: avoid_print

import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
//import 'package:client_app/client.dart';
import 'package:client_app/bonsoir_service.dart';

class ServiceListener {
  bool isServiceResolved = true;

  Future<String> ipAddress() {
    return Future.value('127.0.0.1');
  }

  Future<int> port() {
    return Future.value(18910);
  }
}

/// Provider model that allows to handle Bonsoir discoveries.
class BonsoirDiscoveryModel extends ChangeNotifier {
  /// Creates a new Bonsoir discovery model instance.
  BonsoirDiscoveryModel() {
    start();
  }

  /// The current Bonsoir discovery object instance.
   BonsoirDiscovery? _bonsoirDiscovery;

  /// Contains all discovered (and resolved) services.
  final List<ResolvedBonsoirService> _resolvedServices = [];

  /// The subscription object.
  StreamSubscription<BonsoirDiscoveryEvent>? _subscription;

  /// Returns all discovered (and resolved) services.
  List<ResolvedBonsoirService> get discoveredServices =>
      List.of(_resolvedServices.toSet());

  /// Starts the Bonsoir discovery.
  Future<void> start() async {
    if ((_bonsoirDiscovery == null) || _bonsoirDiscovery!.isStopped) {
      _bonsoirDiscovery =
          BonsoirDiscovery(type: (await AppService.getService())!.type);
      await _bonsoirDiscovery!.ready;
     // await _bonsoirDiscovery!.start();
    }
    await _bonsoirDiscovery!.start();
    _subscription = _bonsoirDiscovery!.eventStream?.listen(_onEventOccurred);
  }

  /// Stops the Bonsoir discovery.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _bonsoirDiscovery?.stop();
  }

  /// Triggered when a Bonsoir discovery event occurred.
  void _onEventOccurred(BonsoirDiscoveryEvent event) async {
    if (event.service == null || !event.isServiceResolved) {
      return;
    }
    if (event.type == BonsoirDiscoveryEventType.DISCOVERY_SERVICE_RESOLVED &&
        event is ResolvedBonsoirService) {
      _resolvedServices.add(event.service! as ResolvedBonsoirService);

      print(event.service!.port);
      print((event.service as ResolvedBonsoirService).ip);
      print("This is the value of... ${event.service}");
      notifyListeners();
    }
   
    else if (event.type == BonsoirDiscoveryEventType.DISCOVERY_SERVICE_LOST) {
      _resolvedServices.remove(event.service);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
