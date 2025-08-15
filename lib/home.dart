import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'screen_painter.dart';
import 'star.dart';
import 'vector.dart';
import 'body.dart';
import 'core.dart';

class Home extends StatefulWidget{

  const Home({super.key});

  @override
  State<StatefulWidget> createState() => HomeState();
}

// encapsulate values that we wish to pass to the painter
class Values{
  bool showHistory = true;
  final List<Body> bodies = [];
}

class HomeState extends State<Home>{

  final random = Random();
  final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple];
  Timer? timer;
  int galaxyCount = 3;
  int starCount = 50;
  final values = Values();

  List<Body> get bodies => values.bodies;

  // the calculations are fully 3D, but constrain to x/y for now
  createGalaxy(double x, double y, double vx, double vy, Color color){
    final c = Core(position: Vector(x: x, y: y), velocity: Vector(x: vx, y: vy));
    bodies.add(c);
    for(int i=0; i<starCount; i++){
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

    for(int i=0; i<galaxyCount;){
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
      // reset after 15 seconds
      if(t.tick*20>15000) {
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
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        // the empty child is needed to give the canvas a non-zero height
        child: CustomPaint(painter: ScreenPainter(values), child: Container()),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: "Number of Galaxies", border: OutlineInputBorder()),
                borderRadius: BorderRadius.all(Radius.circular(8)),
                items: [2, 3, 4, 5].map((i) => DropdownMenuItem<int>(value: i, child: Text(i.toString()))).toList(),
                value: galaxyCount,
                onChanged: (v) => galaxyCount = v!,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Show History"),
                  Switch(value: values.showHistory, onChanged: (v) => values.showHistory = v),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(onPressed: create, child: Text("Restart")),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}