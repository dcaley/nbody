import 'body.dart';

class Core extends Body{
  Core({required super.position, required super.velocity, super.mass=1000, super.color, Body? offset});

  @override
  double get paintSize => 5;

  @override
  bool get showHistory => false;
}