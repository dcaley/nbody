import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

import 'vector.dart';

abstract class Body{
  
  final Vector position;
  final Queue<Vector> history = Queue();
  final int historyLength = 5;
  final Vector velocity;
  final double mass;
  final Color color;
  
  Body({required this.position, required this.velocity, this.mass=0, this.color=Colors.white, Body? offset}){
    if(offset!=null){
      position.x += offset.position.x;
      position.y += offset.position.y;
      position.z += offset.position.z;
      velocity.x += offset.velocity.x;
      velocity.y += offset.velocity.y;
      velocity.z += offset.velocity.z;
    }
  }

  void tick(){
    history.add(Vector.from(position));
    if(history.length>historyLength){
      history.removeFirst();
    }

    // add velocity vector to position vector
    position.x += velocity.x;
    position.y += velocity.y;
    position.z += velocity.z;
  }

  // bodies with no mass have no effect
  bool influencedBy(Body b) => b.mass > 0;

  //double distance(Body b) => sqrt(pow(position.x-b.position.x, 2)+pow(position.y-b.position.y, 2)+pow(position.z-b.position.z, 2));

  double distance(double x, double y, double z) => sqrt(pow(position.x-x, 2)+pow(position.y-y, 2)+pow(position.z-z, 2));

  double get paintSize;

  bool get paintHistory => true;
}