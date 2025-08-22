import 'package:flutter/material.dart';

import 'body.dart';
import 'core.dart';
import 'home.dart';

class ScreenPainter extends CustomPainter{

  final Values values;

  ScreenPainter(this.values, {required super.repaint});

  @override
  void paint(Canvas canvas, Size size) {

    // prevent drawing outside bounds, I'm not clear why we need to do this
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawColor(Colors.black, BlendMode.src);

    // put the origin in the middle of the screen
    canvas.translate(size.width/2, size.height/2);
    // ...unless we are following the first galaxy
    if(values.follow){
      final core = values.bodies.firstWhere((b) => b is Core);
      canvas.translate(-core.position.x, -core.position.y);
    }

    // I want to use drawRawPoints here, but that doesn't help with the real bottleneck,
    // which is the different paint for each trail.  So not worth the complication.

    for (Body b in values.bodies) {
      canvas.drawCircle(
        Offset(b.position.x, b.position.y),
        b.paintSize,
        Paint()
          ..color = b.color
          ..style = PaintingStyle.fill,
      );

      // draw the "trails"
      if(values.showTrails && b.showTrails && b.history.isNotEmpty) {

        final path = Path()..moveTo(b.position.x, b.position.y);
        for(int i=b.history.length-1; i>=0; i--){
          path.lineTo(b.history.elementAt(i).x, b.history.elementAt(i).y);
        }

        canvas.drawPath(path, Paint()
          ..isAntiAlias = true
          ..strokeWidth = b.paintSize
          ..shader = LinearGradient(
            colors: [b.color, b.color.withValues(alpha: 0)],
          ).createShader(Rect.fromLTRB(b.position.x, b.position.y, b.history.first.x, b.history.first.y))
          ..strokeWidth = b.paintSize
          ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}