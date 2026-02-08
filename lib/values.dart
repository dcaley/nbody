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
  final paintPositions = <Color, Float32List>{};

  void buildPerfCollections(){

    bodies.clear();
    colorMap.clear();
    paintPositions.clear();

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
    colorMap.forEach((k, v) => paintPositions[k] = Float32List(v.length*2));

    updateFloatLists();
  }

  // for each body, update the appropriate list
  void updateFloatLists() {
    colorMap.forEach((k, v) {
      for (int i = 0; i < v.length; i++) {
        paintPositions[k]![i * 2] = v[i].position.x;
        paintPositions[k]![i * 2 + 1] = v[i].position.y;
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

      // ensure adequate spacing between galaxies
      if(cores.every((c) => c.distance(x, y, 0)>600)){
        // give some variation to initial trajectory
        createGalaxy(x, y, -(x+random.nextInt(400))/400, -(y+random.nextInt(400))/400, colors[i]);
        i++;
      }
    }

    createGrid();

    buildPerfCollections();
  }

  // the calculations are fully 3D, but constrain to x/y for now
  createGalaxy(double x, double y, double vx, double vy, Color color){
    final c = Core(
      position: Vector3(x, y, 0),
      velocity: Vector3(vx, vy, 0),
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

    final width = MediaQuery.sizeOf(NBody.appKey.currentContext!).width;
    final height = MediaQuery.sizeOf(NBody.appKey.currentContext!).width;

    for(double i=-width/2; i<=width/2; i+=100){
      grid.add((Vector3(i, -height/2, 0), Vector3(i, height/2, 0)));
    }

    for(double i=-height/2; i<=height/2; i+=100){
      grid.add((Vector3(-width/2, i, 0), Vector3(width/2, i, 0)));
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

}