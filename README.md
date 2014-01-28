Physgun for JC2: MP
=========

###How to install###
 - Stick the client and server folders into `Just Cause 2 - Multiplayer Dedicated Server/scripts/physgun`

###What are the controls?###
 - Type /phys to enable the physgun
 - Hold Primary Fire (Left Click by default) to grab things
 - While you have an object grabbed, hold E to rotate the object, hold Shift to snap to the nearest 45 degrees
 - Scroll the mouse in and out to move what ever you are holding away from / towards yourself

###How do I access the spawn menu?###
 - Hold Q while in physgun mode

###How do I change tools?###
 - While in physgun mode, hold Q to bring up the tools menu, from here, select the tool you'd like to use

###How do I delete stuff###
 - You can undo things (in the order you spawned them) by pressing Z while in physgun mode
 - You can also use the remover to remove things

###What tools are there?###
 - Remover - This allows you to remove static objects and vehicles
 - Stacker - Right click two objects to calculate an offset, then click another to stack it
 - Duplicator - Right click an object to copy, left click to paste

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
