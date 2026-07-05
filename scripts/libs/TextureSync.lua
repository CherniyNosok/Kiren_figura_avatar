--=============================================================================
-- TextureSync.lua — Синхронизация строковых данных через пинги Figura
--
-- Тот же паттерн, что SyncLib: register / set / get / tick / init
-- Но для больших строк (текстуры), которые не влезают в один пинг.
-- Автоматически режет на чанки, отправляет, склеивает, применяет.
--
-- Размещение: avatar/scripts/TextureSync.lua
-- Подключение: local TextureSync = require("TextureSync")
--=============================================================================

local TextureSync = {}
TextureSync.__index = TextureSync

-- Байт данных в одном чанке (с запасом под лимит 1024 байт/сек)
local MAX_CHUNK = 500

-- Тиков между чанками (20 = 1 секунда)
local CHUNK_INTERVAL = 30

-------------------------------------------------------------------------------
-- Конструктор
-------------------------------------------------------------------------------
--- @param opts table|nil { syncInterval = тиков_между_повторами } — по умолч. 600 (30 сек)
function TextureSync.new(opts)
    opts = opts or {}

    local self = setmetatable({}, TextureSync)

    self._entries   = {}   -- [idx] = name
    self._nameToIdx = {}   -- name → idx
    self._values    = {}   -- name → string (текущие данные)
    self._callbacks = {}   -- name → function(dataString)

    -- Очередь отправки чанков
    self._queue = {}       -- { { name, data, totalChunks, nextChunk, wait }, … }

    -- Буферы приёма: [idx] = { totalChunks, chunks={ [1]=str, … }, got=0 }
    self._buffers = {}

    -- Таймер повторной синхронизации
    self._syncInterval = opts.syncInterval or 600
    self._syncTimer    = 0

    self._ready = false

    local manager = self

    function pings.__texChunk(idx, chunkIndex, totalChunks, data)
        manager:_onChunk(idx, chunkIndex, totalChunks, data)
    end

    return self
end

-------------------------------------------------------------------------------
-- Регистрация
-------------------------------------------------------------------------------
--- @param name     string    Уникальный ключ
--- @param default  string?   Значение по умолчанию (nil = пусто)
--- @param callback function  function(dataString) — вызывается при получении
function TextureSync:register(name, default, callback)
    callback = callback or function() end

    if self._nameToIdx[name] then
        error("TextureSync: '" .. name .. "' уже зарегистрирован")
    end

    local idx = #self._entries + 1
    self._entries[idx]        = name
    self._nameToIdx[name]     = idx
    self._values[name]        = default or ""
    self._callbacks[name]     = callback

    return self
end

-------------------------------------------------------------------------------
-- Инициализация (после всех register)
-------------------------------------------------------------------------------
function TextureSync:init()
    if self._ready then return self end

    for _, name in ipairs(self._entries) do
        local saved = config:load(name)
        if saved ~= nil and saved ~= "" then
            self._values[name] = saved
        end
        -- Применяем локально (без пингов)
        if self._values[name] ~= "" then
            self._callbacks[name](self._values[name])
        end
    end

    self._ready = true
    return self
end

-------------------------------------------------------------------------------
-- Установить значение (хост)
-------------------------------------------------------------------------------
--- @param name string
--- @param data string  Строка байтов (сжатая текстура и т.д.)
function TextureSync:set(name, data)
    local idx = self._nameToIdx[name]
    if not idx then
        error("TextureSync: неизвестное значение '" .. name .. "'")
    end

    self._values[name] = data or ""

    config:save(name, data)

    -- Локальное применение
    if data and data ~= "" then
        self._callbacks[name](data)
    end

    -- Отменяем текущую отправку этой текстуры
    self:_cancelSend(name)

    -- И очищаем буфер приёма (старые чанки не нужны)
    self:_cancelRecv(name)

    -- Немедленная отправка новой текстуры
    self:_enqueue(name, data)

    return self
end

-------------------------------------------------------------------------------
-- Получить текущее значение
-------------------------------------------------------------------------------
--- @param name string
--- @return string?  Строка байтов или nil
function TextureSync:get(name)
    return self._values[name]
end

