/// "The entry point of the Flutter application, responsible for initializing services and running the app."
import 'package:flutter/material.dart';
import 'app.dart';

import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const RRApp());
}
