--[[
    lang.lua

    Lokachop's
    Angle
    Library

    coded by Lokachop, contact @ Lokachop#5862, lokachop or lokachop@gmail.com
    licensed under the MIT license (refer to LICENSE)

    this lib is terrible btw :(
]]--

LANG = LANG or {}

local math = math
local _rotMatrixCalc = LMAT.Matrix()
local _pattForm = "%4.2f, %4.2f, %4.2f"
local a_meta = {
    -- math
    ["__add"] = function(x, y)
        return LANG.Angle(x[1] + y[1], x[2] + y[2], x[3] + y[3])
    end,
    ["__sub"] = function(x, y)
        return LANG.Angle(x[1] - y[1], x[2] - y[2], x[3] - y[3])
    end,
    ["__unm"] = function(x, y)
        return LANG.Angle(-x[1], -x[2], -x[3])
    end,

    ["Normalize"] = function(x)
        x[1] = x[1] % 360
        x[2] = x[2] % 360
        x[3] = x[3] % 360
    end,

    -- equality
    ["__eq"] = function(x, y)
        return (type(x) == type(y)) and (x[1] == y[1]) and (x[2] == y[2]) and (x[3] == y[3])
    end,
    ["__lt"] = function(x, y)
        return (type(x) == type(y)) and (x[1] < y[1]) and (x[2] < y[2]) and (x[3] < y[3])
    end,
    ["__le"] = function(x, y)
        return (type(x) == type(y)) and (x[1] <= y[1]) and (x[2] <= y[2]) and (x[3] <= y[3])
    end,

    -- str
    ["__tostring"] = function(x)
        return string.format(_pattForm, x[1], x[2], x[3], x[4]) --x[1] .. "," .. x[2] .. "," .. x[3] .. "," .. x[4]
    end,
    ["__concat"] = function(x)
        return string.format(_pattForm, x[1], x[2], x[3], x[4]) --x[1] .. "," .. x[2] .. "," .. x[3] .. "," .. x[4]
    end,

    -- etc
    ["__name"] = "Angle",

    -- extras
    ["Add"] = function(x, y)
        x[1] = x[1] + y[1]
        x[2] = x[2] + y[2]
        x[3] = x[3] + y[3]
    end,
    ["Sub"] = function(x, y)
        x[1] = x[1] - y[1]
        x[2] = x[2] - y[2]
        x[3] = x[3] - y[3]
    end,
    ["MulA"] = function(x, y)
        x[1] = x[1] * y[1]
        x[2] = x[2] * y[2]
        x[3] = x[3] * y[3]
    end,
    ["Mul"] = function(x, y)
        x[1] = x[1] * y
        x[2] = x[2] * y
        x[3] = x[3] * y
    end,
    ["Div"] = function(x, y)
        x[1] = x[1] / y
        x[2] = x[2] / y
        x[3] = x[3] / y
    end,
    ["DivA"] = function(x, y)
        x[1] = x[1] / y[1]
        x[2] = x[2] / y[2]
        x[3] = x[3] / y[3]
    end,


    ["Copy"] = function(x)
        return LANG.Angle(x[1], x[2], x[3])
    end,

    -- rotations
    -- tacky until i do proper matrices
    ["Right"] = function(x)
        _rotMatrixCalc:Identity()
        _rotMatrixCalc:SetAngles(x)

        return LANG.Angle(_rotMatrixCalc[1], _rotMatrixCalc[2], _rotMatrixCalc[3])
    end,
    ["Up"] = function(x)
        _rotMatrixCalc:Identity()
        _rotMatrixCalc:SetAngles(x)

        return LANG.Angle(-_rotMatrixCalc[5], -_rotMatrixCalc[6], -_rotMatrixCalc[7])
    end,
    ["Forward"] = function(x)
        _rotMatrixCalc:Identity()
        _rotMatrixCalc:SetAngles(x)

        return LANG.Angle(_rotMatrixCalc[9], _rotMatrixCalc[10], _rotMatrixCalc[11])
    end,
}
a_meta.__index = a_meta


function LANG.Angle(x, y, z)
    if tonumber(x) == nil then
        local ang = {x[1] or 0, x[2] or 0, x[3] or 0} -- w is matrix only currently
        setmetatable(ang, a_meta)
        return ang
    else
        local ang = {x or 0, y or 0, z or 0}
        setmetatable(ang, a_meta)
        return ang
    end
end