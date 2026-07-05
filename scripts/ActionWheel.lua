local skinsApi = require("scripts/skinsScript")
local SyncLib = require("scripts.libs.SyncLib")

local AW = {}

local sync = SyncLib:new({interval = 100})

skinsApi.texSync:register("skinTex", nil, function(data)
    textures:read("SkinTex", data)
    log("Применен")
    skinsApi.ApplySkin()
    sync:markDirty()
end)

local currentSkinIdx = 0
-- local eyesY = 2
-- local eyeHeight = 1

sync:register("helmet", true, SyncLib.BOOLEAN, function(visible)
    vanilla_model.HELMET:setVisible(visible)
end)
sync:register("armor", true, SyncLib.BOOLEAN, function(visible)
    vanilla_model.ARMOR:setVisible(visible)
end)
sync:register("plushe", false, SyncLib.BOOLEAN, function(visible)
    if models.models.model.root.torso.Head.plushe ~= nil then
        models.models.model.root.torso.Head.plushe:setPrimaryTexture("PRIMARY")
        models.models.model.root.torso.Head.plushe:setVisible(visible)
    end
end)
sync:register("goggles", false, SyncLib.BOOLEAN, function(visible)
    if models.models.model.root.torso.Head.goggles ~= nil then
        models.models.model.root.torso.Head.goggles:setPrimaryTexture("PRIMARY")
        models.models.model.root.torso.Head.goggles:setVisible(visible)
    end
end)

-- local helmetSwitch = config:load("helmetSwitch")
-- local armorSwitch = config:load("armorSwitch")

local mainPage = action_wheel:newPage()
local skinPage = action_wheel:newPage()

action_wheel:setPage(mainPage)

local toggleGoggles = mainPage:newAction()
    :setToggleColor(vectors.hexToRGB("FFFFC400"))
    :setTitle("Очки")
    :setItem("minecraft:glass_pane")

local togglePlushe = mainPage:newAction()
    :setToggleColor(vectors.hexToRGB("#ff7e00"))
    :setTitle("Плюшка")

local actionGotoSkinPage = mainPage:newAction()
    :onLeftClick(function()
        action_wheel:setPage(skinPage)
    end)
    :setItem("minecraft:leather_chestplate")
    :setTitle("Изменить скин")

local toggleArmor = mainPage:newAction()
    :setItem("minecraft:iron_chestplate")
    :setToggleColor(0, 1, 0)
    :setToggleTitle("Броня включена")
    :setColor(1, 0, 0)
    :setTitle("Броня выключена")

local toggleHelmet = mainPage:newAction()
    :setItem("minecraft:iron_helmet")
    :setToggleColor(0, 1, 0)
    :setToggleTitle("Шлем включен")
    :setColor(1, 0, 0)
    :setTitle("Шлем выключен")

local actionGotoBackSkins = skinPage:newAction()
    :onLeftClick(function() 
        action_wheel:setPage(mainPage)
    end)
    :setItem("minecraft:barrier")
    :setTitle("Назад")

local chooseEyeY = skinPage:newAction()
    :setTitle("Координата глаз: "..skinsApi.eyesY)
    :setItem("minecraft:ender_pearl")

local chooseEyeHeight = skinPage:newAction()
    :setTitle("Высота глаз: "..skinsApi.eyeHeight)
    :setItem("minecraft:ender_eye")

sync:register("eyesY", 2, SyncLib.INT8, function(y)
    skinsApi.eyesY = y
    chooseEyeY:setTitle("Координата глаз: "..skinsApi.eyesY)
    skinsApi.ApplySkin()
end)
sync:register("eyeHeight", 1, SyncLib.INT8, function(h)
    skinsApi.eyeHeight = h
    chooseEyeHeight:setTitle("Высота глаз: "..skinsApi.eyeHeight)
    skinsApi.ApplySkin()
end)
    
local chooseSkin = skinPage:newAction()
    :setTitle("Скины")
    :setItem("minecraft:player_head")

