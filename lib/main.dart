import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:intl/intl.dart";
import 'package:loplat_plengi/loplat_plengi.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

/*/// The name associated with the UI isolate's [SendPort].
const String isolateName = 'isolate';

/// A port used to communicate from a background isolate to the UI isolate.
final ReceivePort port = ReceivePort();

/// The background port
SendPort? uiSendPort;

/// The callback for loplat plengi
Future<bool> callback(String msg) async {
  String locationInfo = getLocationInfo(msg);
  developer.log('result: $locationInfo');

  // This will be null if we're running in the background.
  uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
  uiSendPort?.send(null);
  return true;
}*/

String getEngineStatusToString(int engineStatus) {
  String engineStatusStr = "NOT_INITIALIZED";
  if (engineStatus == -1) {
    engineStatusStr = "NOT_INITIALIZED";
  } else if (engineStatus == 0) {
    engineStatusStr = "STOPPED";
  } else if (engineStatus == 1) {
    engineStatusStr = "STARTED";
  } else if (engineStatus == 2) {
    engineStatusStr = "STOPPED_TEMP";
  } else if (engineStatus == -8) {
    engineStatusStr = "ALREADY STARTED";
  }
  return engineStatusStr;
}

String getChangeResultToString(int result) {
  String engineStatusStr = "NOT_INITIALIZED";
  if (result == -1) {
    engineStatusStr = "FAIL";
  } else if (result == -2) {
    engineStatusStr = "PENDING";
  } else if (result == -3) {
    engineStatusStr = "NETWORK_FAIL";
  } else if (result == -4) {
    engineStatusStr = "ERROR_CLOUD_ACCESS";
  } else if (result == -5) {
    engineStatusStr = "FAIL_INTERNET_UNAVAILABLE";
  } else if (result == -6) {
    engineStatusStr = "FAIL_WIFI_SCAN_UNAVAILABLE";
  } else if (result == -8) {
    engineStatusStr = "ALREADY_STARTED";
  } else if (result == -9) {
    engineStatusStr = "FAIL_CONSUMER_STATE";
  } else if (result == -10) {
    engineStatusStr = "NOT_INITIALIZED";
  }
  return engineStatusStr;
}

String getLocationInfo(String log) {
  if (log.isEmpty) {
    return '';
  }
  Map<String, dynamic> jsonData = jsonDecode(log);
  String inNear = '';
  String locationInfo = '';
  if (jsonData['place'] != null) {
    if (jsonData['place']['accuracy'] >= jsonData['place']['threshold']) {
      inNear = '[IN]';
    } else {
      inNear = '[NEAR]';
    }
    locationInfo += '  $inNear${jsonData['place']['name']},'
        '${jsonData['place']['tags']}(${jsonData['place']['loplat_id']}),'
        '${jsonData['place']['floor']}F,${jsonData['place']['accuracy']}/${jsonData['place']['threshold']}';
  }
  if (jsonData['complex'] != null) {
    locationInfo +=
    '\n  [${jsonData['complex']['id']}]${jsonData['complex']['name']}';
  }
  if (jsonData['area'] != null) {
    locationInfo +=
    '\n  [${jsonData['area']['id']}]${jsonData['area']['tag']},${jsonData['area']['name']}';
  }
  if (jsonData['district'] != null) {
    locationInfo +=
    '\n  ${jsonData['district']['lv1_name']} ${jsonData['district']['lv2_name']} ${jsonData['district']['lv3_name']}';
  }
  if (jsonData['location'] != null) {
    locationInfo +=
    '\n  ${jsonData['location']['lat']}, ${jsonData['location']['lng']}';
  }
  if (jsonData['advertisement'] != null) {
    locationInfo +=
    '\n  AD)${jsonData['advertisement']['campaign_id']}, ${jsonData['advertisement']['title']}, ${jsonData['advertisement']['body']}';
  }
  return locationInfo;
}

