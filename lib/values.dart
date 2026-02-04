import 'dart:typed_data';
import 'dart:ui';

import 'package:nbody/star.dart';
import 'package:vector_math/vector_math.dart';

import 'body.dart';
import 'core.dart';

typedef Line = (Vector3 a, Vector3 b);

// encapsulate values that we wish to share between the calculations and painter
class Values{
  bool flatten = false;
  bool follow = false;
  final List<Line> grid = [];
  final List<Star> stars = [];
  final List<Core> cores = [];

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
}