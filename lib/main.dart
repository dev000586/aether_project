// lib/main.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[DeviceOrientation.portraitUp],
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  if(kDebugMode){

    // no real API key needed since no traffic leaves the machine.
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'fake-api-key',
        appId: '1:000000000000:android:0000000000000000',
        messagingSenderId: '000000000000',
        projectId: 'demo-aether',   // must match --project flag above
      ),
    );

    // Connect Firestore to the local emulator.
    // Use 10.0.2.2 on Android emulator (it maps to host 127.0.0.1).
    // Use 127.0.0.1 on iOS simulator and physical devices on the same LAN.
    if(Platform.isAndroid){
      FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
    }else{
      FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
    }
  }else{
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await initDependencies();

  runApp(const AetherApp());
}
