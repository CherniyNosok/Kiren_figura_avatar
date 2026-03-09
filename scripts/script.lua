local squapi = require("scripts/libs/SquAPI")
local tailPhysics = require("scripts/libs/tail")
local AW = require("scripts/ActionWheel")

vanilla_model.PLAYER:setVisible(false)
vanilla_model.CAPE:setVisible(false)
vanilla_model.ARMOR:setVisible(config:load("armorSwitch"))
if config:load("armorSwitch") then
    vanilla_model.HELMET:setVisible(config:load("helmetSwitch"))
end


local ears = models.models.ears
local head = models.models.model.root.torso.Head
local tail = {
    models.models.tail.Tail.Tail1,
    models.models.tail.Tail.Tail1.Tail2,
    models.models.tail.Tail.Tail1.Tail2.Tail3,
    models.models.tail.Tail.Tail1.Tail2.Tail3.Tail4,
    models.models.tail.Tail.Tail1.Tail2.Tail3.Tail4.Tail5,
    models.models.tail.Tail.Tail1.Tail2.Tail3.Tail4.Tail5.Tail6,
    models.models.tail.Tail.Tail1.Tail2.Tail3.Tail4.Tail5.Tail6.Tail7,
    models.models.tail.Tail.Tail1.Tail2.Tail3.Tail4.Tail5.Tail6.Tail7.Tail8,
    --models.models.tail.Tail.Tail1.Tail2.Tail3.Tail4.Tail5.Tail6.Tail7.Tail8.Tail9,
    --models.models.tail.Tail.Tail1.Tail2.Tail3.Tail4.Tail5.Tail6.Tail7.Tail8.Tail9.Tail10
}

squapi.eye:new(
    models.models.model.root.torso.Head.Eyes.Pupils.PupilLeft2,
    1.2, 0.25, 0.5, 0.5
)
squapi.eye:new(
    models.models.model.root.torso.Head.Eyes.Pupils.PupilRight2,
    0.25, 1.2, 0.5, 0.5
)
squapi.eye:new(
    models.models.model.root.torso.Head.Eyes.Pupils.PupilLeft1,
    1.2, 0.25, 0.25, 0.25
)
squapi.eye:new(
    models.models.model.root.torso.Head.Eyes.Pupils.PupilRight1,
    0.25, 1.2, 0.25, 0.25
)

squapi.smoothHead:new(
    {
      models.models.model.root.torso,
    	models.models.model.root.torso.Head --element(you can have multiple elements in a table)
    },
	{
		0.15,
		1
	},    --(1) strength(you can make this a table too)
    0.1,    --(0.1) tilt
    1,    --(1) speed
    nil,    --(true) keepOriginalHeadPos
    false,     --(true) fixPortrait
    nil,     --(nil) animStraightenList
    nil,     --(0.5) straightenMultiplier
    nil,     --(0.5) straightenSpeed
    nil     --(0.1) blendToConsiderStopped
)

squapi.ear:new(
    ears.Ears.EarLeft,
    ears.Ears.EarRight,
    0.75, --(1) rangeMultiplier
    false, --(false) horizontalEars
    1, --(2) bendStrength
    nil, --(true) doEarFlick
    nil, --(400) earFlickChance
    nil, --(0.1) earStiffness
    0.5  --(0.8) earBounce
)

squapi.randimation:new(
    animations["models.model"].blink,
    nil,    --(100) minTime
    nil,    --(300) maxTime
    true     --(false) stopOnSleep
)

local tailModel = tailPhysics.new(models.models.tail.Tail.Tail1)
tailModel:setConfig {
    idleSpeed = vec(0.01, 0.01, 0.1),
    idleStrength = vec(2, 0.1, 8),
    walkSpeed = vec(0, 0, 0.75),
    walkStrength = vec(0.2, 0.05, 1),
    bounce = 0.1,
    stiff = 0.1,
}

