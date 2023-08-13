LKVoxR = LKVoxR or {}
LKVoxR.Voxels = LKVoxR.Voxels or {}

local name_to_id_lut = {}
local id_to_name_lut = {}

-- TODO: voxel types
local last_id = 0
function LKVoxR.NewVoxel(name, parametri)
    last_id = last_id + 1

    parametri.id = last_id
    parametri.name = name
    LKVoxR.Voxels[last_id] = parametri

    name_to_id_lut[name] = last_id
    id_to_name_lut[last_id] = name
end

function LKVoxR.VoxelNameToID(name)
    return name_to_id_lut[name]
end

function LKVoxR.VoxelIDToName(id)
    return id_to_name_lut[id]
end

function LKVoxR.GetVoxelInfoFromID(id)
    return LKVoxR.Voxels[id]
end


LKVoxR.NewVoxel("test1", {
    tex = "jelly",
    solid = true,
})

LKVoxR.NewVoxel("test2", {
    tex = "loka",
    solid = true,
})

LKVoxR.NewVoxel("test3", {
    tex = "mandrill",
    solid = true,
})


LKVoxR.NewVoxel("test4", {
    tex = "jet",
    solid = true,
})