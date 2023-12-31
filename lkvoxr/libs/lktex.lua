--[[
    lktex.lua
    
    lokachop's texture library
    licensed under the MIT license (refer to LICENSE)
]]--

LKTEX = LKTEX or {}
LKTEX.Textures = LKTEX.Textures or {}

local _nameLUT = {}
local _idLUT = {}
local _lastID = 0
function LKTEX.DeclareFromData(name, data)
    _lastID = _lastID + 1
    LKTEX.Textures[_lastID] = data
    _nameLUT[name] = _lastID
    _idLUT[_lastID] = name
end


-- for cc
local _COMPUTERCRAFT = false

local function readByte(fileObject)
    if _COMPUTERCRAFT then
        -- todo: support computercraft on this
    else
        return string.byte(fileObject:read(1))
    end
end

local function closeFile(fileObject)
    if _COMPUTERCRAFT then
        fileObject.close()
    else
        fileObject:close()
    end
end

local function readAndGetFileObject(path)
    if _COMPUTERCRAFT then
        local f = fs.open(path, "rb")
        return f
    else
        local f = love.filesystem.newFile(path)
        f:open("r")
        return f
    end
end

local function readString(fileObject)
    -- read the 0A (10)
    local readCont = readByte(fileObject)
    if readCont ~= 10 then
        return "nostring :("
    end

    local buff = {}
    for i = 1, 4096 do -- read long strings
        readCont = readByte(fileObject)
        if readCont == 10 then
            break
        end

        buff[#buff + 1] = string.char(readCont)
    end

    return table.concat(buff, "")
end

local function readUntil(fileObject, stopNum)
    local readCont
    local buff = {}
    for i = 1, 2048 do -- read big nums
        readCont = readByte(fileObject)
        if readCont == stopNum then
            break
        end

        buff[#buff + 1] = string.char(readCont)
    end
    return table.concat(buff, "")
end

-- ppm files are header + raw data which is EZ
function LKTEX.LoadPPM(name, path)
    local data = {}

    print("---LKTEX-PPMLoad---")
    print("Loading texture at \"" .. path .. "\"")


    local fObj = readAndGetFileObject(path)
    local readCont = readByte(fObj)
    if readCont ~= 80 then
        closeFile(fObj)
        error("PPM Decode error! (header no match!) [" .. readCont .. "]")
        return
    end

    readCont = readByte(fObj)
    if readCont ~= 54 then
        closeFile(fObj)
        error("PPM Decode error! (header no match!) [" .. readCont .. "]")
        return
    end
    readCont = readByte(fObj)
    -- string, read until next 10
    if readCont == 10 then
        local fComm = readUntil(fObj, 10)
        print("Comment; \"" .. fComm .. "\"")
    end

    -- read the width and height
    local w = tonumber(readUntil(fObj, 32))
    local h = tonumber(readUntil(fObj, 10))

    local cDepth = tonumber(readUntil(fObj, 10))
    print("Texture is " .. w .. "x" .. h .. " with a coldepth of " .. cDepth)

    local pixToRead = w * h
    for i = 0, (pixToRead - 1) do
        local r = readByte(fObj)
        local g = readByte(fObj)
        local b = readByte(fObj)

        data[i] = {r, g, b}
    end

    data.data = {w, h}

    closeFile(fObj)

    LKTEX.DeclareFromData(name, data)
end

function LKTEX.GetByName(name)
    return LKTEX.Textures[_nameLUT[name]]
end

function LKTEX.GetByIndex(idx)
    return LKTEX.Textures[idx or 1]
end

function LKTEX.GetNameByIndex(idx)
    return _idLUT[idx or 1]
end

function LKTEX.GetIndexByName(Name)
    return _nameLUT[name]
end


LKTEX.LoadPPM("none",       "textures/loka_lq.ppm")
LKTEX.LoadPPM("loka",       "textures/loka_lq.ppm")
LKTEX.LoadPPM("jelly",      "textures/jelly_lq.ppm")
LKTEX.LoadPPM("jet",        "textures/jet_lq.ppm")
LKTEX.LoadPPM("mandrill",   "textures/mandrill_lq.ppm")