local function loadConfig()
    local skinConfig = config:load("skinSettings")
    if skinConfig == nil then return end

    local skinTexture = textures:get("SkinTex")
    if skinTexture == nil then textures:read("SkinTex", skinConfig.skin64) end

    if skinConfig.eyeHeight == 2 then
        models.models.model.root.torso.Head.Eyes.Pupils.PupilLeft1:setVisible(false)
        models.models.model.root.torso.Head.Eyes.Pupils.PupilRight1:setVisible(false)

        models.models.model.root.torso.Head.Eyes.Pupils.PupilLeft2:setVisible(true)
        models.models.model.root.torso.Head.Eyes.Pupils.PupilRight2:setVisible(true)
        
        models.models.model.root.torso.Head.Eyelids.EyebrowRight2:setVisible(true)
        models.models.model.root.torso.Head.Eyelids.EyebrowLeft2:setVisible(true)
        
        models.models.model.root.torso.Head.Eyelids.EyebrowRight:setVisible(false)
        models.models.model.root.torso.Head.Eyelids.EyebrowLeft:setVisible(false)
    elseif skinConfig.eyeHeight == 1 then
        models.models.model.root.torso.Head.Eyes.Pupils.PupilLeft1:setVisible(true)
        models.models.model.root.torso.Head.Eyes.Pupils.PupilRight1:setVisible(true)

        models.models.model.root.torso.Head.Eyes.Pupils.PupilLeft2:setVisible(false)
        models.models.model.root.torso.Head.Eyes.Pupils.PupilRight2:setVisible(false)
        
        models.models.model.root.torso.Head.Eyelids.EyebrowRight2:setVisible(false)
        models.models.model.root.torso.Head.Eyelids.EyebrowLeft2:setVisible(false)
        
        models.models.model.root.torso.Head.Eyelids.EyebrowRight:setVisible(true)
        models.models.model.root.torso.Head.Eyelids.EyebrowLeft:setVisible(true)
    end
    models.models.model.root.torso.Head.Eyelids:setPos(0, -3 + skinConfig.eyesY + skinConfig.eyeHeight, 0)
    models.models.model.root.torso.Head.Eyes.Pupils:setPos(0, -2 + skinConfig.eyesY, 0)

    local eyeWhiteTex = textures:get("EyeWhiteTex")
    if eyeWhiteTex == nil then eyeWhiteTex = textures:newTexture("EyeWhiteTex", 16, 16) end

    local pixelRU = textures["SkinTex"]:getPixel(1, 1)
    local pixelRD = textures["SkinTex"]:getPixel(1, 2)
    local pixelLU = textures["SkinTex"]:getPixel(6, 1)
    local pixelLD = textures["SkinTex"]:getPixel(6, 2)

    eyeWhiteTex:fill(0, 0, 4, 8, pixelRU[3], pixelRU[2], pixelRU[1])
    eyeWhiteTex:fill(4, 0, 4, 8, pixelLU[3], pixelLU[2], pixelLU[1])
    if pixelRD[4] ~= 0 and pixelLD[4] ~= 0 then
        eyeWhiteTex:fill(0, 8 - skinConfig.eyesY - 1, 4, skinConfig.eyesY + 1, pixelRD[3], pixelRD[2], pixelRD[1])
        eyeWhiteTex:fill(4, 8 - skinConfig.eyesY - 1, 4, skinConfig.eyesY + 1, pixelLD[3], pixelLD[2], pixelLD[1])
    end

    eyeWhiteTex:update()
    if models.models.model.root.torso.Head.Eyes.EyeWhite:getPrimaryTexture() == "PRIMARY" then
        models.models.model.root.torso.Head.Eyes.EyeWhite:setPrimaryTexture("CUSTOM", textures["EyeWhiteTex"])
    end
    --textures["SkinTex"]:update()
    if models.models.model:getPrimaryTexture() == "PRIMARY" then
        models.models.model:setPrimaryTexture("CUSTOM", textures["SkinTex"])
        models.models.tail:setPrimaryTexture("PRIMARY")
        ears:setPrimaryTexture("PRIMARY")
    end

    --AW.loadConfig(skinConfig.eyesY, skinConfig.eyeHeight)
end


function events.entity_init()

    loadConfig()

    if config:load("helmetSwitch") == nil then config:save("helmetSwitch", true) end
    if config:load("armorSwitch") == nil then config:save("armorSwitch", true) end

    models.models.model.root.torso.Head.Eyes.EyeWhite:setPrimaryRenderType("EMISSIVE_SOLID")
    ears:moveTo(head)

    models.models.tail:moveTo(models.models.model.root.torso.Body)

    models.models.plushe:moveTo(head)
    head.plushe:setVisible(false)
    head.plushe:setScale(0.5, 0.5, 0.5)
    head.plushe:setPos(0, 17, 3)
    
    models.models.goggles:moveTo(head)
    head.goggles:setVisible(false)
    --logTable(textures:getTextures())
end


function events.tick()
  --code goes here
end

--render event, called every time your avatar is rendered
--it have two arguments, "delta" and "context"
--"delta" is the percentage between the last and the next tick (as a decimal value, 0.0 to 1.0)
--"context" is a string that tells from where this render event was called (the paperdoll, gui, player render, first person)
function events.render(delta, context)
  --code goes here
end
