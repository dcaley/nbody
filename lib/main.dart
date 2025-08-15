import 'package:flutter/material.dart';

import 'home.dart';

void main() {
  runApp(const NBody());
}

class NBody extends StatelessWidget {
  const NBody({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: "N-Body",
    debugShowCheckedModeBanner: false,
    home: Home(),
  );
}
