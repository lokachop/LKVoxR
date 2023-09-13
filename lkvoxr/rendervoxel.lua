LKVoxR = LKVoxR or {}

local math = math
local math_floor = math.floor
local math_abs = math.abs


local DirTbl = {}
-- from https://www.youtube.com/watch?v=YSOBCp2mito
local function calculateForward()
	local wDiv = LKVOXR_RENDER_RES_X
	local hDiv = LKVOXR_RENDER_RES_Y

	for y = 0, hDiv do
		if not DirTbl[y] then
			DirTbl[y] = {}
		end


		for x = 0, wDiv do
			local coeff = math.tan((LKVOXR_FOV / 2) * (3.1416 / 180)) * 2.71828;
			DirTbl[y][x] = Vector(
				1,
				((wDiv - x) / (wDiv - 1) - 0.5) * coeff,
				(coeff / wDiv) * (hDiv - y) - 0.5 * (coeff / wDiv) * (hDiv - 1)
			):GetNormalized()
		end
	end

	print("Calculated forward table!")
end
calculateForward()

function LKVoxR.GetScreenDirTable()
	return DirTbl
end

-- OVERRIDE: change to appropiate call
local sw, sh = love.graphics.getDimensions()
local drawW, drawH = sw / LKVOXR_RENDER_RES_X, sh / LKVOXR_RENDER_RES_Y

local function drawPixel(r, g, b, x, y)
	love.graphics.setColor(r / 255, g / 255, b / 255)
	love.graphics.rectangle("fill", x * drawW, y * drawH, drawW, drawH)
end

-- TODO: move to a util file...
function LKVoxR.ScreenToWorldDir(x, y)
	-- transform to the small viewport
	local xc = math.floor(x / drawW)
	local yc = math.floor(y / drawH)


	local dirGet = DirTbl[xc][yc]:Copy()
	dirGet:Rotate(LKVoxR.CamAngZ)
	dirGet:Rotate(LKVoxR.CamAngY)

	return dirGet
end

function LKVoxR.ChangeResolution(newW, newH)
	LKVOXR_RENDER_RES_X = newW
	LKVOXR_RENDER_RES_Y = newH
	drawW, drawH = sw / LKVOXR_RENDER_RES_X, sh / LKVOXR_RENDER_RES_Y
	calculateForward()
end

local SIDE_X = 1
local SIDE_Y = 2
local SIDE_Z = 3

local tblConcatHash = {
	[1] = "x",
	[3] = "y",
	[5] = "z"
}

local cx_m_cy = LKVOXR_CX_P * LKVOXR_CY_P
-- 3d adaptation of https://lodev.org/cgtutor/raycasting.html
local function raycastRender(pos, posMap, dir)
	local posX = pos[1]
	local posY = pos[2]
	local posZ = pos[3]

	local mapX = posMap[1]
	local mapY = posMap[2]
	local mapZ = posMap[3]

	local rayDirX = dir[1]
	local rayDirY = dir[2]
	local rayDirZ = dir[3]

	local sideDistX = 0
	local sideDistY = 0
	local sideDistZ = 0

	local deltaDistX = math_abs(1 / rayDirX)
	--local deltaDistX = (1 / rayDirX)
	--deltaDistX = deltaDistX < 0 and -deltaDistX or deltaDistX

	local deltaDistY = math_abs(1 / rayDirY)
	--local deltaDistY = (1 / rayDirY)
	--deltaDistY = deltaDistY < 0 and -deltaDistY or deltaDistY

	local deltaDistZ = math_abs(1 / rayDirZ)
	--local deltaDistZ = (1 / rayDirZ)
	--deltaDistZ = deltaDistZ < 0 and -deltaDistZ or deltaDistZ

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
	for i = 1, LKVOXR_TRACE_STEPS do
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

		tblConcatHash[2] = math_floor(mapX / LKVOXR_CX_P)
		tblConcatHash[4] = math_floor(mapY / LKVOXR_CY_P)
		tblConcatHash[6] = math_floor(mapZ / LKVOXR_CZ_P)

		local chunkHash = table.concat(tblConcatHash, "")
		--local chunkHash = LKVoxR.WorldToChunkHash(mapX, mapY, mapZ)
		local chunkContent = LKVoxR.CurrUniv["chunks"][chunkHash]
		if not chunkContent then
			goto _contRc
		end

		--local cbX, cbY, cbZ = LKVoxR.WorldToChunkBlock(mapX, mapY, mapZ)
		local cbX = mapX % LKVOXR_CX_P
		local cbY = mapY % LKVOXR_CY_P
		local cbZ = mapZ % LKVOXR_CZ_P

		--local bInd = LKVoxR.IndexFromCoords(cbX, cbY, cbZ)
		local bInd = cbX + (cbY * LKVOXR_CX_P) + (cbZ * cx_m_cy)

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

	local perpWallDist = 0
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

	local posHit = (dir * perpWallDist)
	posHit:Add(pos)
	--local posHit = pos + (dir * perpWallDist)

	return hit, side, perpWallDist, posHit, normal, voxID
