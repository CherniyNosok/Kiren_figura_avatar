--=============================================================================
-- SyncLib.lua — Библиотека синхронизации состояний для Figura
--
-- Решает проблему: данные конфигов не передаются другим игрокам при загрузке
-- аватара. Использует пинги Figura для рассылки состояний переключателей.
--
-- Размещение: avatar/scripts/SyncLib.lua
-- Подключение: local SyncLib = require("SyncLib")
--
-- Принцип работы:
--   1. При init() состояния загружаются из конфига и применяются ЛОКАЛЬНО
--   2. При set()/toggle() — применяются локально + мгновенный ping
--   3. Периодический fullSync (через tick) — догоняет новые игроки
--   4. Пинги при загрузке НЕ отправляются (как рекомендует Figura Wiki)
--
-- Ограничения пингов (Figura Backend):
--   — 1024 байт/сек
--   — 32 пинга/сек
--=============================================================================
---@class SyncLib
local SyncLib = {}
SyncLib.__index = SyncLib

-- Типы значений для сериализации
SyncLib.BOOLEAN = "boolean"
SyncLib.INT8    = "int8"     -- -128 .. 127 (1 байт в fullSync)
SyncLib.INT16   = "int16"    -- -32768 .. 32767 (2 байта в fullSync)
SyncLib.INT32   = "int32"    -- ≈ ±2.1 млрд (4 байта в fullSync)

-------------------------------------------------------------------------------
-- Конструктор
-------------------------------------------------------------------------------
--- Создать новый экземпляр менеджера синхронизации.
---@param opts table|nil { interval = число_тиков }  — по умолчанию 60 (3 сек)
---@return SyncLib
function SyncLib.new(opts)
    opts = opts or {}

    local self = setmetatable({}, SyncLib)

    -- Внутренние таблицы (индексированные по порядку регистрации)
    self._entries      = {}     -- [idx] = name        (порядок важен для fullSync)
    self._nameToIdx    = {}     -- name  → idx
    self._defaults     = {}     -- name  → default
    self._values       = {}     -- name  → current value
    self._types        = {}     -- name  → SyncLib.BOOLEAN / INT8 / …
    self._callbacks    = {}     -- name  → function(value)

    -- Состояние синхронизации
    self._dirty        = true   -- true = нужен fullSync
    self._timer        = 0      -- счётчик тиков с последнего fullSync
    self._interval     = opts.interval or 60   -- тиков между fullSync
    self._ready        = false  -- true после init()

    ------------------------------------------------------------------------
    -- Регистрация ping-функций.
    -- Важно: локальную ссылку self захватываем ДО назначения в pings.
    -- После pings.__syncLib_full = … Figura заменит значение на Java-обёртку,
    -- но оригинальная Lua-функция сохранена внутри Figura и будет вызвана
    -- на принимающем клиенте.
    ------------------------------------------------------------------------
    local manager = self

    function pings.__syncLib_full(data)
        manager:_recvFull(data)
    end

    function pings.__syncLib_single(idx, val)
        manager:_recvSingle(idx, val)
    end

    return self
end

-------------------------------------------------------------------------------
-- Регистрация значений
-------------------------------------------------------------------------------
--- Зарегистрировать синхронизируемое значение.
---
--- Поддерживаемые сигнатуры:
---   register(name, default)                        — тип авто, без callback
---   register(name, default, callback)              — тип авто, с callback
---   register(name, default, valueType, callback)   — явный тип, с callback
---
--- Тип авто-определяется:
---   boolean → SyncLib.BOOLEAN
---   number  → SyncLib.INT8
---
---@param name     string  Уникальный ключ
---@param default  any     Значение по умолчанию
---@param vtype    string? Тип сериализации (SyncLib.BOOLEAN, INT8, …)
---@param callback function? Вызывается при изменении значения
function SyncLib:register(name, default, vtype, callback)
    -- Если vtype — функция, значит его пропустили
    if type(vtype) == "function" then
        callback = vtype
        vtype = nil
    end

    -- Авто-определение типа
    if vtype == nil then
        if type(default) == "boolean" then
            vtype = SyncLib.BOOLEAN
        elseif type(default) == "number" then
            vtype = SyncLib.INT8
        else
            error("SyncLib: не удалось определить тип для '" .. name
                .. "'. Укажите SyncLib.BOOLEAN / INT8 / INT16 / INT32.")
        end
    end

    if self._nameToIdx[name] then
        error("SyncLib: значение '" .. name .. "' уже зарегистрировано")
    end

    local idx = #self._entries + 1
    self._entries[idx]    = name
    self._nameToIdx[name] = idx
    self._defaults[name]  = default
    self._values[name]    = default
    self._types[name]     = vtype
    self._callbacks[name] = callback or function() end

    return self  -- цепочечный вызов
end

-------------------------------------------------------------------------------
-- Инициализация (ВЫЗЫВАТЬ ОДИН РАЗ, после всех register)
-------------------------------------------------------------------------------
--- Загружает состояния из конфига и применяет их ЛОКАЛЬНО (без пингов).
--- Помечает fullSync как грязный — при следующем tick отправит данные.
function SyncLib:init()
    if self._ready then
        print("[SyncLib] init() уже вызывался — пропуск")
        return self
    end

    for _, name in ipairs(self._entries) do
        local saved = config:load(name)
        if saved ~= nil then
            -- config:load возвращает nil на не-хосте — используем default
            self._values[name] = saved
        end
        -- Применяем ЛОКАЛЬНО (паттерн из Figura Wiki)
        self._callbacks[name](self._values[name])
    end

    self._dirty = true
    self._ready = true

    return self
