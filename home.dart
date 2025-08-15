import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nbody/star.dart';
import 'package:nbody/vector.dart';

import 'body.dart';
import 'core.dart';

class Home extends StatefulWidget{

  const Home({super.key});

  @override
  State<StatefulWidget> createState() => HomeState();
}

class HomeState extends State<Home>{

  List<Body> bodies = [];
  Timer? timer;

  createGalaxy(double x, double y, double vx, double vy, Color color){
    Random random = Random();
    final c = Core(position: Vector(x: x, y: y), velocity: Vector(x: vx, y: vy));
    bodies.add(c);
    for(int i=0; i<50; i++){
      double theta = random.nextDouble()*pi*2;
      double r = 20.0+i;
      double v = sqrt(1000/r);
      bodies.add(
        Star(
          position: Vector(x: r*cos(theta), y: r*sin(theta)),
          velocity: Vector(x: v*sin(-theta), y: v*cos(-theta)),
          offset: c,
          color: color,
        ),
      );
    }
  }

  @override
  initState(){
    create();

    super.initState();
  }

  create(){

    bodies.clear();

    final random = Random();

    List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple];

    for(int i=0; i<4;){
      double theta = random.nextDouble()*pi*2;
      double r = 600.0+random.nextInt(200);
      double x = r*cos(theta);
      double y = r*sin(theta);

      if(bodies.whereType<Core>().every((c) => c.distance(x, y, 0)>600)){
        createGalaxy(x, y, -(x+random.nextInt(400))/400, -(y+random.nextInt(400))/400, colors[i]);
        i++;
      }
    }

    //createGalaxy(-500, 500, 1, -1, Colors.red);
    //createGalaxy(500, -500, -1, 1, Colors.blue);

    if(timer!=null && timer!.isActive) {
      timer!.cancel();
    }
    timer = Timer.periodic(Duration(milliseconds: 20), (_) => setState(() => calc()));
  }

  calc(){
    for (Body b1 in bodies) {
      for (Body b2 in bodies) {
        if(b1!=b2 && b1.influencedBy(b2)){
          double dx = b1.position.x - b2.position.x;
          double dy = b1.position.y - b2.position.y;
          double dz = b1.position.z - b2.position.z;
          double mag = sqrt(dx*dx+dy*dy+dz*dz);
          double acceleration = -(b2.mass/(mag*mag));
          b1.velocity.x += acceleration * (dx/mag);
          b1.velocity.y += acceleration * (dy/mag);
          b1.velocity.z += acceleration * (dz/mag);
        }
      }
    }

    for (Body b in bodies) {
      b.tick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
         SingleActivator(LogicalKeyboardKey.enter): () {
           print("foo");
           create();
         },
      },
      child: Focus(autofocus: true, child: CustomPaint(painter: ScreenPainter(bodies))),
    );
  }
}

class ScreenPainter extends CustomPainter{
  
  List<Body> bodies;

  ScreenPainter(this.bodies);
  
  @override
  void paint(Canvas canvas, Size size) {

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill,
    );

    // put the origin in the middle of the screen
    canvas.translate(size.width/2, size.height/2);

    for (Body b in bodies) {
      canvas.drawCircle(
        Offset(b.position.x, b.position.y),
        b.paintSize,
        Paint()
          ..color = b.color
          ..style = PaintingStyle.fill,
      );

      //if(b is Core)
      //canvas.drawLine(Offset(b.position.x, b.position.y), Offset(b.position.x+b.velocity.x*500, b.position.y+b.velocity.y*500), Paint()..color=Colors.white);

      if(b.paintHistory) {
        for (int i=0; i<b.history.length; i++) {
          final next = i+1 == b.history.length ? b.position : b.history.elementAt(i+1);
          // drawing individual line segments instead of using a Path so we can control the alpha value
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}