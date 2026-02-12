import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nbody/model.dart';

class ScreenPainter extends CustomPainter{

  final Model model;
  final gridPaint = Paint()
    ..color = Colors.grey.shade900
    ..strokeWidth = 1.0
    ..isAntiAlias = false;

  ScreenPainter(this.model, {required super.repaint});

  @override
  void paint(Canvas canvas, Size size) {

    // prevent drawing outside bounds, I'm not clear why we need to do this
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawColor(Colors.black, BlendMode.src);

    // put the origin in the middle of the screen
    canvas.translate(size.width/2, size.height/2);
    // ...unless we are following the first galaxy
    if(model.follow){
      final core = model.cores.first;
      canvas.translate(-core.position.x, -core.position.y);
    }

    canvas.drawRawPoints(PointMode.lines, model.gridPaintPositions, gridPaint);

    model.starPaintPositions.forEach((k, v) => canvas.drawRawPoints(PointMode.points, v, Paint()
      ..color = k
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round)
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}