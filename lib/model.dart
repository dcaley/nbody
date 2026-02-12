import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nbody/main.dart';
import 'package:nbody/star.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

import 'body.dart';
import 'core.dart';

typedef Line = (Vector3 a, Vector3 b);

// encapsulate values that we wish to share between the calculations and painter
class Model{

  // placeholder so this can be non-null
  Timer timer = Timer(Duration(), (){});

  int galaxyCount = 5;
  int galaxyRadius = 100;
  int starCount = 100;
  double coreMass = 1000;
  bool flatten = false;
  bool follow = false;
  final random = Random();
  final List<Line> grid = [];
  final List<Star> stars = [];
  final List<Core> cores = [];
  final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple];

  // we can obviously define all these dynamically, but that can get expensive when we have a lot of stars
  // instead, initialize them when we build the galaxies, then update the values when things change
  final bodies = <Body>[];
  final colorMap = <Color, List<Body>>{};
  final starPaintPositions = <Color, Float32List>{};
  Float32List gridPaintPositions = Float32List(0);

  void buildPerfCollections(){

    bodies.clear();
    colorMap.clear();
    starPaintPositions.clear();
    gridPaintPositions = Float32List(4*grid.length);

    bodies.addAll(cores);
    bodies.addAll(stars);

    // map colors to bodies
    for(Body b in bodies) {
      if (!colorMap.containsKey(b.color)) {
        colorMap[b.color] = <Body>[];
      }

      colorMap[b.color]!.add(b);
    }

    // initialize a list for each mapping
    colorMap.forEach((k, v) => starPaintPositions[k] = Float32List(v.length*2));

    updateFloatLists();
  }

  // for each body, update the appropriate list
  void updateFloatLists() {
    colorMap.forEach((k, v) {
      for (int i = 0; i < v.length; i++) {
        starPaintPositions[k]![i * 2] = v[i].position.x;
        starPaintPositions[k]![i * 2 + 1] = v[i].position.y;
      }
    });

    for(int i=0; i<grid.length; i++){
      gridPaintPositions[i*4] = grid[i].$1.x;
      gridPaintPositions[i*4+1] = grid[i].$1.y;
      gridPaintPositions[i*4+2] = grid[i].$2.x;
      gridPaintPositions[i*4+3] = grid[i].$2.y;
    }
  }

  startTimer(){
    timer.cancel();
    final size = MediaQuery.of(NBody.appKey.currentContext!).size;
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
      // put the galaxy a bit off the plane to create more "interesting" collisions
      final z = flatten ? 0.0 : random.nextInt(200)-100.0;

      // ensure adequate spacing between galaxies
      if(cores.every((c) => c.distance(x, y, z)>600)){
        // give some variation to initial trajectory
        createGalaxy(x, y, z, -(x+random.nextInt(400))/400, -(y+random.nextInt(400))/400, 0, colors[i]);
        i++;
      }
    }

    createGrid();

    buildPerfCollections();
  }

  createGalaxy(double x, double y, double z, double vx, double vy, double vz, Color color){
    final c = Core(
      position: Vector3(x, y, z),
      velocity: Vector3(vx, vy, vz),
      mass: coreMass,
    );
    cores.add(c);

    // randomly rotate the galaxy
    final q = flatten ? Quaternion.identity() : Quaternion.axisAngle(
      Vector3(random.nextDouble(), random.nextDouble(), random.nextDouble()),
      random.nextDouble()*pi,
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

    grid.clear();

    // TODO: be smarter about sizing
    final width = MediaQuery.sizeOf(NBody.appKey.currentContext!).width-200;
    final height = MediaQuery.sizeOf(NBody.appKey.currentContext!).height;

    int widthDivisions = (width/2)~/100;
    int heightDivisions = (height/2)~/100;

    for(int i=0; i<=widthDivisions; i++){
      grid.add((Vector3(i*100, -heightDivisions*100, 0), Vector3(i*100, heightDivisions*100, 0)));
      if(i>0){
        grid.add((Vector3(-i*100, -heightDivisions*100, 0), Vector3(-i*100, heightDivisions*100, 0)));
      }
    }

    for(int i=0; i<=heightDivisions; i++){
      grid.add((Vector3(-widthDivisions*100, i*100, 0), Vector3(widthDivisions*100, i*100, 0)));
      if(i>0){
        grid.add((Vector3(-widthDivisions*100, -i*100, 0), Vector3(widthDivisions*100, -i*100, 0)));
      }
    }
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
    updateFloatLists();
  }

  // TODO: persist rotation across restarts
  void drag(Offset offset){

    final qx = Quaternion.axisAngle(Vector3(0, 1, 0), offset.dx*pi/400);
    final qy = Quaternion.axisAngle(Vector3(1, 0, 0), offset.dy*pi/400);

    for (Body b in bodies) {
      qx.rotate(b.position);
      qx.rotate(b.velocity);
      qy.rotate(b.position);
      qy.rotate(b.velocity);
    }

    for(Line l in grid){
      qx.rotate(l.$1);
      qx.rotate(l.$2);
      qy.rotate(l.$1);
      qy.rotate(l.$2);
    }

    // if we're running, just let the next tick pick up the changes
    if(!timer.isActive) {
      updateFloatLists();
    }
  }

}