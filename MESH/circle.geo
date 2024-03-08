// Gmsh project created on Tue Jan 09 17:21:46 2024

Point(1) = {0,0,0,1};
Point(2) = {25,0,0,1};
Point(3) = {-25,0,0,1};
Circle(4) = {2,1,3};
Circle(5) = {3,1,2};
Curve Loop(6) = {4,5};
Plane Surface(1) = {6};
// end