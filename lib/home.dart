import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'star.dart';
import 'vector.dart';
import 'body.dart';
import 'core.dart';

class Home extends StatefulWidget{

  const Home({super.key});

  @override
  State<StatefulWidget> createState() => HomeState();
}

class HomeState extends State<Home>{

  final List<Body> bodies = [];
  final random = Random();
  final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple];
  Timer? timer;

  // the calculations are fully 3D, but constrain to x/y for now
  createGalaxy(double x, double y, double vx, double vy, Color color){
    final c = Core(position: Vector(x: x, y: y), velocity: Vector(x: vx, y: vy));
    bodies.add(c);
    for(int i=0; i<50; i++){
      // set a random distance from the core
      double theta = random.nextDouble()*pi*2;
      double r = 20.0+i;
      double v = sqrt(1000/r);
      // add stars in orbit around the core
      bodies.add(
        Star(
          // rotate position around the core
          position: Vector(x: r*cos(theta), y: r*sin(theta)),
          // do the same for the velocity vector
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

    timer?.cancel();
    bodies.clear();

    for(int i=0; i<5;){
      // space galaxy randomly around origin
      double theta = random.nextDouble()*pi*2;
      // and at a random distance
      double r = 600.0+random.nextInt(200);
      double x = r*cos(theta);
      double y = r*sin(theta);

      // ensure adequate spacing between galaxies
      if(bodies.whereType<Core>().every((c) => c.distance(x, y, 0)>600)){
        // give some variation to initial trajectory
        createGalaxy(x, y, -(x+random.nextInt(400))/400, -(y+random.nextInt(400))/400, colors[i]);
        i++;
      }
    }

    timer = Timer.periodic(Duration(milliseconds: 20), (t) {
      // reset after 10 seconds
      if(t.tick*20>10000) {
        create();
      }
      else{
        calc();
        setState(() {});
      }
    });
  }

  calc() {
    for (Body b1 in bodies) {
      for (Body b2 in bodies) {
        if (b1 != b2 && b1.influencedBy(b2)) {
          double dx = b1.position.x - b2.position.x;
          double dy = b1.position.y - b2.position.y;
          double dz = b1.position.z - b2.position.z;
          double mag = sqrt(dx * dx + dy * dy + dz * dz);
          double acceleration = -(b2.mass / (mag * mag));
          b1.velocity.x += acceleration * (dx / mag);
          b1.velocity.y += acceleration * (dy / mag);
          b1.velocity.z += acceleration * (dz / mag);
        }
      }
    }

    // add velocities to positions
    for (Body b in bodies) {
      b.tick();
    }
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    // hit enter to restart simulation
    bindings: <ShortcutActivator, VoidCallback>{
      SingleActivator(LogicalKeyboardKey.enter) : create,
    },
    child: Focus(autofocus: true, child: CustomPaint(painter: ScreenPainter(bodies))),
  );
}

class ScreenPainter extends CustomPainter{
  
  List<Body> bodies;

  ScreenPainter(this.bodies);
  
  @override
  void paint(Canvas canvas, Size size) {

    canvas.drawColor(Colors.black, BlendMode.src);

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

      // draw the "trails"
      if(b.paintHistory) {
        for (int i=0; i<b.history.length; i++) {
          // line to the previous position, last one connects to the current position
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}