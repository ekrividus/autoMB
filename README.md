# autoMB
A windower 4 addon that helps with magic bursts. Well it really will more or less do them for you.  
Will guess what spell type to use based on main/sub jobs, will update at job change. It is suggested that you double check this as you really may prefer something different than what it guesses.  
  
Filters spells available based on the SC, then chooses from them based on order: Thunder > Ice > Wind > Fire > Water > Earth > Dark > Light  
It can, optionally, account for weather and/or day effects, by default this is off.  
If day or weather is on it will choose the spell benefited by the day/weather if available in the SC properties.  
  
Will, optionally, change targets to the one the SC effect was most recently applied to. This can go horribly awry if you have multiple mobs being SC'd at once. It will not always work well in alliance settings, especially noticable in instanced content like Dynamis Divergance where lag seems to really impact things. By default this is off.

---
## Commands:
automb or amb - With no arguments will display help text
### Arguments: 
* on | off  - Starts or stops the addon
* help - will show help text  
* status | show - will show information on current settings  
* (c)ast <spelltype> - one of spell helix ga ra ja light jutsu holy  
* (t)ier <casttier> - will accept any value, no checking for learned spells or appropriate tiers implemented  
* range | rng <casttier> - the max cast range you want, if not set to a number will set it to default of 22'  
* mp <amount> - will keep this much mp in reserve, if the spell to cast would drop you below this point it won't cast  
* (d)elay - how long after a skillchain effect is detected to start casting, if you happen to be casting too fast for the MB to proc  
* (double)burst | dbl - will attempt to double burst, this will not check to ensure a SC effect is still up, it just casts 2 spells back to back  
* doubleburstdelay | doubledelay | (dbld)elay - if you want some cushion between the 2 spells in a double burst, set negative will maybe help account for fast cast  
* stepdown | sd - stepdown spell tier for second spell of double burst (above 1) cycle modes:  
* * Never - just like it sounds  
* * Target Change - stepdown if there was a target change, you didn't have the burst target targeted already  
* * Always - will stepdown if the first choice spell is on CD, so if you have T5 set and Thunder 5 should fire but is on CD it'll stepdown to Thunder 4
* weather - will adjust spell to account for weather, super handy if you have a Sch around  
* day - will adjust spell to account for day  
* (tog)gle [all | elements | weather | spell]][on | off | toggle] - will toggle showing various information per skillchain detected and spell attempt  
* gearswap | gs - will toggle sending 'gs c bursting' and 'gs c notbursting' commands for gearswap  
* target | tgt - toggle auto target swapping for MBs

---
## TODO: 
* Dial in target changes, currently checked by claim IDs, BT, T but maybe should be done differently.
* Blue magic handling, not that I know any blues that really bother with MBs anymore.
* Avatar BPs, if there is a real outcry to support them.
* Beast Pets, again if there is an outcry, I don't see it happening though.