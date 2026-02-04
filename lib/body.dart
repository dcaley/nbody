import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

abstract class Body{
  
  final Vector3 position;
  final int historyLength = 5;
  final Vector3 velocity;
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
    // add velocity vector to position vector
    position.x += velocity.x;
    position.y += velocity.y;
    position.z += velocity.z;
  }

  double distance(double x, double y, double z) => sqrt(pow(position.x-x, 2)+pow(position.y-y, 2)+pow(position.z-z, 2));

  double get paintSize;
}