LKVoxR = LKVoxR or {}
LKVoxR.UniverseRegistry = LKVoxR.UniverseRegistry or {}

function LKVoxR.NewUniverse(tag)
    if not tag then
        error("Attempt to make world without a tag!")
    end


    local worldData = {
        ["chunks"] = {},
        ["tag"] = tag
    }

    local mapS = 4
    for x = -mapS, mapS do
        for y = -mapS, mapS do
            print("gen chunk; " .. x .. ", 0, " .. y)
            worldData["chunks"][LKVoxR.ChunkHash(x, 0, y)] = LKVoxR.NewChunk(x, 0, y)
        end
    end

    print("new world, \"" .. tag .. "\"")
    LKVoxR.UniverseRegistry[tag] = worldData

    return LKVoxR.UniverseRegistry[tag]
end

LKVoxR.BaseUniv = {
        ["chunks"] = {},
        ["tag"] = "lkvoxr_base"
    }

LKVoxR.CurrUniv = LKVoxR.BaseUniv
LKVoxR.UniverseStack = LKVoxR.UniverseStack or {}

function LKVoxR.PushUniverse(univ)
    LKVoxR.UniverseStack[#LKVoxR.UniverseStack + 1] = LKVoxR.CurrUniv
    LKVoxR.CurrUniv = univ
end

function LKVoxR.PopUniverse(univ)
    LKVoxR.CurrUniv = LKVoxR.UniverseStack[#LKVoxR.UniverseStack] or LKVoxR.BaseUniv
    LKVoxR.UniverseStack[#LKVoxR.UniverseStack] = nil
end