Future<void> main() async {
  /// Register the UI isolate's SendPort to allow for communication from the background isolate.
/*  IsolateNameServer.registerPortWithName(
    port.sendPort,
    isolateName,
  );*/
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());

  /// After runApp, register callback
  // LoplatPlengiPlugin.setListener(callback);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _plengiStatus = "NOT_INITIALIZED";
  String _loplatResults = '';
  bool _isAdNetworkEnable = false;
  bool getLocationBtnEnabled = true;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    final SharedPreferences prefs = await  SharedPreferences.getInstance();
    if (Platform.isAndroid) {
      await Permission.locationWhenInUse.request();
      var status = await Permission.locationWhenInUse.status;
      if (status.isDenied) {
        openAppSettings();
      }
      await Permission.notification.request();
      status = await Permission.notification.status;
      if (status.isDenied) {
        openAppSettings();
      }
    } else if (Platform.isIOS) {
      await LoplatPlengiPlugin.requestAlwaysLocationAuthorization();
      await LoplatPlengiPlugin.requestAlwaysAuthorization();
      // await Permission.appTrackingTransparency.request();
      // await Permission.locationWhenInUse.request();
      // var status = await Permission.locationWhenInUse.status;
      // if (status.isGranted) {
      //   await Permission.locationAlways.request();
      // }
    }
    final fcmToken = await FirebaseMessaging.instance.getToken();

    developer.log("rymins fcmToken: $fcmToken");
    FirebaseMessaging.instance.onTokenRefresh
        .listen((fcmToken) {
      developer.log("rymins onTokenRefresh: $fcmToken");
    })
        .onError((err) {
    });
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await LoplatPlengiPlugin.getPlatformVersion ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    int engineStatus = await LoplatPlengiPlugin.getEngineStatus;
    String engineStatusStr = "NOT_INITIALIZED";
    if (engineStatus == -1) {
      engineStatusStr = "NOT_INITIALIZED";
      var status = await LoplatPlengiPlugin.start("loplat", "loplatsecret");
      if (status == 0) {
        engineStatusStr = "STARTED";
      }
    } else if (engineStatus == 0) {
      engineStatusStr = "STOPPED";
      if (Platform.isIOS) {
        var status = await LoplatPlengiPlugin.start("loplat", "loplatsecret");
        if (status == 0) {
          engineStatusStr = "STARTED";
        }
      }
    } else if (engineStatus == 1) {
      engineStatusStr = "STARTED";
    } else if (engineStatus == 2) {
      engineStatusStr = "STOPPED_TEMP";
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _plengiStatus = engineStatusStr;
      _isAdNetworkEnable =  prefs.getBool("adNetwork")?? false;
    });
  }

  startEngine(String id, String pw) async {
    try {
      final res = await LoplatPlengiPlugin.start(id, pw);
      String formattedDate =
      DateFormat('MM-dd HH:mm:ss').format(DateTime.now());
      if (res == 0) {
        int engineStatus = await LoplatPlengiPlugin.getEngineStatus;
        setState(() {
          _plengiStatus = getEngineStatusToString(engineStatus);
          _loplatResults =
          '$formattedDate\nEngine : $_plengiStatus\n\n$_loplatResults';
        });
      } else {
        setState(() {
          _loplatResults =
          '$formattedDate\nEngine : ${_plengiStatus = getChangeResultToString(res ?? -1)}\n\n$_loplatResults';
        });
      }
    } on Error catch (e, t) {
      developer.log("Error: $e $t");
    } catch (e, t) {
      developer.log("Error: $e $t");
    }
  }

  stopEngine() async {
    try {
      final res = await LoplatPlengiPlugin.stop;
      String formattedDate =
      DateFormat('MM-dd HH:mm:ss').format(DateTime.now());
      if (res == 0) {
        int engineStatus = await LoplatPlengiPlugin.getEngineStatus;
        String formattedDate =
        DateFormat('MM-dd HH:mm:ss').format(DateTime.now());
        setState(() {
          _plengiStatus = getEngineStatusToString(engineStatus);
          _loplatResults =
          '$formattedDate\nEngine : $_plengiStatus\n\n$_loplatResults';
        });
      } else {
        setState(() {
          _loplatResults =
          '$formattedDate\nEngine : ${_plengiStatus = getChangeResultToString(res ?? -1)}\n\n$_loplatResults';
        });
      }
    } on Error catch (e, t) {
      developer.log("Error: $e $t");
    } catch (e, t) {
      developer.log("Error: $e $t");
    }
  }

  enableAdNetwork() async {
    try {
      final res = await LoplatPlengiPlugin.enableAdNetwork(!_isAdNetworkEnable);
      final SharedPreferences prefs = await  SharedPreferences.getInstance();
      String formattedDate =
      DateFormat('MM-dd HH:mm:ss').format(DateTime.now());
      if (res == "success") {
        setState(() {
          _loplatResults =
          '$formattedDate\nEnableAdNetwork : ${!_isAdNetworkEnable}\n\n$_loplatResults';
          _isAdNetworkEnable = !_isAdNetworkEnable;
          prefs.setBool("adNetwork",_isAdNetworkEnable );
        });
      }
    } on Error catch (e, t) {
      developer.log("Error: $e $t");
    } catch (e, t) {
      developer.log("Error: $e $t");
    }
  }

  updateLog(String log) {
    if (log.isEmpty) {
      return;
    }
    String locationInfo = getLocationInfo(log);
    if (locationInfo.isNotEmpty) {
      String formattedDate =
      DateFormat('MM-dd HH:mm:ss').format(DateTime.now());
      setState(() {
        _loplatResults = '$formattedDate\n$locationInfo\n\n$_loplatResults';
        getLocationBtnEnabled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text(
              'loplat SDK plugin example app',
              style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          body: Builder(builder: (context) => _buildBody(context))),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SafeArea(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                    'Running on: $_platformVersion\nplaceEngineStatus: $_plengiStatus enableAdnetwork:$_isAdNetworkEnable'),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          await startEngine("loplat", "loplatsecret");
                        },
                        child: const Text('Start'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          await stopEngine();
                        },
                        child: const Text('Stop'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: getLocationBtnEnabled
                          ? () {
                        setState(() {
                          getLocationBtnEnabled = false;
                        });
                        Timer timer =
                        Timer(const Duration(seconds: 8), () {
                          setState(() {
                            if (!getLocationBtnEnabled) {
                              getLocationBtnEnabled = true;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('응답시간이 초과되었습니다')));
                            }
                          });
                        });
                        _getCurrentPlace().then((value) {
                          timer.cancel();
                          updateLog(value!);
                        });
                      }
                          : null,
                      child: const Text('Get Location'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 8.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          await enableAdNetwork();
                        },
                        child: const Text('enalbe adnetwork'),
                      ),
                    ),
                  ],
                ),
                Expanded(
                    flex: 1,
                    child: Align(
                        alignment: Alignment.topLeft,
                        child:
                        SingleChildScrollView(child: Text(_loplatResults))))
              ],
            ),
          ),
        ));
  }

  Future<String?> _getCurrentPlace() async {
    String? res = await LoplatPlengiPlugin.testRefreshPlaceForeground();
    if (res == null || res.isEmpty) {
      return '응답 결과가 없습니다';
    }
    return res;
  }
}
