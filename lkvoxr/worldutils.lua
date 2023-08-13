LKVoxR = LKVoxR or {}


function LKVoxR.WorldGen(x, y, z)
    local vxc = x / 32
    local vzc = z / 32
    local spxVal = ((LKNoise.Simplex.simplex2D(vxc, vzc) + 1) / 4)

    local tadd = 32
    local valCheck = (spxVal * 8) + tadd
    if y < valCheck then
        local xs = x / 16
        local ys = y / 16
        local zs = z / 16

        local worl = LKNoise.Worley.worley3D(xs, ys, zs)

        if worl > .5 then
            local isRoof = (y + 1) > valCheck
            if isRoof then
                local xs2 = x / 16
                local ys2 = z / 16

                local noiseSpx = LKNoise.Simplex.simplex2D(xs2, ys2)
                if noiseSpx > 0 then
                    return 2
                else
                    return 4
                end
            end

            return 1
        else
            return 0
        end
    else
        return 0
    end
end


function LKVoxR.NewChunk(cx, cy, cz)
    local chunkData = {}

    for i = 0, (LKVOXR_CX_P * LKVOXR_CY_P * LKVOXR_CZ_P) - 1 do
        local xc = (i % LKVOXR_CX_P)
        local yc = math.floor(i / LKVOXR_CX_P) % LKVOXR_CY_P
        local zc = math.floor(math.floor(i / LKVOXR_CX_P) / LKVOXR_CY_P) % LKVOXR_CZ_P


        chunkData[i] = LKVoxR.WorldGen(xc + (cx * LKVOXR_CX_P), yc + (cy * LKVOXR_CY_P), zc + (cz * LKVOXR_CZ_P))
    end

    return chunkData
end

local tblConcat = {
    [1] = "x",
    [3] = "y",
    [5] = "z"
}
function LKVoxR.ChunkHash(cx, cy, cz)
    tblConcat[2] = cx
    tblConcat[4] = cy
    tblConcat[6] = cz

    return table.concat(tblConcat, "")
end

function LKVoxR.IndexFromCoords(x, y, z)
    return x + (y * LKVOXR_CX_P) + (z * LKVOXR_CX_P * LKVOXR_CY_P)
end

function LKVoxR.WorldToChunkBlock(x, y, z)
    local xc = math.floor(x % LKVOXR_CX_P)
    local yc = math.floor(y % LKVOXR_CY_P)
    local zc = math.floor(z % LKVOXR_CZ_P)

    return xc, yc, zc
end

function LKVoxR.WorldToChunkIndex(x, y, z)
    local xc = math.floor(x / LKVOXR_CX_P)
    local yc = math.floor(y / LKVOXR_CY_P)
    local zc = math.floor(z / LKVOXR_CZ_P)

    return xc, yc, zc
end

function LKVoxR.WorldToChunkHash(x, y, z)
    tblConcat[2] = math.floor(x / LKVOXR_CX_P)
    tblConcat[4] = math.floor(y / LKVOXR_CY_P)
    tblConcat[6] = math.floor(z / LKVOXR_CZ_P)

    return table.concat(tblConcat, "")
end


function LKVoxR.GetWorldContents(x, y, z)
    local cx, cy, cz = LKVoxR.WorldToChunkIndex(x, y, z)
    local hash = LKVoxR.ChunkHash(cx, cy, cz)

    local theChunk = LKVoxR.CurrUniv["chunks"][hash]
    if not theChunk then
        return
    end

    local bx, by, bz = LKVoxR.WorldToChunkBlock(x, y, z)
    local bInd = LKVoxR.IndexFromCoords(bx, by, bz)

    return theChunk[bInd]
end

function LKVoxR.SetWorldContents(x, y, z, to)
    local cx, cy, cz = LKVoxR.WorldToChunkIndex(x, y, z)
    local hash = LKVoxR.ChunkHash(cx, cy, cz)

    local theChunk = LKVoxR.CurrUniv["chunks"][hash]
    if not theChunk then
        return
    end

    local bx, by, bz = LKVoxR.WorldToChunkBlock(x, y, z)
    local bInd = LKVoxR.IndexFromCoords(bx, by, bz)

    theChunk[bInd] = to
end