end


local _up = Vector(0, 1, 0)
local _halfSteps = (LKVOXR_TRACE_STEPS * .7)
local function lerp(t, a, b)
	return a * (1 - t) + b * t
end

local doShadows = LKVOXR_DO_SHADOWS
local sunDir = LKVOXR_SUN_DIR


local sideMuls = LKVOXR_SIDE_MULS

local doFog = LKVOXR_DO_FOG
local fogCr, fogCg, fogCb = LKVOXR_FOG_COLOUR[1], LKVOXR_FOG_COLOUR[2], LKVOXR_FOG_COLOUR[3]
local fID = 0
function LKVoxR.RenderActiveUniverse()
	fID = fID + 1

	local camPos = LKVoxR.CamPos
	local camMap = LKVoxR.CamPos:Copy()
	camMap[1] = math.floor(camMap[1])
	camMap[2] = math.floor(camMap[2])
	camMap[3] = math.floor(camMap[3])

	for i = 0, (LKVOXR_RENDER_RES_X * LKVOXR_RENDER_RES_Y) do
		local xc = i % LKVOXR_RENDER_RES_X
		local yc = math.floor(i / LKVOXR_RENDER_RES_X)

		if (((xc + yc) + fID) % 2) == 0 then
			goto _contRender
		end

		local dirGet = DirTbl[xc][yc]:Copy()
		dirGet:Rotate(LKVoxR.CamAngZ)
		dirGet:Rotate(LKVoxR.CamAngY)

		local currUniv = LKVoxR.CurrUniv
		if not currUniv then
			return
		end

		local hit, side, dist, hitPos, hitNormal, voxID = raycastRender(camPos, camMap:Copy(), dirGet)

		if hit then
			local voxNfo = LKVoxR.GetVoxelInfoFromID(voxID)
			local tex = LKTEX.GetByName(voxNfo.tex)

			--print(voxNfo.name, voxNfo.tex)


			local tdata = tex.data
			local tw, th = tdata[1], tdata[2]

			local distDiv = math.min(dist / _halfSteps, 1)


			local tx = (hitPos[1] % 1)
			local ty = (hitPos[2] % 1)
			local tz = (hitPos[3] % 1)

			local rc, gc, bc = 32, 64, 96
			local tgx, tgy = 1, 1
			if side == SIDE_X then
				tgx = math_floor(tz * tw)
				tgy = math_floor((1 - ty) * th)
			elseif side == SIDE_Y then
				tgx = math_floor(tx * tw)
				tgy = math_floor(tz * th)
			elseif side == SIDE_Z then
				tgx = math_floor(tx * tw)
				tgy = math_floor((1 - ty) * th)
			end

			local cont = tex[tgx + (tgy * tw)]
			if cont then
				rc = cont[1]
				gc = cont[2]
				bc = cont[3]
			end

			if doShadows then
				local shadowHit = LKVoxR.RaycastWorld(hitPos + (hitNormal * 0.001), sunDir)
				if shadowHit then
					rc = rc * .5
					gc = gc * .5
					bc = bc * .5
				end
			end

			if LKVOXR_DO_BLOCK_SHADE then
				local mul = sideMuls[side]
				rc = rc * mul
				gc = gc * mul
				bc = bc * mul
			end

			if doFog then
				rc = lerp(distDiv, rc, fogCr)
				gc = lerp(distDiv, gc, fogCg)
				bc = lerp(distDiv, bc, fogCb)
			end


			love.graphics.setColor(rc * .0039, gc * .0039, bc * .0039)
			love.graphics.rectangle("fill", xc * drawW, yc * drawH, drawW, drawH)
		else
			local dotVal = dirGet[2] + 1
			local colBR = 32 + dotVal * 64
			local colBG = 48 + dotVal * 96
			local colBB = 64 + dotVal * 128

			drawPixel(colBR, colBG, colBB, xc, yc)
		end

		::_contRender::
	end
end