end

-------------------------------------------------------------------------------
-- Установка значений (для хоста)
-------------------------------------------------------------------------------
--- Установить значение и синхронизировать с другими клиентами.
---@param name  string Ключ
---@param value any    Новое значение
function SyncLib:set(name, value)
    local idx = self._nameToIdx[name]
    if not idx then
        error("SyncLib: неизвестное значение '" .. name .. "'")
    end

    self._values[name] = value

    -- Сохраняем в конфиг (на не-хосте config:save игнорируется)
    config:save(name, value)

    -- Локальное применение (на всякий случай — дублирует init,
    -- но нужно если callback имеет побочные эффекты вроде анимаций)
    self._callbacks[name](value)

    -- Мгновенный ping для уже подключённых клиентов
    pings.__syncLib_single(idx, value)

    -- Помечаем, что новым игрокам нужен полный пакет
    self._dirty = true

    return self
end

--- Переключить boolean-значение.
---@param name string Ключ
---@return boolean Новое значение
function SyncLib:toggle(name)
    if self._types[name] ~= SyncLib.BOOLEAN then
        error("SyncLib: toggle() только для boolean, '" .. name
            .. "' имеет тип " .. tostring(self._types[name]))
    end
    local newVal = not self._values[name]
    self:set(name, newVal)
    return newVal
end

--- Получить текущее значение.
---@param name string Ключ
---@return any Текущее значение
function SyncLib:get(name)
    return self._values[name]
end

--- Принудительно запросить полную синхронизацию на следующем tick.
function SyncLib:markDirty()
    self._dirty = true
    return self
end

-------------------------------------------------------------------------------
-- Периодическая синхронизация
-------------------------------------------------------------------------------
--- Вызывать в events.tick().
--- Отправляет fullSync только если прошёл интервал.
function SyncLib:tick()
    if not self._ready then return end

    self._timer = self._timer + 1

    if self._timer >= self._interval then
        self._timer = 0
        self._dirty = false
        pings.__syncLib_full(self:_packAll())
    end
end

-------------------------------------------------------------------------------
-- Внутренние методы: сериализация
-------------------------------------------------------------------------------
--- Упаковать все значения в бинарную строку для fullSync.
---@return string Упакованные данные
function SyncLib:_packAll()
    local bytes = {}

    -- 1 байт: количество значений (защита от рассинхрона версий)
    table.insert(bytes, #self._entries)

    for _, name in ipairs(self._entries) do
        local vtype = self._types[name]
        local value = self._values[name]

        if vtype == SyncLib.BOOLEAN then
            table.insert(bytes, value and 1 or 0)

        elseif vtype == SyncLib.INT8 then
            local v = math.floor(value)
            if v < 0 then v = v + 256 end
            table.insert(bytes, v % 256)

        elseif vtype == SyncLib.INT16 then
            local v = math.floor(value)
            if v < 0 then v = v + 65536 end
            table.insert(bytes, v % 256)
            table.insert(bytes, math.floor(v / 256) % 256)

        elseif vtype == SyncLib.INT32 then
            local v = math.floor(value)
            if v < 0 then v = v + 4294967296 end
            table.insert(bytes, v % 256)
            table.insert(bytes, math.floor(v / 256) % 256)
            table.insert(bytes, math.floor(v / 65536) % 256)
            table.insert(bytes, math.floor(v / 16777216) % 256)
        end
    end

    return string.char(table.unpack(bytes))
end

--- Распаковать fullSync и применить все значения.
---@param data string Упакованные данные
function SyncLib:_recvFull(data)
    local bytes = {string.byte(data, 1, #data)}
    local pos = 2  -- первый байт = количество записей

    local count = bytes[1] or 0

    -- Защита: если количество не совпадает, ничего не делаем
    if count ~= #self._entries then
        print("[SyncLib] fullSync: несовпадение количества записей ("
            .. count .. " получено, " .. #self._entries .. " ожидалось). "
            .. "Версии скрипта могут отличаться.")
        return
    end

    for _, name in ipairs(self._entries) do
        local vtype = self._types[name]
        local value

        if vtype == SyncLib.BOOLEAN then
            value = (bytes[pos] == 1)
            pos = pos + 1

        elseif vtype == SyncLib.INT8 then
            value = bytes[pos]
            if value > 127 then value = value - 256 end
            pos = pos + 1

        elseif vtype == SyncLib.INT16 then
            value = bytes[pos] + bytes[pos + 1] * 256
            if value > 32767 then value = value - 65536 end
            pos = pos + 2

        elseif vtype == SyncLib.INT32 then
            value = bytes[pos]
                + bytes[pos + 1] * 256
                + bytes[pos + 2] * 65536
                + bytes[pos + 3] * 16777216
            if value > 2147483647 then value = value - 4294967296 end
            pos = pos + 4
        end

        if value ~= nil then
            self._values[name] = value
            self._callbacks[name](value)
        end
    end
end

--- Применить одиночное изменение (при ping).
---@param idx  number Индекс значения (1-based)
---@param value any   Новое значение
function SyncLib:_recvSingle(idx, value)
    local name = self._entries[idx]
    if name then
        self._values[name] = value
        self._callbacks[name](value)
    end
end

-------------------------------------------------------------------------------
-- Утилиты
-------------------------------------------------------------------------------
--- Вернуть таблицу всех текущих значений (для отладки).
---@return table { name = value, … }
function SyncLib:dump()
    local result = {}
    for _, name in ipairs(self._entries) do
        result[name] = self._values[name]
    end
    return result
end

return SyncLib