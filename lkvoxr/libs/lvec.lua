--[[
    lvec.lua

    Lokachop's
    Vector
    Library

    coded by Lokachop, contact @ Lokachop#5862, lokachop or lokachop@gmail.com
    licensed under the MIT license (refer to LICENSE)
]]--

LVEC = LVEC or {}

local math = math
local math_sqrt = math.sqrt
local math_cos = math.cos
local math_sin = math.sin

local _rotMatrixCalc = LMAT.Matrix()
local _pattForm = "%4.2f, %4.2f, %4.2f, %4.2f"
local v_meta = {
    -- math
    ["__add"] = function(x, y)
        return LVEC.Vector(x[1] + y[1], x[2] + y[2], x[3] + y[3])
    end,
    ["__sub"] = function(x, y)
        return LVEC.Vector(x[1] - y[1], x[2] - y[2], x[3] - y[3])
    end,
    ["__mul"] = function(x, y)
        if tonumber(y) ~= nil then
            return LVEC.Vector(x[1] * y, x[2] * y, x[3] * y)
        elseif y.ismatrix then
            local vx = (y[ 1] * x[1]) + (y[ 2] * x[2]) + (y[ 3] * x[3]) + (y[ 4] * x[4])
            local vy = (y[ 5] * x[1]) + (y[ 6] * x[2]) + (y[ 7] * x[3]) + (y[ 8] * x[4])
            local vz = (y[ 9] * x[1]) + (y[10] * x[2]) + (y[11] * x[3]) + (y[12] * x[4])
            local vw = (y[13] * x[1]) + (y[14] * x[2]) + (y[15] * x[3]) + (y[16] * x[4])


            --[[
            if vw ~= 1 then
                vx = vx
                vy = vy
                vz = vz
            end
            ]]--

            return LVEC.Vector(vx, vy, vz, vw)
        else
            return LVEC.Vector(x[1] * y[1], x[2] * y[2], x[3] * y[3])
        end
    end,
    ["__div"] = function(x, y)
        return LVEC.Vector(x[1] / y[1], x[2] / y[2], x[3] / y[3])
    end,
    ["__pow"] = function(x, y)
        if tonumber(y) ~= nil then
            return LVEC.Vector(x[1] ^ y, x[2] ^ y, x[3] ^ y)
        else
            return LVEC.Vector(x[1] ^ y[1], x[2] ^ y[2], x[3] ^ y[3])
        end
    end,
    ["__unm"] = function(x, y)
        return LVEC.Vector(-x[1], -x[2], -x[3])
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
    ["__name"] = "Vector",


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
    ["MulV"] = function(x, y)
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
    ["DivV"] = function(x, y)
        x[1] = x[1] / y[1]
        x[2] = x[2] / y[2]
        x[3] = x[3] / y[3]
    end,
    ["Length"] = function(x)
        return math_sqrt(x[1] ^ 2 + x[2] ^ 2 + x[3] ^ 2)
    end,
    ["Dot"] = function(x, y)
        return x[1] * y[1] + x[2] * y[2] + x[3] * y[3]
    end,
    ["Normalize"] = function(x)
        local l = math_sqrt(x[1] ^ 2 + x[2] ^ 2 + x[3] ^ 2)
        x[1] = x[1] / l
        x[2] = x[2] / l
        x[3] = x[3] / l
    end,
    ["GetNormalized"] = function(x)
        local l = math_sqrt(x[1] ^ 2 + x[2] ^ 2 + x[3] ^ 2)
        return LVEC.Vector(x[1] / l, x[2] / l, x[3] / l)
    end,
    ["Cross"] = function(x, y)
        return LVEC.Vector(
            x[2] * y[3] - x[3] * y[2],
            x[3] * y[1] - x[1] * y[3],
            x[1] * y[2] - x[2] * y[1]
        )
    end,
    ["Neg"] = function(x)
        x[1] = -x[1]
        x[2] = -x[2]
        x[3] = -x[3]
    end,

    ["Rotate"] = function(x, y)
        _rotMatrixCalc:Identity()
        _rotMatrixCalc:SetAngles(y)

        local mr = x:Copy() * _rotMatrixCalc
        x[1] = mr[1]
        x[2] = mr[2]
        x[3] = mr[3]
    end,
    ["Copy"] = function(x)
        return LVEC.Vector(x[1], x[2], x[3], x[4])
    end,

    -- rotations
    -- tacky until i do proper matrices
    ["Right"] = function(x)
        _rotMatrixCalc:Identity()
        _rotMatrixCalc:SetAngles(x)

        return LVEC.Vector(_rotMatrixCalc[1], _rotMatrixCalc[2], _rotMatrixCalc[3])
    end,
    ["Up"] = function(x)
        _rotMatrixCalc:Identity()
        _rotMatrixCalc:SetAngles(x)

        return LVEC.Vector(-_rotMatrixCalc[5], -_rotMatrixCalc[6], -_rotMatrixCalc[7])
    end,
    ["Forward"] = function(x)
        _rotMatrixCalc:Identity()
        _rotMatrixCalc:SetAngles(x)

        return LVEC.Vector(_rotMatrixCalc[9], _rotMatrixCalc[10], _rotMatrixCalc[11])
    end,
    ["isvec"] = true
}

v_meta.__index = v_meta


function LVEC.Vector(x, y, z, w)
    if tonumber(x) == nil then
        local v = {x[1] or 0, x[2] or 0, x[3] or 0, x[4] or 1} -- w is matrix only currently
        setmetatable(v, v_meta)
        return v
    else
        local v = {x or 0, y or 0, z or 0, w or 1}
        setmetatable(v, v_meta)
        return v
    end
end