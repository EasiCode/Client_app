import 'dart:async';
import 'dart:io';

import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
//import 'package:device_info/device_info.dart';

late NearbyService nearbyService;
late StreamSubscription subscription;
List<Device> devices = [];
List<Device> connectedDevices = [];
enum DeviceType { advertiser, browser }
late final DeviceType deviceType;

class NearbyClient {
  var device = devices[];
  NearbyClient() {
    init();
   //connectPeer(device);
  }


  connectPeer(Device device) {
     
    
    switch (device.state) {
      case SessionState.notConnected:
        nearbyService.invitePeer(
          deviceID: device.deviceId,
          deviceName: device.deviceName,
        );
        break;
      case SessionState.connected:
        nearbyService.disconnectPeer(deviceID: device.deviceId);
        break;
      case SessionState.connecting:
        break;
    }
  }

  void init() async {
    nearbyService = NearbyService();

    await nearbyService.init(
        serviceType: 'mpconn',
        strategy: Strategy.P2P_CLUSTER,
        callback: (isRunning) async {
          if (isRunning) {
            await nearbyService.stopBrowsingForPeers();
            await Future.delayed(const Duration(microseconds: 200));
            await nearbyService.startBrowsingForPeers();
            print("browsing for peer...");
          }
        });

    subscription =
        nearbyService.stateChangedSubscription(callback: (devicesList) {
      devicesList.forEach((element) {
        print(
            " deviceId: ${element.deviceId} | deviceName: ${element.deviceName} | state: ${element.state}");

              connectPeer(element);
        if (Platform.isAndroid) {
          if (element.state == SessionState.connected) {
            nearbyService.stopBrowsingForPeers();
          } else {
            nearbyService.startBrowsingForPeers();
            //print("not connected ooooooooooooooooooo");
          }
        }
      });

      /* setState(() {
        devices.clear();
        devices.addAll(devicesList);
        connectedDevices.clear();
        connectedDevices.addAll(devicesList
            .where((d) => d.state == SessionState.connected)
            .toList());
      }); */
    });
  }
  // make connection

}
