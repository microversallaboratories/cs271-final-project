# cs271-final-project
View this in RAW MODE

Author: Hojun Shin, Jacob North

Structure of Game:
 - Setup
 - Game Loop
   - Draw Background
   - Draw Character
   - Draw inventory on screen
   - Key input
   - Check for item on ground, add to inventory
   - Check if by a door, and unlock if player has key
   - If walking through door, transport to next map area
   - Loop back to Game Loop
      
Future Updates:
- By 3/5/20:
  - Add 2D array from map file
  - Use map array to limit player's movement (ex. '@' cannot move into wall '#')
  - Use boundaries to limit player's movement to out of map (Minimum_x = 0, Minimum_y = 0)
-  By 3/7/20:
  - Add Items to 2D array
  - Add Item interaction
  - (Maybe) Add Inventory UI
-  By 3/9/20:
  - Wrap-up Stage clear
  - Add multiple Map
  - Add Game clear pop-up
     

  
