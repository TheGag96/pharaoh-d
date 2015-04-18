import BaseAI, Thief, Trap, ThiefType, TrapType, Tile, structures, astar;
import std.algorithm, std.array, std.stdio, std.typecons, std.random, std.container;

///The class implementing gameplay logic.
class AI : BaseAI {
  public:  
    Player me = null;
    Tile[] spawnPoints;
    Thief[] myThieves, enemyThieves;
    Trap[] myTraps, enemyTraps;
    const string messages = ["HAPPY FEET", "WOMBO COMBO", "OHH! OHHHHH!", "WHERE YOU AT??"];
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
      spawPoints = getSpawnPoints();
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
        
        
      }
      
      return true;
    }
    
    void placeTraps() {
      //place sarcophagus
      alias hallway = Tuple!(int, "x", int, "y", int, "direction");
      
      //place other traps
    }
    
    void purchaseThieves() {
      
    }
    
    void trashTalk() {
      if (roundTurnNumber() > 3 && enemyThieves.length - prevEnemyThiefCount < 0) {
        foreach (thief; myThieves) {
          thief.thiefTalk(messages[uniform(0,messages.length)]);
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
      
      foreach (trap; traps) {f
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
      me.purchaseThief(p.x, p.y, thiefType);
    }
    
    bool placeTrap(Player me, point p, int thiefType) {
      me.placeTrap(p.x, p.y, thiefType);
    }

    //This function is called once, after your last turn
    void end() {}
    
    this(Connection* c) {
      super(c);
    }
}
