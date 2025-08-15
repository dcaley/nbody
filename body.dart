import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nbody/vector.dart';

import 'core.dart';

abstract class Body{
  
  Vector position;
  Queue<Vector> history = Queue();
  int historyLength = 5;
  Vector velocity;
  double mass;
  Color color;
  
  Body({required this.position, required this.velocity, this.mass=1, this.color=Colors.white, Body? offset}){
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
    position.x += velocity.x;
    position.y += velocity.y;
    position.z += velocity.z;
  }

  bool influencedBy(Body b) => b is Core;

  //double distance(Body b) => sqrt(pow(position.x-b.position.x, 2)+pow(position.y-b.position.y, 2)+pow(position.z-b.position.z, 2));

  double distance(double x, double y, double z) => sqrt(pow(position.x-x, 2)+pow(position.y-y, 2)+pow(position.z-z, 2));

  double get paintSize;

  bool get paintHistory => true;
}