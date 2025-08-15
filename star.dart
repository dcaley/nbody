import 'body.dart';

class Star extends Body{
  Star({required super.position, required super.velocity, super.mass=1, super.color, super.offset});

  @override
  double get paintSize => 2;
}