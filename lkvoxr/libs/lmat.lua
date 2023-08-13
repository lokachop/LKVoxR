--[[
    lmat.lua

    Lokachop's
    Matrix
    Library

    coded by lokachop, contact @ Lokachop#5862, lokachop or lokachop@gmail.com

]]--

LMAT = LMAT or {}

local math = math
local math_sqrt = math.sqrt
local math_cos = math.cos
local math_sin = math.sin


local matcb = {}
local temp_r1, temp_r2, temp_r3
local mat_meta = {
    ["__add"] = function(x, y)
        return LMAT.Matrix(
            x[ 1] + y[ 1], x[ 2] + y[ 2], x[ 3] + y[ 3], x[ 4] + y[ 4],
            x[ 5] + y[ 5], x[ 6] + y[ 6], x[ 7] + y[ 7], x[ 8] + y[ 8],
            x[ 9] + y[ 9], x[10] + y[10], x[11] + y[11], x[12] + y[12],
            x[13] + y[13], x[14] + y[14], x[15] + y[15], x[16] + y[16]
        )
    end,
    ["__sub"] = function(x, y)
        return LMAT.Matrix(
            x[ 1] - y[ 1], x[ 2] - y[ 2], x[ 3] - y[ 3], x[ 4] - y[ 4],
            x[ 5] - y[ 5], x[ 6] - y[ 6], x[ 7] - y[ 7], x[ 8] - y[ 8],
            x[ 9] - y[ 9], x[10] - y[10], x[11] - y[11], x[12] - y[12],
            x[13] - y[13], x[14] - y[14], x[15] - y[15], x[16] - y[16]
        )
    end,
    ["__mul"] = function(x, y)
        if y == tonumber(y) then -- number
            return LMAT.Matrix(
                x[ 1] * y, x[ 2] * y, x[ 3] * y, x[ 4] * y,
                x[ 5] * y, x[ 6] * y, x[ 7] * y, x[ 8] * y,
                x[ 9] * y, x[10] * y, x[11] * y, x[12] * y,
                x[13] * y, x[14] * y, x[15] * y, x[16] * y
            )
        elseif y.isvec then -- vector
            return x -- unfinished
        else -- matrix or unknown
            return LMAT.Matrix(
                (x[ 1] * y[ 1]) + (x[ 2] * y[ 5]) + (x[ 3] * y[ 9]) + (x[ 4] * y[13]),
                (x[ 1] * y[ 2]) + (x[ 2] * y[ 6]) + (x[ 3] * y[10]) + (x[ 4] * y[14]),
                (x[ 1] * y[ 3]) + (x[ 2] * y[ 7]) + (x[ 3] * y[11]) + (x[ 4] * y[15]),
                (x[ 1] * y[ 4]) + (x[ 2] * y[ 8]) + (x[ 3] * y[12]) + (x[ 4] * y[16]),

                (x[ 5] * y[ 1]) + (x[ 6] * y[ 5]) + (x[ 7] * y[ 9]) + (x[ 8] * y[13]),
                (x[ 5] * y[ 2]) + (x[ 6] * y[ 6]) + (x[ 7] * y[10]) + (x[ 8] * y[14]),
                (x[ 5] * y[ 3]) + (x[ 6] * y[ 7]) + (x[ 7] * y[11]) + (x[ 8] * y[15]),
                (x[ 5] * y[ 4]) + (x[ 6] * y[ 8]) + (x[ 7] * y[12]) + (x[ 8] * y[16]),

                (x[ 9] * y[ 1]) + (x[10] * y[ 5]) + (x[11] * y[ 9]) + (x[12] * y[13]),
                (x[ 9] * y[ 2]) + (x[10] * y[ 6]) + (x[11] * y[10]) + (x[12] * y[14]),
                (x[ 9] * y[ 3]) + (x[10] * y[ 7]) + (x[11] * y[11]) + (x[12] * y[15]),
                (x[ 9] * y[ 4]) + (x[10] * y[ 8]) + (x[11] * y[12]) + (x[12] * y[16]),

                (x[13] * y[ 1]) + (x[14] * y[ 5]) + (x[15] * y[ 9]) + (x[16] * y[13]),
                (x[13] * y[ 2]) + (x[14] * y[ 6]) + (x[15] * y[10]) + (x[16] * y[14]),
                (x[13] * y[ 3]) + (x[14] * y[ 7]) + (x[15] * y[11]) + (x[16] * y[15]),
                (x[13] * y[ 4]) + (x[14] * y[ 8]) + (x[15] * y[12]) + (x[16] * y[16])
            )
        end
    end,



    -- warcrime
    -- str
    ["__tostring"] = function(x)
        matcb[ 1] = x[ 1] matcb[ 2] = ", " matcb[ 3] = x[ 2] matcb[ 4] = ", " matcb[ 5] = x[ 3] matcb[ 6] = ", " matcb[ 7] = x[ 4] matcb[ 8] = "\n"
        matcb[ 9] = x[ 5] matcb[10] = ", " matcb[11] = x[ 6] matcb[12] = ", " matcb[13] = x[ 7] matcb[14] = ", " matcb[15] = x[ 8] matcb[16] = "\n"
        matcb[17] = x[ 9] matcb[18] = ", " matcb[19] = x[10] matcb[20] = ", " matcb[21] = x[11] matcb[22] = ", " matcb[23] = x[12] matcb[24] = "\n"
        matcb[25] = x[13] matcb[26] = ", " matcb[27] = x[14] matcb[28] = ", " matcb[29] = x[15] matcb[30] = ", " matcb[31] = x[16] matcb[32] = "\n"
        return table.concat(matcb, "")
    end,

    ["__concat"] = function(x)
        matcb[ 1] = x[ 1] matcb[ 2] = ", " matcb[ 3] = x[ 2] matcb[ 4] = ", " matcb[ 5] = x[ 3] matcb[ 6] = ", " matcb[ 7] = x[ 4] matcb[ 8] = "\n"
        matcb[ 9] = x[ 5] matcb[10] = ", " matcb[11] = x[ 6] matcb[12] = ", " matcb[13] = x[ 7] matcb[14] = ", " matcb[15] = x[ 8] matcb[16] = "\n"
        matcb[17] = x[ 9] matcb[18] = ", " matcb[19] = x[10] matcb[20] = ", " matcb[21] = x[11] matcb[22] = ", " matcb[23] = x[12] matcb[24] = "\n"
        matcb[25] = x[13] matcb[26] = ", " matcb[27] = x[14] matcb[28] = ", " matcb[29] = x[15] matcb[30] = ", " matcb[31] = x[16] matcb[32] = "\n"
        return table.concat(matcb, "")
    end,

    ["__name"] = "Matrix",


    -- extras
    ["Set"] = function(x, a0, a1, a2, a3, b0, b1, b2, b3, c0, c1, c2, c3, d0, d1, d2, d3)
        x[ 1] = a0 or 1 x[ 2] = a1 or 0 x[ 3] = a2 or 0 x[ 4] = a3 or 0
        x[ 5] = b0 or 0 x[ 6] = b1 or 1 x[ 7] = b2 or 0 x[ 8] = b3 or 0
        x[ 9] = c0 or 0 x[10] = c1 or 0 x[11] = c2 or 1 x[12] = c3 or 0
        x[13] = d0 or 0 x[14] = d1 or 0 x[15] = d2 or 0 x[16] = d3 or 1
    end,

    ["Unpack"] = function(x)

    end,

    ["Copy"] = function(x)
        return LMAT.Matrix(
            x[ 1], x[ 2], x[ 3], x[ 4],
            x[ 5], x[ 6], x[ 7], x[ 8],
            x[ 9], x[10], x[11], x[12],
            x[13], x[14], x[15], x[16]
        )
    end,

    ["SetMatrix"] = function(x, y)
        x[ 1] = y[ 1] x[ 2] = y[ 2] x[ 3] = y[ 3] x[ 4] = y[ 4]
        x[ 5] = y[ 5] x[ 6] = y[ 6] x[ 7] = y[ 7] x[ 8] = y[ 8]
        x[ 9] = y[ 9] x[10] = y[10] x[11] = y[11] x[12] = y[12]
        x[13] = y[13] x[14] = y[14] x[15] = y[15] x[16] = y[16]
    end,

    ["Identity"] = function(x)
        x[ 1] = 1 x[ 2] = 0 x[ 3] = 0 x[ 4] = 0
        x[ 5] = 0 x[ 6] = 1 x[ 7] = 0 x[ 8] = 0
        x[ 9] = 0 x[10] = 0 x[11] = 1 x[12] = 0
        x[13] = 0 x[14] = 0 x[15] = 0 x[16] = 1
    end,

    ["SetAngles"] = function(x, y)
        local rx = math.rad(y[1])
        local ry = math.rad(y[2])
        local rz = math.rad(y[3])


        local c_rx, s_rx = math_cos(rx), math_sin(rx)
        local c_ry, s_ry = math_cos(ry), math_sin(ry)
        local c_rz, s_rz = math_cos(rz), math_sin(rz)

        temp_r1:Set(
            1,    0,    0, 0,
            0, c_rx, s_rx, 0,
            0,-s_rx, c_rx, 0,
            0,    0,    0, 1
        )

        temp_r2:Set(
            c_ry, 0,-s_ry, 0,
               0, 1,    0, 0,
            s_ry, 0, c_ry, 0,
               0, 0,    0, 1
        )

        temp_r3:Set(
             c_rz, s_rz, 0, 0,
            -s_rz, c_rz, 0, 0,
                0,    0, 1, 0,
                0,    0, 0, 1
        )

        local mul = temp_r1 * temp_r3 * temp_r2

        -- keep translation
        mul[ 4] = x[ 4]
        mul[ 8] = x[ 8]
        mul[12] = x[12]
        mul[16] = x[16]

        x:SetMatrix(mul)
    end,

    -- y is vec
    ["SetTranslation"] = function(x, y)
        x[ 4] = y[1]
        x[ 8] = y[2]
        x[12] = y[3]
        x[16] = y[4]
    end,

    ["SetScale"] = function(x, y)
        x[ 1] = y[1]
        x[ 6] = y[2]
        x[11] = y[3]
        x[16] = y[4]
    end,

    ["ismatrix"] = true
}
mat_meta.__index = mat_meta

function LMAT.Matrix(a0, a1, a2, a3, b0, b1, b2, b3, c0, c1, c2, c3, d0, d1, d2, d3)
    local mat = {
        a0 or 1, a1 or 0, a2 or 0, a3 or 0,
        b0 or 0, b1 or 1, b2 or 0, b3 or 0,
        c0 or 0, c1 or 0, c2 or 1, c3 or 0,
        d0 or 0, d1 or 0, d2 or 0, d3 or 1,
    }

    setmetatable(mat, mat_meta)

    return mat
end

temp_r1 = LMAT.Matrix()
temp_r2 = LMAT.Matrix()
temp_r3 = LMAT.Matrix()