-------------------------------------------------------------------------------
-- Удалить значение
-------------------------------------------------------------------------------
--- @param name string
function TextureSync:remove(name)
    local idx = self._nameToIdx[name]
    if not idx then return end

    self._values[name] = ""
    config:save(name, nil)

    self:_cancelSend(name)
    self:_cancelRecv(name)
end

-------------------------------------------------------------------------------
-- Tick
-------------------------------------------------------------------------------
function TextureSync:tick()
    if not self._ready then return end

    -- Отправка чанков из очереди
    self:_processQueue()

    -- Периодическая повторная синхронизация всех непустых значений
    self._syncTimer = self._syncTimer + 1
    if self._syncTimer >= self._syncInterval then
        self._syncTimer = 0
        for _, name in ipairs(self._entries) do
            if self._values[name] ~= "" then
                self:_enqueue(name, self._values[name])
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Внутреннее: отменить отправку
-------------------------------------------------------------------------------
--- Убрать из очереди все записи для данной текстуры.
function TextureSync:_cancelSend(name)
    local idx = self._nameToIdx[name]
    for i = #self._queue, 1, -1 do
        if self._queue[i].idx == idx then
            table.remove(self._queue, i)
        end
    end
end

-------------------------------------------------------------------------------
-- Внутреннее: отменить приём
-------------------------------------------------------------------------------
--- Очистить буфер сборки для данной текстуры.
function TextureSync:_cancelRecv(name)
    local idx = self._nameToIdx[name]
    if idx then
        self._buffers[idx] = nil
    end
end

-------------------------------------------------------------------------------
-- Внутреннее: поставить в очередь
-------------------------------------------------------------------------------
function TextureSync:_enqueue(name, data)
    if not data or data == "" then return end

    local idx = self._nameToIdx[name]
    local totalChunks = math.ceil(#data / MAX_CHUNK)

    table.insert(self._queue, {
        idx         = idx,
        data        = data,
        totalChunks = totalChunks,
        nextChunk   = 1,
        wait        = CHUNK_INTERVAL,  -- первый чанк уйдёт сразу
    })
end

-------------------------------------------------------------------------------
-- Внутреннее: отправка из очереди
-------------------------------------------------------------------------------
function TextureSync:_processQueue()
    if #self._queue == 0 then return end

    local entry = self._queue[1]

    entry.wait = entry.wait + 1
    if entry.wait < CHUNK_INTERVAL then return end
    entry.wait = 0

    local startByte = (entry.nextChunk - 1) * MAX_CHUNK + 1
    local endByte   = math.min(startByte + MAX_CHUNK - 1, #entry.data)
    local chunk     = entry.data:sub(startByte, endByte)

    pings.__texChunk(entry.idx, entry.nextChunk, entry.totalChunks, chunk)

    entry.nextChunk = entry.nextChunk + 1

    if entry.nextChunk > entry.totalChunks then
        table.remove(self._queue, 1)
    end
end

-------------------------------------------------------------------------------
-- Внутреннее: приём чанка
-------------------------------------------------------------------------------
function TextureSync:_onChunk(idx, chunkIndex, totalChunks, data)
    if not self._buffers[idx] then
        self._buffers[idx] = {
            totalChunks = totalChunks,
            chunks      = {},
            got         = 0,
        }
    end

    local buf = self._buffers[idx]

    if buf.totalChunks ~= totalChunks then
        buf.chunks      = {}
        buf.got         = 0
        buf.totalChunks = totalChunks
    end

    if not buf.chunks[chunkIndex] then
        buf.chunks[chunkIndex] = data
        buf.got = buf.got + 1
    end

    if buf.got >= totalChunks then
        local full = {}
        for i = 1, totalChunks do
            full[i] = buf.chunks[i]
        end

        self._buffers[idx] = nil

        local name = self._entries[idx]
        local fullData = table.concat(full)

        self._values[name] = fullData
        self._callbacks[name](fullData)
    end
end

-------------------------------------------------------------------------------
-- Утилиты
-------------------------------------------------------------------------------
--- Прогресс приёма.
function TextureSync:progress(name)
    local idx = self._nameToIdx[name]
    if not idx then return 0, 0 end
    local buf = self._buffers[idx]
    if not buf then return 0, 0 end
    return buf.got, buf.totalChunks
end

--- Размер очереди.
function TextureSync:queueSize()
    return #self._queue
end

return TextureSync