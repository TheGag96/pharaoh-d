import BaseAI, Thief, Trap, ThiefType, TrapType, Tile, structures, util;
import std.algorithm, std.array, std.stdio, std.string, std.typecons, std.random, std.container;

///The class implementing gameplay logic.
class AI : BaseAI {
  public:  
    Player me = null;
    point[] mySpawns, enemySpawns;
    Thief[] myThieves, enemyThieves;
    Trap[] myTraps, enemyTraps;
    const string[] messages = ["HAPPY FEET", "WOMBO COMBO", "OHH! OHHHHH!", "WHERE YOU AT??", "GET YO ASS WHOOPED!!"];
    int prevEnemyThiefCount = 0;
    
    alias point = Tuple!(int, "x", int, "y");
  
    override string username() const {
      return "Ain't Falco";
    }
    override string password() const {
      return "password";
    }

    override void init() {
      //Find the player that I am
      me = players[playerID()];
      mySpawns = getMySpawns();
      enemySpawns = getEnemySpawns();
    }
    
    override bool run() {
      if (roundTurnNumber() <= 1) {
        placeTraps();
        return true;
      }
      else if (roundTurnNumber() <= 3) {
        purchaseSlaves();
        purchaseDiggers();
        return true;
      }
      else {
        //
        //normal turn starts here
        //
        
        if (roundTurnNumber() % 4 <= 1)
          purchaseSlaves();
        
        //get everything
        myThieves = getMyThieves();
        enemyThieves = getEnemyThieves();
        myTraps = getMyTraps();
        enemyTraps = getMyTraps();
        
        //get hype
        trashTalk();
        
        //be strategic
        useTraps();
        
        moveSlaves();
        
        if (roundTurnNumber() >= 12)
          moveDiggers();
      }      
      
      return true;
    }
    
    alias hallway = Tuple!(int, "x", int, "y", int, "direction", int, "length");
    hallway[] hallways;
    
    const int[] perpX = [0, 0, 1, 1];
    const int[] perpY = [1, 1, 0, 0];
    
