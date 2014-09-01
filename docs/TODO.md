# TODO

Figure out structure for representing tables and persons occupying them.

## Round table

  { 
    radius: 10,
    location: [100,200],
    seats: [p1,p2,p3]
  }

## Rect table

  {
    dimensions: [3,1],
    location: [100,200],
    size: [3,4]
    seats: [[p1,p2,p3],[p4],[p5,p6,p7],[p8]]
  }

Representing:

     p1 p2 p3
     --------
  p8 |      | p4
     --------
     p7 p6 p5

opposite: i,j -> [i+2][length2-j-1]
left: i,j-1 if < 0 then i-1,length-1 if i-1 < then length-1,length-1
