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
  bool showTrails = true;
  final List<Body> bodies = [];
}

class HomeState extends State<Home>{

  final random = Random();
  final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple];
  Timer timer = Timer(Duration(), (){});
  int galaxyCount = 3;
  int galaxyRadius = 100;
  int starCount = 50;
  double coreMass = 1000;
  final values = Values();

  List<Body> get bodies => values.bodies;

  // the calculations are fully 3D, but constrain to x/y for now
  createGalaxy(double x, double y, double vx, double vy, Color color){
    final c = Core(
      position: Vector(x: x, y: y),
      velocity: Vector(x: vx, y: vy),
      mass: coreMass,
    );
    bodies.add(c);
    for(int i=0; i<starCount; i++){
      // place the star at a random distance from the core, but not closer than 20
      double r = 20+random.nextDouble()*(galaxyRadius-20);
      // set the velocity of a circular orbit at that radius
      double v = sqrt(c.mass/r);
      // add stars in orbit around the core
      double theta = random.nextDouble()*pi*2;
      bodies.add(
        Star(
          // rotate around the core
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
    // defer because we need screen size
    WidgetsBinding.instance.addPostFrameCallback((_) => startTimer());
    super.initState();
  }

  create(){

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

  }

  startTimer(){
    timer.cancel();
    final Size size = MediaQuery.of(context).size;
    Rect screen = Rect.fromLTWH(-size.width/2, -size.height/2, size.width, size.height);
    timer = Timer.periodic(Duration(milliseconds: 20), (t) {
      // reset if all cores have moved offscreen
      if(bodies.whereType<Core>().any((c) => screen.contains(Offset(c.position.x, c.position.y)))){
        calc();
      }
      else {
        create();
        startTimer();
      }

      setState(() {});
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
              getSlider(
                title: "Galaxies",
                value: galaxyCount.toDouble(),
                min: 2,
                max: 5,
                divisions: 3,
                ticks: 4,
                labels: [2, 3, 4, 5].map((v) => Text(v.toStringAsFixed(0))).toList(),
                callback: (v) => galaxyCount = v.toInt(),
              ),
              SizedBox(height: 10),
              getSlider(
                title: "Galaxy Radius",
                value: galaxyRadius.toDouble(),
                min: 50,
                max: 200,
                divisions: 3,
                labels: [50, 100, 150, 200].map((v) => Text(v.toStringAsFixed(0))).toList(),
                callback: (v) => galaxyRadius = v.toInt(),
              ),
              SizedBox(height: 10),
              getSlider(
                title: "Stars",
                value: starCount.toDouble(),
                min: 20,
                max: 100,
                divisions: 8,
                labels: [20, 100].map((v) => Text(v.toStringAsFixed(0))).toList(),
                callback: (v) => starCount = v.toInt(),
              ),
              SizedBox(height: 10),
              getSlider(
                title: "Core Mass",
                value: coreMass,
                min: 100,
                max: 10000,
                divisions: 99,
                labels: [2, 4].map((v) => Text("10^${v.toStringAsFixed(0)}")).toList(),
                callback: (v) => coreMass = v,
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Show Trails"),
                  Switch(value: values.showTrails, onChanged: (v) => values.showTrails = v),
                ],
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    timer.isActive ? timer.cancel() : startTimer();
                    setState(() {});
                  },
                  child: Text(timer.isActive ? "Pause" : "Resume"),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(onPressed: timer.isActive ? null : calc, child: Text("Step")),
              ),
              SizedBox(height: 10),
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

  Widget getSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    int ticks = 16,
    required List<Widget> labels,
    required Function(double) callback
  }){
    return InputDecorator(
      decoration: InputDecoration(
        labelText: "$title: ${value.toStringAsFixed(0)}",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
      ),
      child: Column(
        children: [
          Theme(
            data: ThemeData(sliderTheme: SliderTheme.of(context).copyWith(overlayShape: SliderComponentShape.noThumb)),
            child: Slider(
              divisions: divisions,
              min: min,
              max: max,
              value: value,
              onChanged: callback,
              label: value.toStringAsFixed(0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(ticks, (index) => SizedBox(
                    height: 5,
                    child: VerticalDivider(width: 8),
                  )),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: labels,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}