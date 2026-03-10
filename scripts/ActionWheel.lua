local skinsApi = require("scripts/skinsScript")

local AW = {}

local currentSkinIdx = 0
local eyesY = 2
local eyeHeight = 1
local helmetSwitch = config:load("helmetSwitch")
local armorSwitch = config:load("armorSwitch")

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
    :setToggled(armorSwitch)

local toggleHelmet = mainPage:newAction()
    :setItem("minecraft:iron_helmet")
    :setToggleColor(0, 1, 0)
    :setToggleTitle("Шлем включен")
    :setColor(1, 0, 0)
    :setTitle("Шлем выключен")
    :setToggled(helmetSwitch)

local actionGotoBackSkins = skinPage:newAction()
    :onLeftClick(function() 
        action_wheel:setPage(mainPage)
    end)
    :setItem("minecraft:barrier")
    :setTitle("Назад")

local chooseEyeY = skinPage:newAction()
    :setTitle("Координата глаз: "..eyesY)
    :setItem("minecraft:ender_pearl")

local chooseEyeHeight = skinPage:newAction()
    :setTitle("Высота глаз: "..eyeHeight)
    :setItem("minecraft:ender_eye")
    
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

function pings.clickApply()
    if currentSkinIdx > 0 then
        skinsApi.ApplySkin(currentSkinIdx, eyesY, eyeHeight)
    end
end

chooseSkin:setOnScroll(scrollingSkin)
    :setOnLeftClick(pings.clickApply)

local function scrollingEyesY(dir)
    if dir > 0 then
        eyesY = eyesY + 1
    else
        eyesY = eyesY - 1
    end

    if eyesY < 0 then
        eyesY = 8 - (eyeHeight + 1)
    elseif eyesY > 8 - (eyeHeight + 1) then
        eyesY = 0
    end

    chooseEyeY:setTitle("Координата глаз: "..eyesY)
end

local function scrollingEyeHeight(dir)
    if dir > 0 then
        eyeHeight = eyeHeight + 1
    else
        eyeHeight = eyeHeight - 1
    end

    if eyeHeight < 1 then
        eyeHeight = 2
    elseif eyeHeight > 2 then
        eyeHeight = 1
    end

    chooseEyeHeight:setTitle("Высота глаз: "..eyeHeight)
end

chooseEyeHeight:onScroll(scrollingEyeHeight)
    :setOnLeftClick(pings.clickApply)
chooseEyeY:onScroll(scrollingEyesY)
    :setOnLeftClick(pings.clickApply)

function pings.clickArmorSwitch(state)
    vanilla_model.ARMOR:setVisible(state)
    armorSwitch = state
    config:save("armorSwitch", armorSwitch)
    if not helmetSwitch then
        vanilla_model.HELMET:setVisible(helmetSwitch)
    end
end

function pings.clickHelmetSwitch(state)
    vanilla_model.HELMET:setVisible(state)
    helmetSwitch = state
    config:save("helmetSwitch", helmetSwitch)
end

toggleArmor:setOnToggle(pings.clickArmorSwitch)
toggleHelmet:setOnToggle(pings.clickHelmetSwitch)

function pings.clickPlusheSwitch(state)
    models.models.model.root.torso.Head.plushe:setPrimaryTexture("PRIMARY")
    models.models.model.root.torso.Head.plushe:setVisible(state)
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

togglePlushe:setOnToggle(pings.clickPlusheSwitch)
    :setTexture(getPlusheTexture(), 8, 8, 8, 8, 2)

function pings.clickGogglesSwitch(state)
    models.models.model.root.torso.Head.goggles:setPrimaryTexture("PRIMARY")
    models.models.model.root.torso.Head.goggles:setVisible(state)
end

toggleGoggles:setOnToggle(pings.clickGogglesSwitch)

local function loadConfig()
    local skinConfig = config:load("skinSettings")
    if skinConfig == nil then return end
    eyesY = skinConfig.eyesY
    eyeHeight = skinConfig.eyeHeight

    chooseEyeY:setTitle("Координата глаз: "..eyesY)
    chooseEyeHeight:setTitle("Высота глаз: "..eyeHeight)
end

function events.entity_init()
    loadConfig()
end

return AW