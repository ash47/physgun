Physgun for JC2: MP
=========

###How to install###
 - Stick the client and server folders into `Just Cause 2 - Multiplayer Dedicated Server/scripts/physgun`

###What are the controls?###
 - Type /phys to enable the physgun
 - Hold Primary Fire (Left Click by default) to grab things
 - While you have an object grabbed, hold E to rotate the object
 - Scroll the mouse in and out to move what ever you are holding away from / towards yourself

###How do I access the spawn menu?###
 - Hold Q while in physgun mode

###How do I change tools?###
 - While in physgun mode, simply scroll the mouse wheel to change tools (the current tool should be indicated below the map)

###How do I delete stuff###
 - You can undo things (in the order you spawned them) by pressing Z while in physgun mode
 - You can also use the remover to remove things

###Settings###
 - Settings are located in `shared/settings.lua`

###How do I make it admin only?###
 - See `shared/settings.lua`, you can set which actions require permissions, if a permission is set to true, and you have ZED's admin plugin installed, the following permissions can be used
  - `pickup_players`
  - `pickup_vehicles`
  - `pickup_vehicles_occupied`
  - `pickup_static_object`
  - `spawn_object`
  - `remove_something`
