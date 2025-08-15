class Vector{

  double x;
  double y;
  double z;

  Vector({this.x=0, this.y=0, this.z=0});

  Vector.from(Vector from) : x = from.x, y = from.y, z = from.z;
}