    void placeTraps() {
      //place sarcophagus at ends of longest hallways and guard it by lining up traps in a row
      hallways = util.getLongestHallways(playerID());
      int fakeWallCount = 0;
      foreach (i; 0..hallways.length) {
        hallway h = hallways[i];
        me.placeTrap(h.x, h.y, TrapType.SARCOPHAGUS);
        
        if (i == 0) {
          me.placeTrap(h.x+xChange[h.direction], h.y+yChange[h.direction], TrapType.MERCURY_PIT);
          if (h.length >= 4) {
            me.placeTrap(h.x+2*xChange[h.direction], h.y+2*yChange[h.direction], TrapType.FAKE_ROTATING_WALL);
            me.placeTrap(h.x+3*xChange[h.direction], h.y+3*yChange[h.direction], TrapType.QUICKSAND);
            fakeWallCount++;
          }
          if (h.length >= 6) {
            me.placeTrap(h.x+4*xChange[h.direction], h.y+4*yChange[h.direction], TrapType.FAKE_ROTATING_WALL);
            me.placeTrap(h.x+5*xChange[h.direction], h.y+5*yChange[h.direction], TrapType.QUICKSAND);
            fakeWallCount++;
          }
          if (h.length >= 8) {
            me.placeTrap(h.x+6*xChange[h.direction], h.y+6*yChange[h.direction], TrapType.FAKE_ROTATING_WALL);
            me.placeTrap(h.x+7*xChange[h.direction], h.y+7*yChange[h.direction], TrapType.QUICKSAND);
            fakeWallCount++;
          }
        }
        else {
          me.placeTrap(h.x+xChange[h.direction], h.y+yChange[h.direction], TrapType.BOULDER);
          if (h.length >= 3) {
            me.placeTrap(h.x+2*xChange[h.direction], h.y+2*yChange[h.direction], TrapType.FAKE_ROTATING_WALL);
            fakeWallCount++;
          }
          if (h.length >= 4)
            me.placeTrap(h.x+3*xChange[h.direction], h.y+3*yChange[h.direction], TrapType.QUICKSAND);
          if (h.length >= 5)
            me.placeTrap(h.x+4*xChange[h.direction], h.y+4*yChange[h.direction], TrapType.SPIDER_WEB);
          if (h.length >= 6)
            me.placeTrap(h.x+5*xChange[h.direction], h.y+5*yChange[h.direction], TrapType.SPIDER_WEB);
        }
        
        //buy oil vases in wall next to sarcophagus so that it can't be dug to
        point adjacent1 = point(h.x+perpX[h.direction], h.y+perpY[h.direction]);
        point adjacent2 = point(h.x-perpX[h.direction], h.y-perpY[h.direction]);
        point behind = point(h.x-xChange[h.direction], h.y-yChange[h.direction]);

        point[] possibilities = [adjacent1, adjacent2, behind];
        int[] distances = [];
        
        foreach (a; possibilities) {
          int minDist = 100000;
          foreach(b; enemySpawns) {
            minDist = min(minDist, b.manhattanDistance(a));
          }
          distances ~= minDist;
        }
        
        for (int a = 0; a < possibilities.length; a++) {
          point p = possibilities[a];
          if (p.x < 1+25*playerID() || p.y < 1 || p.x > 23+25*playerID() || p.y > 23) {
            possibilities.remove(a);
            possibilities.length--;
            distances.remove(a);
            distances.length--;
          }
        }
        
        int lowest = 1000;
        ulong lowestIndex = 0;
        foreach (a; 0..possibilities.length) {
          if (distances[a] < lowest) {
            lowest = distances[a];
            lowestIndex = a;
          }
        }
        
        point chosenPoint = possibilities[lowestIndex];
        
        if (getTrapAt(chosenPoint) is null) {
          me.placeTrap(chosenPoint.x, chosenPoint.y, TrapType.OIL_VASES);
        }
        
      }
      
      //place other traps
      //place fake rotating walls randomly in hallways
      point[] hallwayPoints = util.getTwoNeighborTiles(playerID());
      int maxFakeWalls = trapTypes[TrapType.FAKE_ROTATING_WALL].getMaxInstances();
      while (fakeWallCount < maxFakeWalls) {
        int index = cast(int)uniform(0, hallwayPoints.length);
        point p = hallwayPoints[index];
        if (getTrapAt(p) !is null) {
          hallwayPoints.remove(index);
          hallwayPoints.length--;
          continue;
        }
        me.placeTrap(p.x, p.y, TrapType.FAKE_ROTATING_WALL);
        hallwayPoints.remove(index);
        hallwayPoints.length--;
        fakeWallCount++;
      }
      
      //place wire if money left
      int currentMoney = me.getScarabs();
      int wireCost = trapTypes[TrapType.HEAD_WIRE].getCost();
      for (int a = 0; a < enemySpawns.length && currentMoney >= wireCost; a++) {
        me.placeTrap(enemySpawns[a].x+xChange[a], enemySpawns[a].y+yChange[a], TrapType.HEAD_WIRE);
        currentMoney -= wireCost;
      }
      
      //places spikes if scarabs left
      int spikeCost = trapTypes[TrapType.SPIKE_PIT].getCost();
      int spikesNum = 0;
      int maxSpikes = trapTypes[TrapType.SPIKE_PIT].getMaxInstances();
      int[][] grid = buildGrid();
      while (currentMoney >= spikeCost && spikesNum < 5) {
        point p = getRandomEmptyTile(playerID(), grid);
        if (getTrapAt(p.x, p.y) is null) {
          me.placeTrap(p.x, p.y, TrapType.SPIKE_PIT);
          currentMoney -= spikeCost;
          spikesNum++;
        }
      }
    }
    
    alias unit = Tuple!(point, "pos", int, "type", point[], "path", int, "pathStep");
    unit[] units = [];
    unit[] diggerUnits = [];
    unit[] slaveUnits = [];
    
    int slavesSpawned = 0;
    void purchaseSlaves() {
      foreach (i; 0..4) {
        if (me.getScarabs() < thiefTypes[ThiefType.SLAVE].getCost() || slavesSpawned == thiefTypes[ThiefType.SLAVE].getMaxInstances()) {
          return;
        }
        auto sarcSpots = getEnemyTrapsOfType(TrapType.SARCOPHAGUS).map!(x => point(x.getX(), x.getY())).array;
        me.purchaseThief(mySpawns[i].x, mySpawns[i].y, ThiefType.SLAVE);
        slaveUnits ~= unit(mySpawns[i], ThiefType.SLAVE, getPath(mySpawns[i], sarcSpots[uniform(0, sarcSpots.length)]), 0);
        slavesSpawned++;
      }
    }
    
