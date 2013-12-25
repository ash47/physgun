Physgun for JC2: MP
=========

###How to install###
 - Stick the client and server folders into `Just Cause 2 - Multiplayer Dedicated Server/scripts/physgun`

###What are the controls?###
 - Hold G to grab things
 - While holding G, hold E to rotate what ever you are holding
 - Scroll the mouse in and out to move what ever you are holding away from / towards yourself

###How do I make it admin only?###
 - There are two functions `AllowedToPickupVehicle` and `AllowedToPickupPlayer` in `server/physgun_init.lua`, these control who is allowed to pickup certain things
 - By default, anyone can pickup vehicles, and only white listed people can pickup other players, it's pretty straight forward to change these hooks to your likings
 - The `trustClients` is some what useless, if you're gonna let people move stuff with a physgun, you might as well trust them, the reason this option exists is incase you get someone who modifies the script some how, and uses it to teleport vehicles around
 - In `client/physgun_init.lua` there are two options `nUpdateTime` which defines how long (in seconds) before an update with your new angles will be sent to the server
 - `nRotationFactor` which controls how fast objects rotate, the higher the number, the faster they rotate, player's can change this with `/rotspeed`, note: this command is inversed, and hence, a higher number will cause slower rotation