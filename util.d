import std.stdio, std.array, std.container, std.algorithm, std.typecons, core.exception, std.math, std.conv, std.random;
import BaseAI, Tile;

alias point = Tuple!(int, "x", int, "y");
const int mapWidth = 50;
const int mapHeight = 25;

////
//A* Stuff
////

const static int[] xChange = [-1,  1,  0,  0];
const static int[] yChange = [ 0,  0, -1,  1];
  
point[] getPath(point start, point end) {
  //get game grid
  int[][] grid = buildGrid();
  
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
      if (adjacent.inBounds() && !adjacent.isWall(grid) && bfsgrid[adjacent.x][adjacent.y] == -1) {
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
      grid[x][y] = BaseAI.BaseAI.tiles[y + x*25].getType();
    }
  }
  return grid;
}

bool inBounds(point p) {
  return (p.x >= 0 && p.x < mapWidth && p.y >= 0 && p.y < mapHeight);
}

bool isWall(point p, ref int[][] grid) {
  return (grid[p.x][p.y] == Tile.WALL);
}

bool isEmpty(point p, ref int[][] grid) {
  return (grid[p.x][p.y] == Tile.EMPTY);
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

alias hallway = Tuple!(int, "x", int, "y", int, "direction", int, "length");

hallway[] getLongestHallways(int playerID) {
  hallway[] hallways = [];
  int[][] grid = buildGrid();
  
  int minX = playerID*25;
  
  //get all dead ends (those are hallways)
  foreach (x; minX+1..minX+24) {
    foreach (y; 1..24) {
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
        hallways ~= hallway(x, y, direction, 0);
      }
    }
  }

  hallways.getLengths(grid);
  hallways.sort!((a,b) => a.length > b.length);
  
  return hallways[0..3];
}

void getLengths(ref hallway[] hallways, ref int[][] grid) {
  foreach (ref hallway h; hallways) {
    int length = 0;
    int x = h.x, y = h.y;
    const int[] perpX = [0, 0, 1, 1];
    const int[] perpY = [1, 1, 0, 0];
    bool endFound = false;
    while (!endFound) {
      length++;
      point adjacent1 = point(x+perpX[h.direction], y+perpY[h.direction]);
      point adjacent2 = point(x-perpX[h.direction], y-perpY[h.direction]);
      
      if (inBounds(adjacent1) && !isWall(adjacent1, grid)) {
        endFound = true;
        break;
      }
      if (inBounds(adjacent2) && !isWall(adjacent2, grid)) {
        endFound = true;
        break;
      }
      
      x += xChange[h.direction];
      y += yChange[h.direction];
      if (!inBounds(point(x, y))) break;
    }
    h.length = length;
  }
}

////
//Two-Wall Neighbor Detection
////

point[] getTwoNeighborTiles(int playerID) {
  point[] result = [];
  int[][] grid = buildGrid();
  
  int minX = playerID*mapHeight;
  
  foreach (x; minX+1..minX+24) {
    foreach (y; 1..mapHeight-1) {
      point candidate = point(x,y);
      if (grid[candidate.x][candidate.y] == Tile.EMPTY && getNeighborWallCount(candidate, grid) == 2) {
        result ~= candidate;
      }
    }
  }
  
  return result;
}

int getNeighborWallCount(point p, ref int[][] grid) {
  int neighbors = 0;
  foreach (a; 0..4) {
    point n = point(p.x+xChange[a], p.y+yChange[a]);
    if (inBounds(n) && grid[n.x][n.y] == Tile.WALL) {
      neighbors++;
    }
  }
  return neighbors;
}

point getRandomEmptyTile(int playerID, ref int[][] grid) {
  int randomX = uniform(1, 24) + playerID*25;
  int randomY = uniform(1, 24);
  
  while (grid[randomX][randomY] != 0) {
    randomX = uniform(1, 24) + playerID*25;
    randomY = uniform(1, 24);
  }
  
  return point(randomX, randomY);
}

////
//Other Side of Sarcophagus
////
point getWallOver(point p, ref int[][] grid, int playerID) {
  foreach (a; 0..4) {
    point wallOver = point(p.x+2*xChange[a], p.y+2*yChange[a]);
    if (wallOver.x >= 1+25*(1-playerID) && wallOver.x <= 23+25*(1-playerID) && wallOver.y >= 1 && wallOver.y <= 23) {
      if (isEmpty(wallOver, grid) && isWall(point(p.x+xChange[a], p.y+yChange[a]), grid)) { 
        return wallOver;
      }
    }
  }
  return point(-1,-1);
}
