Physgun for JC2: MP
=========

###How to install###
 - Stick the client and server folders into `Just Cause 2 - Multiplayer Dedicated Server/scripts/physgun`

###What are the controls?###
 - Type /phys to enable the physgun
 - Hold Primary Fire (Left Click by default) to grab things
 - While you have an object grabbed, hold E to rotate the object
 - Scroll the mouse in and out to move what ever you are holding away from / towards yourself

# How do I access the spawn menu?
 - Hold Q while in physgun mode

###How do I make it admin only?###
 - There are four permission settings in `server/physgun_init.lua`, these control who is allowed to pickup certain things
  - `pickupVehiclesRequiresPermission`
  - `pickupStaticRequiresPermission`
  - `pickupPlayersRequiresPermission`
  - `spawningRequiresPermission`
 - Each of these determines if a white list should be used to allow players to do the respective things, the white list is defaulted to OFF for all except players
 - If you enable the white list, you should add your steamID to the list `whiteList`
 - If you have ZED Permissions installed, after enabling the white lists, simple add the permisions `pickup_players`, `pickup_vehicles`, `pickup_static_object` and `spawn_object`
 - The `trustClients` is some what useless, if you're gonna let people move stuff with a physgun, you might as well trust them, the reason this option exists is incase you get someone who modifies the script some how, and uses it to teleport vehicles around
 - In `client/physgun_init.lua` there are two options `nUpdateTime` which defines how long (in seconds) before an update with your new angles will be sent to the server
 - `nRotationFactor` which controls how fast objects rotate, the higher the number, the faster they rotate, player's can change this with `/rotspeed`, note: this command is inversed, and hence, a higher number will cause slower rotation