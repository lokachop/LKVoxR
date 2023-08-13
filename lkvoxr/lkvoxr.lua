LKVoxR = LKVoxR or {}




local relaPath = "lkvoxr/"
function LKVoxR.LoadFile(path)
    require(relaPath .. path)
end

LKVoxR.LoadFile("libs/lmat") -- make sure to load lmat first
LKVoxR.LoadFile("libs/lvec")
LKVoxR.LoadFile("libs/lang")
LKVoxR.LoadFile("libs/lknoise")
LKVoxR.LoadFile("libs/lktex") -- TODO: lktex isn't a full lib still...

if (not Vector) or (not Matrix) or (not Angle) then -- hack hack
    Vector = LVEC.Vector
    Matrix = LMAT.Matrix
    Angle  = LANG.Angle
end

LKVoxR.LoadFile("consts")
LKVoxR.LoadFile("camera")
LKVoxR.LoadFile("voxels")
LKVoxR.LoadFile("worldutils")
LKVoxR.LoadFile("universes")
LKVoxR.LoadFile("rendervoxel")