    void purchaseDiggers() {
      int[] spotsLeft = [0, 1, 2, 3];
      int[][] grid = buildGrid();
      
      //make fleets for each sarcophagus
      auto pointsForDiggers = getEnemyTrapsOfType(TrapType.SARCOPHAGUS).map!(sarc => getWallOver(point(sarc.getX(), sarc.getY()), grid, playerID())).array;
      
      foreach (p; pointsForDiggers) {
        point minDistPoint = mySpawns[spotsLeft[0]];
        int minDist = p.manhattanDistance(mySpawns[spotsLeft[0]]);
        int spotChosen = 0;
        foreach (i; 1..spotsLeft.length) {
          if (p.manhattanDistance(mySpawns[spotsLeft[i]]) < minDist) {
            minDistPoint = mySpawns[spotsLeft[i]];
            minDist = p.manhattanDistance(mySpawns[spotsLeft[i]]);
            spotChosen = cast(int)i;
          }
        }
        spotsLeft.remove(spotChosen);
        spotsLeft.length--;
        me.purchaseThief(minDistPoint.x, minDistPoint.y, ThiefType.DIGGER);
        diggerUnits ~= unit(minDistPoint, ThiefType.DIGGER, getPath(minDistPoint, p), 0);
        //writeln("yo she's a gold digga ", p, " ", units[units.length-1].path.length);
      }
      
      //have one guide
      //point[] guidePath = getPath(mySpawns[0], mySpawns[1]) ~ getPath(mySpawns[1], mySpawns[2]) ~ getPath(mySpawns[2], mySpawns[3]) ~ getPath(mySpawns[3], mySpawns[0]);
      //me.purchaseThief(mySpawns[0].x, mySpawns[0].y, ThiefType.GUIDE);
      //units ~= unit(mySpawns[0], ThiefType.GUIDE, guidePath, 0);
    }
    
    void useTraps() {
      //use boulders if thieves are too close
      for (int i = 0; i < hallways.length; i++) {
        hallway h = hallways[i];
        Thief[] nearSarc = getThievesAt(h.x+2*xChange[h.direction], h.y+2*yChange[h.direction]);
        if (nearSarc.length > 0) {
          Trap boulder = getTrapAt(h.x+xChange[h.direction], h.y+yChange[h.direction]);
          if (boulder !is null && boulder.getTrapType() == TrapType.BOULDER && boulder.getActivationsRemaining() > 0) {
            boulder.act(h.x+2*xChange[h.direction], h.y+2*yChange[h.direction]);
          }
          hallways.remove(i);
          hallways.length--;
        }
      }
    }
    
    void moveDiggers() {
      Thief[] diggers = diggerUnits.map!(x => getThief(x)).array;
      for (int i = 0; i < diggerUnits.length; i++) {
        Thief thief = diggers[i];
        if (thief is null || !thief.isAlive()) {
          diggerUnits.remove(i);
          diggers.remove(i);
          diggerUnits.length--;
          diggers.length--;
          i--;
        }
      }
      
      for (int i = 0; i < diggers.length; i++) {
        Thief cur = diggers[i];
        int movementLeft = 4;
        bool removed = false;
        while (movementLeft > 0 && diggerUnits[i].pathStep < diggerUnits[i].path.length) {
          point moveChoice = diggerUnits[i].path[diggerUnits[i].pathStep];
          bool result = cur.move(moveChoice.x, moveChoice.y);
          if (result) {
            if (!cur.isAlive()) {
              diggerUnits.remove(i);
              diggers.remove(i);
              diggerUnits.length--;
              diggers.length--;
              removed = true;
              i--;
              break;
            }
            if (cur.getFrozenTurnsLeft > 0) break;
            if (cur.getX() == moveChoice.x && cur.getY() == moveChoice.y) {
              diggerUnits[i].pathStep++;
              diggerUnits[i].pos = moveChoice;
            }
            movementLeft--;
          }
          else {
            break;
          }
        }
        if (!removed && diggerUnits[i].pathStep == diggerUnits[i].path.length) {
          foreach (a; 0..4) {
            point overWall = point(diggerUnits[i].pos.x + 2*xChange[a], diggerUnits[i].pos.y + 2*yChange[a]);
            Trap sarcMaybe = getTrapAt(overWall);
            if (sarcMaybe !is null && inBounds(overWall) && sarcMaybe.getTrapType() == TrapType.SARCOPHAGUS) {
              if (movementLeft == 4 && cur.getSpecialsLeft() > 0)
                cur.useSpecial(overWall.x-xChange[a], overWall.y-yChange[a]);
              break;
            }
          }
        }
      }
    }
    
