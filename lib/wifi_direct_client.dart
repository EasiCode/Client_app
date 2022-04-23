// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';

late NearbyService _nearbyService;
List<Device> devices = [];
List<Device> connectedDevices = [];

enum DeviceType { advertiser, browser }

late final DeviceType deviceType;

// .............................................................................
class NearbyClient {
  // ...........................................................................
  NearbyClient() {
    init();
  }

  // ...........................................................................
  void connectPeer(Device device) {
    if (device.state == SessionState.notConnected) {
      _nearbyService.invitePeer(
        deviceID: device.deviceId,
        deviceName: device.deviceName,
      );
    }
  }

  // ...........................................................................
  void init() {
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
      for (final device in devices) {
        connectPeer(device);
      }
    });
  }
}
