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
		DirTbl[y] = {}
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

local SIDE_X = 0
local SIDE_Y = 1
local SIDE_Z = 2

-- 3d adaptation of https://lodev.org/cgtutor/raycasting.html
function LKVoxR.RaycastWorld(pos, dir)
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


local _up = Vector(0, 1, 0)
local _halfSteps = (LKVOXR_TRACE_STEPS * .75)
local function lerp(t, a, b)
	return a * (1 - t) + b * t
end

local doShadows = LKVOXR_DO_SHADOWS
local sunDirTest = Vector(5, 3, 2)
sunDirTest:Normalize()

local fID = 0
function LKVoxR.RenderActiveUniverse()
	fID = fID + 1
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

		local camPos = LKVoxR.CamPos
		local hit, side, dist, hitPos, hitNormal, voxID, mapPos, ddx, ddy, ddz = LKVoxR.RaycastWorld(camPos, dirGet)

		if hit then
			local voxNfo = LKVoxR.GetVoxelInfoFromID(voxID)

			local tex = LKTEX.Textures[voxNfo.tex]
			local tdata = tex.data
			local tw, th = tdata[1], tdata[2]

			local distDiv = dist / _halfSteps

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
				local shadowHit = LKVoxR.RaycastWorld(hitPos + (hitNormal * 0.001), sunDirTest)
				if shadowHit then
					rc = rc * .5
					gc = gc * .5
					bc = bc * .5
				end
			end

			local lerpR = lerp(distDiv, rc, 0)
			local lerpG = lerp(distDiv, gc, 0)
			local lerpB = lerp(distDiv, bc, 0)


			drawPixel(lerpR, lerpG, lerpB, xc, yc)
		else
			--drawPixel(r, g, b, xc, yc)
			local dotVal = dirGet:Dot(_up)
			drawPixel(32 + dotVal * 64, 48 + dotVal * 96, 64 + dotVal * 128, xc, yc)

			--drawPixel((dirGet[1] + 1) * 128, (dirGet[2] + 1) * 128, (dirGet[3] + 1) * 128, xc, yc)
		end

		::_contRender::
	end
end