    void moveSlaves() {
      Thief[] slaves = slaveUnits.map!(x => getThief(x)).array;
      for (int i = 0; i < slaveUnits.length; i++) {
        Thief thief = slaves[i];
        if (thief is null || !thief.isAlive()) {
          slaveUnits.remove(i);
          slaves.remove(i);
          slaveUnits.length--;
          slaves.length--;
          i--;
        }
      }
      
      for (int i = 0; i < slaveUnits.length; i++) {
        Thief cur = slaves[i];
        if (cur is null) continue;
        int movementLeft = 2;
        bool removed = false;
        while (cur.getMovementLeft() > 0 && slaveUnits[i].pathStep < slaveUnits[i].path.length) {
          point moveChoice = slaveUnits[i].path[slaveUnits[i].pathStep];
          bool result = cur.move(moveChoice.x, moveChoice.y);
          if (result) {
            if (!cur.isAlive()) {
              slaveUnits.remove(i);
              slaves.remove(i);
              slaveUnits.length--;
              slaves.length--;
              removed = true;
              i--;
              break;
            }
            if (cur.getFrozenTurnsLeft() > 0) break;
            if (cur.getX() == moveChoice.x && cur.getY() == moveChoice.y) {
              slaveUnits[i].pathStep++;
              slaveUnits[i].pos = moveChoice;
            }
            movementLeft--;
          }
          else {
            if (cur.getFrozenTurnsLeft() > 0) movementLeft--;
            break;
          }
        }
      }
    }
    
    void trashTalk() {
      if (roundTurnNumber() > 3 && enemyThieves.length - prevEnemyThiefCount < 0) {
        foreach (thief; myThieves) {
          //thief.thiefTalk(messages[uniform(0,messages.length)]);
          writeln("Thief #", thief.getID(), ": \"", messages[uniform(0,messages.length)], "\"");
        }
      }
    }
    
    Thief[] getMyThieves() {
      Thief[] thiefList = [];  
      
      foreach (thief; thieves) {
        if (thief.getOwner() == playerID()) {
          thiefList ~= thief;
        }
      }
      
      return thiefList;
    }
    
    Thief[] getEnemyThieves() {
      Thief[] thiefList = [];  
      
      foreach (thief; thieves) {
        if (thief.getOwner() != playerID()) {
          thiefList ~= thief;
        }
      }
      
      return thiefList;
    }
    
    Trap[] getMyTraps() {
      Trap[] trapList = [];  
      
      foreach (trap; traps) {
        if (trap.getOwner() == playerID()) {
          trapList ~= trap;
        }
      }
      
      return trapList;
    }
    
    Trap[] getEnemyTraps() {
      Trap[] trapList = [];  
      
      foreach (trap; traps) {
        if (trap.getOwner() != playerID()) {
          trapList ~= trap;
        }
      }
      
      return trapList;
    }
    
    point[] getMySpawns() {
      point[] tileList = [];
      
      int mapSize = mapHeight();
      tileList ~= point(mapSize/2-1 + (1-playerID())*mapSize, 0);
      tileList ~= point(mapSize-1 + (1-playerID())*mapSize, mapSize/2-1);
      tileList ~= point(mapSize/2+1 + (1-playerID())*mapSize, mapSize-1 );
      tileList ~= point((1-playerID())*mapSize, mapSize/2+1);
      
      return tileList;  
    }
    
