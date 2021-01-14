// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info/device_info.dart';
import 'package:get_mac/get_mac.dart';
import 'package:imei_plugin/imei_plugin.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart';
import 'geolocation.dart';

void main() {
  runZonedGuarded(() {
    runApp(MyApp());
  }, (dynamic error, dynamic stack) {
    print(error);
    print(stack);
  });
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> _deviceData = <String, dynamic>{};
  bool filter = false;
  String _platformVersion = 'Unknown';
  String localization = "";
  String wifiBSSID = "";
  String wifiIP = "";
  String wifiName = "";
  String uuid = "";
  String imei = "";
  bool load = false;
  List<String> multiImei = [];
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    setState(() {
      load = true;
    });
    Map<String, dynamic> deviceData;
    imei = await ImeiPlugin.getImei();
    multiImei = await ImeiPlugin.getImeiMulti(); //for double-triple SIM phones
    uuid = await ImeiPlugin.getId();
    String platformVersion = "Desconhecido";
    wifiBSSID = await WifiInfo().getWifiBSSID();
    wifiIP = await WifiInfo().getWifiIP();
    wifiName = await WifiInfo().getWifiName();

    await determinePosition()
        .then((value) => {localization = value.toString()});
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await GetMac.macAddress;
    } on PlatformException {
      platformVersion = 'Failed to get Device MAC Address.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });

    try {
      if (Platform.isAndroid) {
        if (filter) {
          deviceData =
              _readAndroidShortBuildData(await deviceInfoPlugin.androidInfo);
        } else {
          deviceData =
              _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
        }
      } else if (Platform.isIOS) {
        if (filter) {
          deviceData = _readIosDeviceShortInfo(await deviceInfoPlugin.iosInfo);
        } else {
          deviceData = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
        }
      }
    } on PlatformException {
      deviceData = <String, dynamic>{
        'Error:': 'Failed to get platform version.'
      };
    }

    if (!mounted) return;

    setState(() {
      _deviceData = deviceData;
      load = false;
    });
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,
      'isPhysicalDevice': build.isPhysicalDevice,
      'androidId': build.androidId,
      'systemFeatures': build.systemFeatures,
      'MAC': _platformVersion,
      'Localization': localization,
      'Wifi BSSID': wifiBSSID,
      'Wifi Name': wifiName,
      'Wifi IP': wifiIP,
      'IMEI': multiImei.toString()
    };
  }

  Map<String, dynamic> _readAndroidShortBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'model': build.model,
      'isPhysicalDevice': build.isPhysicalDevice,
      'MAC': _platformVersion,
      'Localization': localization,
      'Wifi BSSID': wifiBSSID,
      'Wifi Name': wifiName,
      'Wifi IP': wifiIP,
      'IMEI': multiImei.toString()
    };
  }

  Map<String, dynamic> _readIosDeviceShortInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'model': data.model,
      'isPhysicalDevice': data.isPhysicalDevice,
      'MAC': _platformVersion,
      'Localization': localization,
      'Wifi BSSID': wifiBSSID,
      'Wifi Name': wifiName,
      'Wifi IP': wifiIP
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'model': data.model,
      'localizedModel': data.localizedModel,
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'utsname.sysname:': data.utsname.sysname,
      'utsname.nodename:': data.utsname.nodename,
      'utsname.release:': data.utsname.release,
      'utsname.version:': data.utsname.version,
      'utsname.machine:': data.utsname.machine,
      'MAC': _platformVersion,
      'Localization': localization,
      'Wifi BSSID': wifiBSSID,
      'Wifi Name': wifiName,
      'Wifi IP': wifiIP
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF283266),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                initPlatformState();
              },
            ),
            IconButton(
              icon: filter ? Icon(Icons.list) : Icon(Icons.filter_alt),
              onPressed: () {
                setState(() {
                  filter = !filter;
                });
                initPlatformState();
              },
            ),
            SizedBox(
              width: 10,
            )
          ],
          title: Text(Platform.isAndroid ? 'Android' : 'iOS'),
        ),
        body: !load
            ? ListView(
                children: _deviceData.keys.map((String property) {
                  return Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          property,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFF56E28),
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Montserrat'),
                        ),
                      ),
                      Expanded(
                          child: Container(
                        padding:
                            const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
                        child: Text(
                          '${_deviceData[property]}',
                          maxLines: 10,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Montserrat'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                    ],
                  );
                }).toList(),
              )
            //Color(0xFF283266)
            : Center(
                child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFF56E28))),
              ),
      ),
    );
  }
}
