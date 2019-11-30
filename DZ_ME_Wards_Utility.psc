scriptName DZ_ME_Wards_Utility extends Actor 

bool function bSpellContainsKeyword (spell spSpell, keyword kwKeyword) global
	if spSpell.HasKeyword(kwKeyword)
		return true
	else
		return false
	endif
endfunction


int function iSpellTypeEquippedInWhichHand (actor akActor, string kwString) global
    keyword kwKeyword = keyword.getKeyword(kwString)
    spell currentLeftSpell = akActor.GetEquippedSpell(0)
	spell currentRightSpell = akActor.GetEquippedSpell(1)
	bool leftSpellContainsKeyword = bSpellContainsKeyword(currentLeftSpell, kwKeyword)
	bool rightSpellContainsKeyword = bSpellContainsKeyword(currentRightSpell, kwKeyword)
	if leftSpellContainsKeyword && !rightSpellContainsKeyword ; left
		return 0 ; 
	elseif !leftSpellContainsKeyword && rightSpellContainsKeyword ; right
		return 1
	elseif leftSpellContainsKeyword && rightSpellContainsKeyword ; left and right
		return 2
	else 
		return -1 ; neither hand
	endif
endFunction

float function fGetSpellFirstMagicEffectMagnitude (spell spSpell) global ; gets spell magnitude from first in the spell list
	return spSpell.GetNthEffectMagnitude(0)	
endfunction


int function fGetSpellMagicEffectMagnitude (spell spSpell, int intPosStart, int intPosEnd) global ; gets average magic effect magnitude from spell 
	; can choose positions or leave at 0 for all
	int start = intPosStart
    int end = intPosEnd
    if end == 0
    	end = spSpell.GetNumEffects() 
    endif
	if end != 0
	float MagicEffectMagnitude = 0
	while start < end
		MagicEffectMagnitude += spSpell.GetNthEffectMagnitude(0)
		start += 1
			endwhile
			return (MagicEffectMagnitude / end) as int
		else
			return 0
		endif
endfunction


float function fGetActorWardPercentage (actor akActor, spell spSpell) global
	return akActor.GetAV("WardPower") / spSpell.GetNthEffectMagnitude(0)
endfunction


float function intGetMagicEffectList (spell akSpell) ; unused rn

	int n = akspell.GetNumEffects()
	if n != 0 
		int i = 0
		Form[] MagicEffectArray 
		MagicEffectArray = new Form[5]
			while i != n
			MagicEffectArray[0] = akspell.GetNthEffectMagicEffect(i)
				i += 1
			endwhile
					return  akSpell.GetNthEffectMagnitude(0)
		endif
	endFunction