    point[] getEnemySpawns() {
      point[] tileList = [];
      
      int mapSize = mapHeight();
      tileList ~= point(mapSize-1 + (playerID())*mapSize, mapSize/2-1);
      tileList ~= point((playerID())*mapSize, mapSize/2+1);
      tileList ~= point(mapSize/2+1 + (playerID())*mapSize, mapSize-1 );
      tileList ~= point(mapSize/2-1 + (playerID())*mapSize, 0);
      
      return tileList;  
    }
    
    Tile getTile(int x, int y) {
      if (x < 0 || x >= mapWidth() || y < 0 || y >= mapHeight()) {
        return null;
      }
      return tiles[y + x*mapHeight()];
    }
    
    Trap getTrap(int x, int y) {
      if (x < 0 || x >= mapWidth() || y < 0 || y >= mapHeight()) {
        return null;
      }
      
      foreach (trap; traps) {
        if (trap.getX() == x && trap.getY() == y) {
          return trap;
        }
      }
      
      return null;
    }
    
    Thief getThief(int x, int y) {
      if (x < 0 || x >= mapWidth() || y < 0 || y >= mapHeight()) {
        return null;
      }
      
      foreach (thief; thieves) {
        if (thief.getX() == x && thief.getY() == y) {
          return thief;
        }
      }
      
      return null;
    }
    
    bool onMySide(int x) {
      if (playerID() == 0) {
        return (x < mapWidth()/2);
      }
      else {
        return (x >= mapWidth()/2);
      }
    }
    
    point enemySide(point p) {
      int x2 = p.x % mapHeight(), y2 = p.y % mapHeight();
      return point(x2 + playerID()*mapHeight(), y2 + playerID()*mapHeight());
    }
    
    point mySide(point p) {
      int x2 = p.x % mapHeight(), y2 = p.y % mapHeight();
      return point(x2 + (1-playerID())*mapHeight(), y2 + (1-playerID())*mapHeight());
    }
    
    bool purchaseThief(Player player, point p, int thiefType) {
      return player.purchaseThief(p.x, p.y, thiefType);
    }
    
    bool placeTrap(Player player, point p, int thiefType) {
      return player.placeTrap(p.x, p.y, thiefType);
    }
    
    Trap getTrapAt(int x, int y) {
      foreach (trap; traps) {
        if (trap.getX() == x && trap.getY() == y) {
          return trap;
        }
      }
      return null;
    }
    
    Thief[] getThievesAt(point p) {
      return getThievesAt(p.x, p.y);
    }
    
    Thief[] getThievesAt(int x, int y) {
      Thief[] result = [];
      foreach (thief; thieves) {
        if (thief.getX() == x && thief.getY() == y) {
          result ~= thief;
        }
      }
      return result;
    }
    
    Trap getTrapAt(point p) {
      return getTrapAt(p.x, p.y);
    }
    
    Trap[] getAllTrapsOfType(int trapType) {
      Trap[] result = [];
      foreach (x; traps) {
        if (x.getOwner() == playerID() && x.getTrapType() == trapType) {
          result ~= x;
        }
      }
      return result;
    }
    
    Trap[] getEnemyTrapsOfType(int trapType) {
      Trap[] result = [];
      foreach (x; traps) {
        if (x.getOwner() == 1-playerID() && x.getTrapType() == trapType) {
          result ~= x;
        }
      }
      return result;
    }
    
    Thief[] getAllThievesOfType(int thiefType) {
      Thief[] result = [];
      foreach (x; thieves) {
        if (x.getOwner() == playerID() && x.getThiefType() == thiefType) {
          result ~= x;
        }
      }
      return result;
    }
    
    Thief[] getAllThievesOfTypeAt(int x, int y, int thiefType) {
      Thief[] result = [];
      foreach (thief; thieves) {
        if (thief.getOwner() == playerID() && thief.getX() == x && thief.getY() == y && thief.getThiefType() == thiefType) {
          result ~= thief;
        }
      }
      return result;
    }
    
    Thief getThief(unit u) {
      foreach (thief; thieves) {
        if (thief.getOwner() == playerID() && thief.getX() == u.pos.x && thief.getY() == u.pos.y && thief.getThiefType() == u.type) {
          return thief;
        }
      }
      return null;
    }

    //This function is called once, after your last turn
    void end() {}
    
    this(Connection* c) {
      super(c);
    }
}
