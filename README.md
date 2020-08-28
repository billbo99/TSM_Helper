# TSM_Helper

This mod is in BETA testing.

The purpose of the mod is to help with the creation of "Supply Priorities" within TSM.


Using signals supplied to the "Supply Station" this mod will rename the station and setup a "Supply Priorities" within TSM if not present.

The station rename is triggered by one of two events :-
    - station being RENAMED by the player.
    - station being ROTATED by the player.

When triggered the mod will look for any wires connected to the supply station.
- If a single wire is connected to the station both icons in the "Supply Priority" GUI will be set to the icon.
- If two different coloured wires are used,
    - then the LEFT icon will be set using the GREEN wire
    - and the RIGHT icon will be set using the RED wire  ( R=RIGHT )


There are some special signal under "Virtual Signals" that can be used to control the wait conditions for the "Supply Priority"
    - Wait Until Empty (default Enabled, if <0 this condition is disabled)
    - Wait Until Full (If >0 then override Empty condition, if <0 this condition is disabled)
    - Inactivity Wait (default 5 seconds,  if <0 this condition is disabled)
    - Wait Time (Enabled if >0)
    - AND Condition Operator (Default is OR, if >0 condition is changed to AND)



PS .. this documentation needs updating with more examples in the form of pictures.