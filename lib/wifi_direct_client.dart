// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';

// .............................................................................
class NearbyClient {
  // ...........................................................................
  NearbyClient() {
    _init();
  }

  // ...........................................................................
  Future<void> sendMessage(String message) async {
    await isConnected;
    final firstDevice = _devices.first;
    _nearbyService.sendMessage(firstDevice.deviceId, message);
  }

  // ...........................................................................
  Future<void> get isConnected => _isConnected.future;

  // ######################
  // Private
  // ######################

  // ...........................................................................
  late NearbyService _nearbyService;
  final List<Device> _devices = [];
  final _isConnected = Completer();

  // ...........................................................................
  void _deviceDidChange(Device device) async {
    if (device.state == SessionState.notConnected) {
      await _nearbyService.invitePeer(
        deviceID: device.deviceId,
        deviceName: device.deviceName,
      );

      if (!_isConnected.isCompleted) {
        _isConnected.complete();
      }
    }
  }

  // ...........................................................................
  void _init() {
    _nearbyService = NearbyService();

    _nearbyService.init(
        serviceType: 'mpconn',
        strategy: Strategy.P2P_CLUSTER,
        callback: (isRunning) async {
          if (isRunning) {
            await _nearbyService.stopBrowsingForPeers();
            await Future.delayed(const Duration(microseconds: 200));
            await _nearbyService.startBrowsingForPeers();
            print("browsing for peer...");
            _listenAndConnect();
          }
        });
  }

  // ...........................................................................
  void _listenAndConnect() {
    _nearbyService.stateChangedSubscription(callback: (devices) {
      _devices.addAll(devices);

      for (final device in devices) {
        _deviceDidChange(device);
      }
    });
  }
}