local function scrollingSkin(dir)
    if dir > 0 then
        currentSkinIdx = currentSkinIdx + 1
    else
        currentSkinIdx = currentSkinIdx - 1
    end

    if currentSkinIdx > #skinsApi.skins then
        currentSkinIdx = 1
    elseif currentSkinIdx < 1 then
        currentSkinIdx = #skinsApi.skins
    end

    if currentSkinIdx ~= 0 and #skinsApi.skins > 0 then
        chooseSkin:setItem()
            :title(skinsApi.skins[currentSkinIdx].name)
            :setTexture(skinsApi.skins[currentSkinIdx].texture, 20, 20, 8, 12, 2)
    end
end

local function clickApply()
    if currentSkinIdx > 0 then
        local tmp = skinsApi.skins[currentSkinIdx].texture:save()
        skinsApi.texSync:set("skinTex", tmp)
    end
end

chooseSkin:setOnScroll(scrollingSkin)
    :setOnLeftClick(function()
        clickApply()
        skinsApi.ApplySkin()
    end)

local function scrollingEyesY(dir)
    if dir > 0 then
        skinsApi.eyesY = skinsApi.eyesY + 1
    else
        skinsApi.eyesY = skinsApi.eyesY - 1
    end

    if skinsApi.eyesY < 0 then
        skinsApi.eyesY = 8 - (skinsApi.eyeHeight + 1)
    elseif skinsApi.eyesY > 8 - (skinsApi.eyeHeight + 1) then
        skinsApi.eyesY = 0
    end

    chooseEyeY:setTitle("Координата глаз: "..skinsApi.eyesY)
end

local function scrollingEyeHeight(dir)
    if dir > 0 then
        skinsApi.eyeHeight = skinsApi.eyeHeight + 1
    else
        skinsApi.eyeHeight = skinsApi.eyeHeight - 1
    end

    if skinsApi.eyeHeight < 1 then
        skinsApi.eyeHeight = 2
    elseif skinsApi.eyeHeight > 2 then
        skinsApi.eyeHeight = 1
    end

    chooseEyeHeight:setTitle("Высота глаз: "..skinsApi.eyeHeight)
end

chooseEyeHeight:onScroll(scrollingEyeHeight)
    :setOnLeftClick(function()
        sync:set("eyeHeight", skinsApi.eyeHeight)
    end)
chooseEyeY:onScroll(scrollingEyesY)
    :setOnLeftClick(function()
        sync:set("eyesY", skinsApi.eyesY)
    end)

local function clickArmorSwitch(state)
    sync:set("armor", state)
    if not sync:get("helmet") then
        sync:toggle("helmet")
    end
end

local function clickHelmetSwitch(state)
    sync:set("helmet", state)
end

toggleArmor:setOnToggle(clickArmorSwitch)
toggleHelmet:setOnToggle(clickHelmetSwitch)

function pings.clickPlusheSwitch()
    models.models.model.root.torso.Head.plushe:setPrimaryTexture("PRIMARY")
end

local function getPlusheTexture()
    local tex
    for k, v in pairs(textures:getTextures()) do
        if v:getName():find("plusheTexture") then
            tex = textures:copy("PlusheIcon", v)

            for x = 0, 7 do
                for y = 0, 7 do
                    local pixel = tex:getPixel(40 + x, 8 + y)
                    if pixel[4] ~= 0 then
                        tex:setPixel(8 + x, 8 + y, pixel)
                    end
                end
            end
        end
    end
    return tex
end

togglePlushe:setOnToggle(function(visible)
    pings.clickPlusheSwitch()
    sync:set("plushe", visible)
end)
    :setTexture(getPlusheTexture(), 8, 8, 8, 8, 2)

function pings.clickGogglesSwitch()
    models.models.model.root.torso.Head.goggles:setPrimaryTexture("PRIMARY")
end

toggleGoggles:setOnToggle(function(visible)
    pings.clickGogglesSwitch()
    sync:set("goggles", visible)
end)

-- local function loadConfig()
--     local skinConfig = config:load("skinSettings")
--     if skinConfig == nil then return end
--     skinsApi.eyesY = skinConfig.eyesY
--     skinsApi.eyeHeight = skinConfig.eyeHeight

--     chooseEyeY:setTitle("Координата глаз: "..skinsApi.eyesY)
--     chooseEyeHeight:setTitle("Высота глаз: "..skinsApi.eyeHeight)
-- end

function events.entity_init()
    sync:init()
end

function events.tick()
    sync:tick()

    local a, b = skinsApi.texSync:progress("skinTex")
    -- log(a, b)
end

return AW