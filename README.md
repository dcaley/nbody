# nbody

This was an attempt to see if I still remembered how to write a simple n-body simulation, which I had not done since college.

On the whole, this was successful.  The math was definitely a bit rusty, but still in there.

This is not a serious simulation.  It is a simple Newtonian implementation, more optimized for looking good than being useful.  You won't find a tree or a mesh or even a constant for G.  I fiddled with values until things looked good.

The math is fully 3D, but everything is currently constrained to the X/Y plane, simply because Z doesn't really add anything to what I was trying to accomplish.  Maybe I will be motivated to change this at some point.

Yes, I'm aware of the [vector_math](https://pub.dev/packages/vector_math) package, but I my goal was to see if I could do without that sort of thing.  I might use it if I ever want to do anything more complicated.