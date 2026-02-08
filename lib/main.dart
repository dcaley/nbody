import 'package:flutter/material.dart';

import 'home.dart';

void main() {
  runApp(NBody());
}

class NBody extends StatelessWidget {

  static final appKey = GlobalKey<NavigatorState>();

  const NBody({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: "N-Body",
    debugShowCheckedModeBanner: false,
    home: Material(child: Home()),
    navigatorKey: appKey,
  );
}