float function fEstimateDisplayedDamage (actor akActor, weapon akWeapon, bool abPowerAttack, bool isPlayer) global ; estimates damage accurately based on game formulas
;Round[( basedamage + smithingincrease)*(1 + skill/200)*(1 + perkeffects)*(1 + itemeffects)*(1 + potion effect)*(1 + SeekerofMightbonus)]
    ; powerattack requires OnHit
    bool powerAttack = abPowerAttack

    ; currently equipped weapon
    ; must be attacking to calculate lefthand weapon temper because reasons
    ; OnHit can get current equipped weapon too
    weapon currentweapon
    int currentweaponhand
    weapon lefthandweapon = akActor.GetEquippedWeapon(true)
    weapon righthandweapon = akActor.GetEquippedWeapon(false)
    if isPlayer 
    	; do stuff
    elseif lefthandweapon == akWeapon ; if the weapon is equipped in left hand
    	if righthandweapon == akWeapon ; if weapon is also equipped in right hand
    		if akActor.GetAnimationVariableBool("bLeftHandAttack") ; is left hand attacking
    			currentweaponhand = 2 ; assume dual weild attack
    		else 
    			currentweaponhand = 1 ; assume only right hand attacking
    		endif
    	else
    		currentweaponhand = 0 ; only left hand can attack
    	endif
    else 
    	currentweaponhand = 1 ; only right hand can attack
    endif 

    Debug.Notification("current weapon hand is " + currentweaponhand)
    ; grab base weapon damage value
	float baseweapondamage = currentweapon.GetBaseDamage()
	; calculate tempered weapon damage
    float currentweapontemper = WornObject.GetItemHealthPercent(akActor, currentweaponhand, 0) ; todo which hand 
    int qualitylevel = ((currentweapontemper - 1) * 10) as int
    int Fine = 1 ;1
    int Superior = 3 ;2
    int Exquisite = 5 ;3
    int Flawless = 7 ;4
    int Epic = 8 ;5
    int Legendary = 10 ;6
    float beyondMult = 1.8 ; when beyond Legendary 
    float tempereddamage
    if (qualitylevel > 0)
    	if qualitylevel == 1
    		tempereddamage = Fine
    	elseif qualitylevel == 2
    		tempereddamage = Superior
    	elseif qualitylevel == 3
    		tempereddamage = Exquisite
    	elseif qualitylevel == 4
        	tempereddamage = Flawless
        elseif qualitylevel == 5
        	tempereddamage = Epic
        elseif qualitylevel == 6
        	tempereddamage = Legendary
        elseif qualitylevel > 6
        	tempereddamage = Legendary + (qualityLevel - 6) * beyondMult
        endif
    else 
    	tempereddamage = 0
    endif
    ; calculation skill multiplier
    int weaponType = currentweapon.GetWeaponType()
    float skillLevel
    if weaponType != 0
		if weaponType <= 4 ;One handed weapons
			skillLevel = akActor.GetAV("OneHanded") + akActor.GetAV("OneHandedMod") + akActor.GetAV("OneHandedPowerMod")
		elseIf weaponType == 5 || weaponType == 6 ;Two handed weapons
			skillLevel = akActor.GetAV("TwoHanded") + akActor.GetAV("TwoHandedMod") + akActor.GetAV("TwoHandedPowerMod")
		elseIf weaponType == 7 || weaponType == 9 ;Ranged weapons
			skillLevel = akActor.GetAV("Marksman") + akActor.GetAV("MarksmanMod") + akActor.GetAV("MarksmanPowerMod")
		endif
	endif
    float minimumSkillMultiplier
	float maximumSkillMultiplier
	float skillMultiplier 
    if akActor == Game.GetPlayer()
		minimumSkillMultiplier = Game.GetGameSettingFloat("fDamagePCSkillMin")
		maximumSkillMultiplier = Game.GetGameSettingFloat("fDamagePCSkillMax")
	else
		minimumSkillMultiplier = Game.GetGameSettingFloat("fDamageSkillMin")
		maximumSkillMultiplier = Game.GetGameSettingFloat("fDamageSkillMax")
	endif
    skillMultiplier = minimumSkillMultiplier + ((maximumSkillMultiplier - minimumSkillMultiplier) * skillLevel / 100)
    ; calculate true damage
    float trueDamage 
    if weaponType != 0
    	trueDamage = ((baseweapondamage + tempereddamage) * skillmultiplier)
        if powerAttack
        	trueDamage = truedamage * (1 + Game.GetGameSettingFloat("fPowerAttackDefaultBonus"))
        endif 
        ; perk stuff goes here
    else ; unarmed and creatures
    	truedamage = (akActor.GetAV("UnarmedDamage") + akActor.GetAV("UnarmedDamageMod") + akActor.GetAV("UnarmedDamagePowerMod")) * (1 + Game.GetGameSettingFloat("fCombatUnarmedCritDamageMult"))
    endif
 
    Debug.Notification("TRUE" + truedamage + "BASE" + baseweapondamage + "SKILL" + skillmultiplier + "TEMP" + tempereddamage)

endfunction