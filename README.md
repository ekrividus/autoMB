# autoMB
Help with magic bursts, well it really will more or less do them for you.  
Will guess what spell type to use based on main/sub jobs, will update at job change.

automb on | off  
automb help - will show help text  
automb status | show - will show information on current settings  
automb (c)ast <spelltype> - one of spell helix ga ra ja light jutsu holy  
automb (t)ier <casttier> - will accept any value, no checking for learned spells or appropriate tiers implemented  
automb mp <amount> - will keep this much mp in reserve, if the spell to cast would drop you below this point it won't cast  
automb (d)elay - how long after a skillchain effect is detected to start casting, if you happen to be casting too fast for the MB to proc  
automb (double)burst | dbl - will attempt to double burst, this will not check to ensure a SC effect is still up, it just casts 2 spells back to back  
automb doubleburstdelay | doubledelay | (dbld)elay - if you want some cushion between the 2 spells in a double burst, set negative will maybe help account for fast cast  
automb stepdown | sd - stepdown spell tier (above 1) toggles modes:  
* Never - just like it sounds  
* Target Change - stepdown if there was a target change, you didn't have the burst target targeted already  
* Always - will stepdown for the second spell in a dbl burst everytime  
automb weather - will adjust spell to account for weather  
automb day - will adjust spell to account for day  
automb (tog)gle [all | elements | weather | spell]][on | off | toggle] - will toggle showing various information per skillchain detected and spell attempt  
automb gearswap | gs - will toggle sending 'gs c bursting' and 'gs c notbursting' commands for gearswap
