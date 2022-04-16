// ignore_for_file: avoid_print

import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

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

  /// The current Bonsoir discovery object instance.
  BonsoirDiscovery? _bonsoirDiscovery;

  /// Contains all discovered (and resolved) services.
  final List<ResolvedBonsoirService> _resolvedServices = [];

  /// The subscription object.
  StreamSubscription<BonsoirDiscoveryEvent>? _subscription;

  /// Returns all discovered (and resolved) services.
  List<ResolvedBonsoirService> get discoveredServices => List.of(_resolvedServices.toSet());

  /// Stops the Bonsoir discovery.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _bonsoirDiscovery?.stop();
  }
}
