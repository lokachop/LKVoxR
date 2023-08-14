LKVoxR = LKVoxR or {}
local math = math
local math_floor = math.floor
local math_abs = math.abs


function LKVoxR.WorldGen(x, y, z)
	if y == 0 then
		return 3
	end


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



local SIDE_X = 0
local SIDE_Y = 1
local SIDE_Z = 2

-- 3d adaptation of https://lodev.org/cgtutor/raycasting.html
function LKVoxR.RaycastWorld(pos, dir, steps)
	local posX = pos[1]
	local posY = pos[2]
	local posZ = pos[3]

	local mapX = math_floor(posX)
	local mapY = math_floor(posY)
	local mapZ = math_floor(posZ)

	local rayDirX = dir[1]
	local rayDirY = dir[2]
	local rayDirZ = dir[3]


	local sideDistX = 0
	local sideDistY = 0
	local sideDistZ = 0

	local deltaDistX = math_abs(1 / rayDirX)
	local deltaDistY = math_abs(1 / rayDirY)
	local deltaDistZ = math_abs(1 / rayDirZ)
	local perpWallDist = 0

	local stepX = 0
	local stepY = 0
	local stepZ = 0

	local hit = false
	local side = 0

	if rayDirX < 0 then
		stepX = -1
		sideDistX = (posX - mapX) * deltaDistX
	else
		stepX = 1
		sideDistX = (mapX + 1.0 - posX) * deltaDistX
	end

	if rayDirY < 0 then
		stepY = -1
		sideDistY = (posY - mapY) * deltaDistY
	else
		stepY = 1
		sideDistY = (mapY + 1.0 - posY) * deltaDistY
	end

	if rayDirZ < 0 then
		stepZ = -1
		sideDistZ = (posZ - mapZ) * deltaDistZ
	else
		stepZ = 1
		sideDistZ = (mapZ + 1.0 - posZ) * deltaDistZ
	end


	local voxID = 0
	for i = 1, (dist or LKVOXR_TRACE_STEPS) do
		if sideDistX < sideDistY then
			if sideDistX < sideDistZ then
				sideDistX = sideDistX + deltaDistX
				mapX = mapX + stepX
				side = SIDE_X
			else
				sideDistZ = sideDistZ + deltaDistZ
				mapZ = mapZ + stepZ
				side = SIDE_Z
			end
		else
			if sideDistY < sideDistZ then
				sideDistY = sideDistY + deltaDistY
				mapY = mapY + stepY
				side = SIDE_Y
			else
				sideDistZ = sideDistZ + deltaDistZ
				mapZ = mapZ + stepZ
				side = SIDE_Z
			end
		end

		-- TODO: refactor when 3d chunks
		if mapY > LKVOXR_MAX_Y or mapY < 0 then
			break
		end

		local chunkHash = LKVoxR.WorldToChunkHash(mapX, mapY, mapZ)
		local chunkContent = LKVoxR.CurrUniv["chunks"][chunkHash]
		if not chunkContent then
			goto _contRc
		end

		local cbX, cbY, cbZ = LKVoxR.WorldToChunkBlock(mapX, mapY, mapZ)
		local bInd = LKVoxR.IndexFromCoords(cbX, cbY, cbZ)

		local cont = chunkContent[bInd]
		if not cont then
			goto _contRc
		end

		if cont ~= 0 then
			voxID = cont
			hit = true
			break
		end

		::_contRc::
	end

	local normal = Vector(0, 0, 0)
	if side == SIDE_X then
		perpWallDist = sideDistX - deltaDistX
		normal[1] = -stepX
	elseif side == SIDE_Y then
		perpWallDist = sideDistY - deltaDistY
		normal[2] = -stepY
	else
		perpWallDist = sideDistZ - deltaDistZ
		normal[3] = -stepZ
	end

	local posHit = pos + (dir * perpWallDist)
	local mapPos = Vector(mapX, mapY, mapZ)

	return hit, side, perpWallDist, posHit, normal, voxID, mapPos
end