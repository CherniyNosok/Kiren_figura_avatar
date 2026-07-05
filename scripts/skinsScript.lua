local TextureSync = require("scripts.libs.TextureSync")

local SkinsScript = {}

SkinsScript.texSync = TextureSync.new({interval = 600})

-- SkinsScript.texSync:register("skinTex", nil, function(data)
--     textures:read("SkinTex", data)
-- end)

SkinsScript.eyesY = 2
SkinsScript.eyeHeight = 1

local skinsPath = avatar:getName().."/skins"
SkinsScript.skins = {}

local function readTexture(path)
    local inputStream = file:openReadStream(path)
    local buffer = data:createBuffer()

    buffer:readFromStream(inputStream)
    buffer:setPosition(0)

    local readedBase64 = buffer:readBase64(buffer:available())
    buffer:close()
    inputStream:close()

    return readedBase64
end

local function loadSkins()
    if not host:isHost() then return end

    local index = 1

    for key, value in ipairs(file:list(skinsPath)) do
        local match = string.match(value, "skin%d*_?([%w_]*)%.png")
        if match ~= nil then
            local readedBase64 = readTexture(skinsPath.."/"..value)

            local name
            if match ~= "" then
                name = match
            else
                name = "Skin"..index
            end

            local tex = textures:read(name, readedBase64)
            table.insert(SkinsScript.skins, {name = name, texture = tex})

            index = index + 1
        end
    end
end

function SkinsScript.ApplyEyesY()
    models.models.model.root.torso.Head.Eyelids:setPos(0, -3 + SkinsScript.eyesY + SkinsScript.eyeHeight, 0)
    models.models.model.root.torso.Head.Eyes.Pupils:setPos(0, -2 + SkinsScript.eyesY, 0)

    local eyeWhiteTex = textures:get("EyeWhiteTex")
    if eyeWhiteTex == nil then eyeWhiteTex = textures:newTexture("EyeWhiteTex", 16, 16) end
    
    if textures["SkinTex"] then
        local pixelRU = textures["SkinTex"]:getPixel(1, 1)
        local pixelRD = textures["SkinTex"]:getPixel(1, 2)
        local pixelLU = textures["SkinTex"]:getPixel(6, 1)
        local pixelLD = textures["SkinTex"]:getPixel(6, 2)

        eyeWhiteTex:fill(0, 0, 4, 8, pixelRU[3], pixelRU[2], pixelRU[1])
        eyeWhiteTex:fill(4, 0, 4, 8, pixelLU[3], pixelLU[2], pixelLU[1])
        if pixelRD[4] ~= 0 and pixelLD[4] ~= 0 then
            eyeWhiteTex:fill(0, 8 - SkinsScript.eyesY - 1, 4, SkinsScript.eyesY + 1, pixelRD[3], pixelRD[2], pixelRD[1])
            eyeWhiteTex:fill(4, 8 - SkinsScript.eyesY - 1, 4, SkinsScript.eyesY + 1, pixelLD[3], pixelLD[2], pixelLD[1])
        end

        --log(models.models.model.root.torso.Head.Eyes.EyeWhite:getTextureSize())

        eyeWhiteTex:update()
        models.models.model.root.torso.Head.Eyes.EyeWhite:setPrimaryTexture("CUSTOM", textures["EyeWhiteTex"])

        textures["SkinTex"]:update()
        models.models.model:setPrimaryTexture("CUSTOM", textures["SkinTex"])
        if models.models.model.root.torso.Body.tail then
            models.models.model.root.torso.Body.tail:setPrimaryTexture("PRIMARY")
        end
        if models.models.model.root.torso.Head.ears then
            models.models.model.root.torso.Head.ears:setPrimaryTexture("PRIMARY")
        end

    end
end

function SkinsScript.ApplyEyesHeight()
    if SkinsScript.eyeHeight == 2 then
        models.models.model.root.torso.Head.Eyes.Pupils.PupilLeft1:setVisible(false)
        models.models.model.root.torso.Head.Eyes.Pupils.PupilRight1:setVisible(false)

        models.models.model.root.torso.Head.Eyes.Pupils.PupilLeft2:setVisible(true)
        models.models.model.root.torso.Head.Eyes.Pupils.PupilRight2:setVisible(true)
        
        models.models.model.root.torso.Head.Eyelids.EyebrowRight2:setVisible(true)
        models.models.model.root.torso.Head.Eyelids.EyebrowLeft2:setVisible(true)
        
        models.models.model.root.torso.Head.Eyelids.EyebrowRight:setVisible(false)
        models.models.model.root.torso.Head.Eyelids.EyebrowLeft:setVisible(false)
    elseif SkinsScript.eyeHeight == 1 then
        models.models.model.root.torso.Head.Eyes.Pupils.PupilLeft1:setVisible(true)
        models.models.model.root.torso.Head.Eyes.Pupils.PupilRight1:setVisible(true)

        models.models.model.root.torso.Head.Eyes.Pupils.PupilLeft2:setVisible(false)
        models.models.model.root.torso.Head.Eyes.Pupils.PupilRight2:setVisible(false)
        
        models.models.model.root.torso.Head.Eyelids.EyebrowRight2:setVisible(false)
        models.models.model.root.torso.Head.Eyelids.EyebrowLeft2:setVisible(false)
        
        models.models.model.root.torso.Head.Eyelids.EyebrowRight:setVisible(true)
        models.models.model.root.torso.Head.Eyelids.EyebrowLeft:setVisible(true)
    end
    models.models.model.root.torso.Head.Eyelids:setPos(0, -3 + SkinsScript.eyesY + SkinsScript.eyeHeight, 0)
end

function SkinsScript.ApplySkin()
    if textures["SkinTex"] then
        SkinsScript.ApplyEyesHeight()
        SkinsScript.ApplyEyesY()

        textures["SkinTex"]:update()
        models.models.model:setPrimaryTexture("CUSTOM", textures["SkinTex"])
        if models.models.model.root.torso.Body.tail then
            models.models.model.root.torso.Body.tail:setPrimaryTexture("PRIMARY")
        end
        if models.models.model.root.torso.Head.ears then
            models.models.model.root.torso.Head.ears:setPrimaryTexture("PRIMARY")
        end

    end
    -- saveConfig(eyesY, eyeHeight)
end

function events.entity_init()
    if host:isHost() and not file:exists(skinsPath) then
        file:mkdirs(skinsPath)
        log("Папка скинов создана в figura/data/"..skinsPath)
    end

    loadSkins()
    SkinsScript.texSync:init()
end

function events.tick()
    SkinsScript.texSync:tick()
end

return SkinsScript