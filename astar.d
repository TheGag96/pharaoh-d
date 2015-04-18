import std.stdio, std.array, std.container, std.algorithm, std.typecons, core.exception, std.math, std.conv;
import BaseAI, Tile;

alias point = Tuple!(int, "x", int, "y");

////
//A* Stuff
////

const static int[] xChange = [-1,  1,  0,  0];
const static int[] yChange = [ 0,  0, -1,  1];
  
point[] getPath(point start, point end) {
  //set up discovery/path-back grid 
  int[][] bfsgrid = new int[][](mapWidth, mapHeight);
  foreach (x; 0..bfsgrid.length) {
    bfsgrid[x][] = -1;
  }
  
  
  //do A* search
  //the first points processed will be the ones with the smallest sum of
  //differences between the start point and end point
  auto queue = Array!point([start]).heapify!((a,b) => pointCompare(a,b,start,end));
  
  point v = start;
  
  //related to x and y change arrays; tile discovered by direction i will be traveled back in the direction wayBack[i]
  const int[] wayBack = [ 1,  0,  3,  2];
  
  bool found = false;
  while (!queue.empty() && !found) {
    v = queue.front;
    queue.removeFront();
    foreach (a; 0..4) {
      point adjacent = point(v.x + xChange[a], v.y + yChange[a]);
      if (adjacent.inBounds() && !adjacent.isWall() && bfsgrid[adjacent.x][adjacent.y] == -1) {
        //queue adjacent empty undiscovered tiles for search
        queue.insert(adjacent);
        
        //store path to previous tile (and thus back to start)
        bfsgrid[adjacent.x][adjacent.y] = wayBack[a];
        
        //break if we actually found the end
        if (adjacent == end) {
          found = true;
          break;
        }
      }
    }
  }
  
  //if we never found the end the search failed
  if (!found) {
    return [];
  }
  
  //follow path back to the start from the end tile and return it as a whole
  //the first element is the first step
  point goinHome = end;
  auto stack = make!(SList!point);
  point[] path = [];
  while (goinHome != start) {
    path ~= goinHome;
    int wayToGo = bfsgrid[goinHome.x][goinHome.y];
    goinHome = point(goinHome.x + xChange[wayToGo], goinHome.y + yChange[wayToGo]);
  }
  return path.reverse; 
}

int[][] buildGrid() {
  int[][] grid = new int[][](50, 25);
  foreach (x; 0..50) {
    foreach (y; 0..25) {
      grid[x][y] = BaseAI.BaseAI.tiles[y + x*25)].getType();
    }
  }
  return grid;
}

bool inBounds(point p) {
  return (p.x >= 0 && p.x < mapWidth && p.y >= 0 && p.y < mapHeight);
}

bool isWall(point p) {
  return (grid[p.x][p.y] == Tile.WALL);
}

int manhattanDistance(point a, point b) {
  return abs(b.x-a.x) + abs(b.y-a.y);
}

int pointCompare(point a, point b, point start, point end) {
  return  (a.manhattanDistance(start)+a.manhattanDistance(end) >
           b.manhattanDistance(start)+b.manhattanDistance(end));
}

////
//Hallway Detection
////

alias hallway = Tuple!(int, "x", int, "y", int, "direction");

point[] getLongestHallways(int playerID) {
  hallway[] hallways = [];
  int[][] grid = buildGrid();
  
  int minX = playerID*25;
  
  //get all dead ends (those are hallways)
  foreach (x; minX..minX+50) {
    foreach (y; 0..25) {
      int neighbors = 0;
      int direction = -1;
      foreach (a; 0..4) {
        if (grid[x+xChange[a]][y+yChange[a]] == Tile.WALL) {
          neighbors++;
        }
        else {
          direction = a;
        }
      }
      if (neighbors == 3) {
        hallways ~= hallway(x, y, direction);
      }
    }
  }

  hallways.sort!((a,b) => a.getLength(grid) > b.getLength(grid));
  
  return hallways[0..4];
}

int getLength(hallway h, ref int[][] grid) {
  int length = 0;
  int x = h.x, y = h.y;
  while (inBounds(point(x, y)) && grid[x][y] != Tile.WALL) {
    length++;
    x += xChange[h.direction];
    x += yChange[h.direction];
  }
  return length;
}
