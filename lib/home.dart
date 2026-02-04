import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nbody/values.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

import 'screen_painter.dart';
import 'star.dart';
import 'body.dart';
import 'core.dart';

class Home extends StatefulWidget{

  const Home({super.key});

  @override
  State<StatefulWidget> createState() => HomeState();
}

class HomeState extends State<Home> with SingleTickerProviderStateMixin{

  final random = Random();
  final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple];
  // placeholder so this can be non-null
  Timer timer = Timer(Duration(), (){});
  int galaxyCount = 5;
  int galaxyRadius = 100;
  int starCount = 100;
  double coreMass = 1000;
  final values = Values();
  late final AnimationController animationController;

  List<Star> get stars => values.stars;
  List<Core> get cores => values.cores;
  List<Body> get bodies => values.bodies;

  // the calculations are fully 3D, but constrain to x/y for now
  createGalaxy(double x, double y, double vx, double vy, Color color){
    final c = Core(
      position: Vector3(x, y, 0),
      velocity: Vector3(vx, vy, 0),
      mass: coreMass,
    );
    cores.add(c);

    // randomly rotate the galaxy
    final q = values.flatten ? Quaternion.identity() : Quaternion.axisAngle(
      Vector3(random.nextDouble(), random.nextDouble(), random.nextDouble()),
      random.nextDouble()*pi*2,
    );

    // add stars in orbit around the core
    for(int i=0; i<starCount; i++){
      // place the star at a random distance from the core, but not closer than 20
      double r = 20+random.nextDouble()*(galaxyRadius-20);
      final rotateQ = Quaternion.axisAngle(Vector3(0, 0, 1), random.nextDouble()*pi*2);

      stars.add(
        Star(
          // rotate around the core
          position: q.rotate(rotateQ.rotate(Vector3(0, r, 0))),
          // set the velocity to that of a circular orbit at the radius and rotate that too
          velocity: q.rotate(rotateQ.rotate(Vector3(sqrt(c.mass/r), 0, 0))),
          offset: c,
          color: color,
        ),
      );
    }
  }

  void createGrid(){

    values.grid.clear();

    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).width;

    for(double i=-width/2; i<=width/2; i+=100){
      values.grid.add((Vector3(i, -height/2, 0), Vector3(i, height/2, 0)));
    }

    for(double i=-height/2; i<=height/2; i+=100){
      values.grid.add((Vector3(-width/2, i, 0), Vector3(width/2, i, 0)));
    }
  }

  @override
  initState(){

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 20),
    )..repeat();

    // defer because we need screen size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      create();
      startTimer();
    });
    super.initState();
  }

  create(){

    cores.clear();
    stars.clear();

    for(int i=0; i<galaxyCount;){
      // space galaxy randomly around origin
      final theta = random.nextDouble()*pi*2;
      // and at a random distance
      final r = 600.0+random.nextInt(200);
      final x = r*cos(theta);
      final y = r*sin(theta);

      // ensure adequate spacing between galaxies
      if(cores.every((c) => c.distance(x, y, 0)>600)){
        // give some variation to initial trajectory
        createGalaxy(x, y, -(x+random.nextInt(400))/400, -(y+random.nextInt(400))/400, colors[i]);
        i++;
      }
    }

    createGrid();

    values.buildPerfCollections();
  }

  startTimer(){
    timer.cancel();
    final size = MediaQuery.of(context).size;
    final screen = Rect.fromLTWH(-size.width/2, -size.height/2, size.width, size.height);
    timer = Timer.periodic(Duration(milliseconds: 20), (t) {
      // reset if all cores have moved offscreen
      if(cores.any((c) => screen.contains(Offset(c.position.x, c.position.y)))){
        calc();
      }
      else {
        create();
        startTimer();
      }
    });
  }

  calc() {
    double dx, dy, dz, distance, acceleration;
    for (Core b2 in cores) {
      for (Body b1 in bodies) {
        if (b1 != b2) {
          dx = b1.position.x - b2.position.x;
          dy = b1.position.y - b2.position.y;
          dz = b1.position.z - b2.position.z;
          distance = sqrt(dx * dx + dy * dy + dz * dz);
          acceleration = -(b2.mass / (distance * distance));
          b1.velocity.x += acceleration * (dx / distance);
          b1.velocity.y += acceleration * (dy / distance);
          b1.velocity.z += acceleration * (dz / distance);
        }
      }
    }

    // add velocities to positions
    for (Body b in bodies) {
      b.tick();
    }

    // update the values to be painted
    values.updateFloatLists();
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: CustomPaint(
          painter: ScreenPainter(values, repaint: animationController),
          // the empty child is needed to give the canvas a non-zero height
          child: Container(),
        ),
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
                callback: (v) => setState(() => galaxyCount = v.toInt()),
              ),
              SizedBox(height: 10),
              getSlider(
                title: "Galaxy Radius",
                value: galaxyRadius.toDouble(),
                min: 50,
                max: 200,
                divisions: 3,
                labels: [50, 100, 150, 200].map((v) => Text(v.toStringAsFixed(0))).toList(),
                callback: (v) => setState(() => galaxyRadius = v.toInt()),
              ),
              SizedBox(height: 10),
              getSlider(
                title: "Stars",
                value: starCount.toDouble(),
                min: 20,
                max: 100,
                divisions: 8,
                labels: [20, 100].map((v) => Text(v.toStringAsFixed(0))).toList(),
                callback: (v) => setState(() => starCount = v.toInt()),
              ),
              SizedBox(height: 10),
              getSlider(
                title: "Core Mass",
                value: coreMass,
                min: 100,
                max: 10000,
                divisions: 99,
                labels: [2, 4].map((v) => Text("10^${v.toStringAsFixed(0)}")).toList(),
                callback: (v) => setState(() =>coreMass = v),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Follow"),
                  Switch(value: values.follow, onChanged: (v) => setState(() => values.follow = v)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Flatten"),
                  Switch(value: values.flatten, onChanged: (v) => setState(() => values.flatten = v)),
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