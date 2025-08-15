import 'package:flutter/material.dart';

import 'body.dart';
import 'home.dart';

class ScreenPainter extends CustomPainter{

  final Values values;

  ScreenPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {

    // prevent drawing outside bounds, I'm not clear why we need to do this
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawColor(Colors.black, BlendMode.src);

    // put the origin in the middle of the screen
    canvas.translate(size.width/2, size.height/2);

    for (Body b in values.bodies) {
      canvas.drawCircle(
        Offset(b.position.x, b.position.y),
        b.paintSize,
        Paint()
          ..color = b.color
          ..style = PaintingStyle.fill,
      );

      // draw the "trails"
      if(values.showHistory && b.showHistory) {
        for (int i=0; i<b.history.length; i++) {
          // line to the previous position, last one connects to the current position
          final next = i+1 == b.history.length ? b.position : b.history.elementAt(i+1);
          // drawing individual line segments instead of using a Path so we can control the alpha value
          // TODO but the performance sucks
          canvas.drawLine(
            Offset(b.history.elementAt(i).x, b.history.elementAt(i).y),
            Offset(next.x, next.y),
            Paint()
              ..strokeWidth = b.paintSize
              ..color = b.color.withValues(alpha: i/b.history.length)
              ..style = PaintingStyle.stroke,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}