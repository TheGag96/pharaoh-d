import BaseAI, Thief, Trap, ThiefType, TrapType, Tile, structures, util;
import std.algorithm, std.array, std.stdio, std.string, std.typecons, std.random, std.container;

///The class implementing gameplay logic.
class AI : BaseAI {
  public:  
    Player me = null;
    Tile[] spawnPoints;
    Thief[] myThieves, enemyThieves;
    Trap[] myTraps, enemyTraps;
    const string[] messages = ["HAPPY FEET", "WOMBO COMBO", "OHH! OHHHHH!", "WHERE YOU AT??"];
    int prevEnemyThiefCount = 0;
    
    alias point = Tuple!(int, "x", int, "y");
  
    override string username() const {
      return "Ain't Falco!";
    }
    override string password() const {
      return "password";
    }

    override void init() {
      //Find the player that I am
      me = players[playerID()];
      spawnPoints = getSpawnPoints();
    }
    
    override bool run() {
      if (roundTurnNumber() <= 1) {
        placeTraps();
        return true;
      }
      else if (roundTurnNumber() <= 3) {
        purchaseThieves();
        return true;
      }
      else {
        //
        //normal turn starts here
        //
        
        //get everything
        myThieves = getMyThieves();
        enemyThieves = getEnemyThieves();
        myTraps = getMyTraps();
        enemyTraps = getMyTraps();
        
        //get hype
        trashTalk();
        
        //be strategic
        useTraps();
        moveThieves();
      }
      
      return true;
    }
    
    alias hallway = Tuple!(int, "x", int, "y", int, "direction");
    hallway[] hallways;
    
    void placeTraps() {
      //place sarcophagus
      alias hallway = Tuple!(int, "x", int, "y", int, "direction");
      hallways = util.getLongestHallways(playerID());
      foreach (h; hallways) {
        me.placeTrap(h.x, h.y, TrapType.SARCOPHAGUS);
        me.placeTrap(h.x+xChange[h.direction], h.y+yChange[h.direction], TrapType.BOULDER);
        me.placeTrap(h.x+2*xChange[h.direction], h.y+2*yChange[h.direction], TrapType.FAKE_ROTATING_WALL);
      }
      
      
      //place other traps
    }
    
    void purchaseThieves() {
      
    }
    
    void useTraps() {
      //use boulders if thieves are too close
      foreach (h; hallways) {
        Thief[] nearSarc = getThievesAt(h.x+2*xChange[h.direction], h.y+2*yChange[h.direction]);
        if (nearSarc.length > 0) {
          Trap boulder = getTrapAt(h.x+xChange[h.direction], h.y+yChange[h.direction]);
          boulder.act(xChange[h.direction], yChange[h.direction]);
        }
      }
    }
    
    void moveThieves() {
      
    }
    
    void trashTalk() {
      if (roundTurnNumber() > 3 && enemyThieves.length - prevEnemyThiefCount < 0) {
        foreach (thief; myThieves) {
          //thief.thiefTalk(messages[uniform(0,messages.length)]);
          writeln(messages[uniform(0,messages.length)]);
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
    
    Tile[] getSpawnPoints() {
      Tile[] tileList = [];
      
      int mapSize = mapHeight();
      tileList ~= getTile(mapSize/2-1 + (1-playerID())*mapSize, 0);
      tileList ~= getTile(mapSize-1 + (1-playerID())*mapSize, mapSize/2-1);
      tileList ~= getTile(mapSize/2+1 + (1-playerID())*mapSize, mapSize-1 );
      tileList ~= getTile((1-playerID())*mapSize, mapSize/2+1);
      
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

    //This function is called once, after your last turn
    void end() {}
    
    this(Connection* c) {
      super(c);
    }
}
