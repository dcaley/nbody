import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

abstract class Body{
  
  final Vector3 position;
  final Vector3 velocity;
  final double mass;
  final Color color;
  
  Body({required this.position, required this.velocity, this.mass=0, this.color=Colors.white, Body? offset}){
    if(offset!=null){
      position.add(offset.position);
      velocity.add(offset.velocity);
    }
  }

  void tick(){
    position.add(velocity);
  }

  double get paintSize;
}