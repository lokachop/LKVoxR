LKVoxR = LKVoxR or {}
--[[
	writeup for tomorrow
	each chunk will store its contents
	and they get updated each time theres a block update
	we send to the gpu a list of chunk content textures and the chunk origins for the things we want to render
	this should be fast AND nice

]]--


LKVoxR._loveShader = love.graphics.newShader(LKVoxR.RelaPath .. "/shader/voxel.frag")
LKVoxR._loveCanvas = love.graphics.newCanvas(LKVOXR_RENDER_RES_X, LKVOXR_RENDER_RES_Y)


--[[
	tree packing algo from https://blackpawn.com/texts/lightmaps/default.html
]]--
local atlas_wPad = 4
local atlas_hPad = 4
local atlas_size = 128


local function newleaf(sx, sy, ox, oy)
	return {
		children = {},
		ox = ox or 0,
		oy = oy or 0,
		sx = sx,
		sy = sy,
		has_tex = false,
	}
end

local function tex_size(tex)
	local tData = tex.data

	local texW = tData[1]
	local texH = tData[2]

	return texW + atlas_wPad, texH + atlas_hPad
end

local function insert_into_leaf(leaf, rect)
	if (#leaf.children > 0) then
		local new_pos = insert_into_leaf(leaf.children[1], rect)
		if new_pos ~= nil then
			return new_pos
		end

		-- no room, insert second
		return insert_into_leaf(leaf.children[2], rect)
	else
		if leaf.has_tex then
			return
		end

		local rectw, recth = tex_size(rect)

		if leaf.sx < rectw or leaf.sy < recth then
			return
		end

		if leaf.sx == rectw and leaf.sy == recth then
			leaf.has_tex = true
			return {leaf.ox, leaf.oy}
		end


		-- we have to split
		local dw = leaf.sx - rectw
		local dh = leaf.sy - recth


		if dw > dh then -- if (the leafsize - rectw) > (the leafsize - recth)
			leaf.children[1] = newleaf( -- left, stores og lightmap
				rectw,
				leaf.sy,
				leaf.ox,
				leaf.oy
			)
			leaf.children[2] = newleaf( -- right
				dw,
				leaf.sy,
				leaf.ox + rectw,
				leaf.oy
			)
		else
			leaf.children[1] = newleaf( -- up, stores lightmap
				leaf.sx,
				recth,
				leaf.ox,
				leaf.oy
			)
			leaf.children[2] = newleaf( -- down
				leaf.sx,
				dh,
				leaf.ox,
				leaf.oy + recth
			)
		end


		return insert_into_leaf(leaf.children[1], rect)
	end
end


local function renderImageData(tex, ox, oy)
	local tData = tex.data

	local texW = tData[1]
	local texH = tData[2]

	for i = 0, (texW * texH) - 1 do
		local xc = i % texW
		local yc = math.floor(i / texW)

		local cont = tex[i]

		love.graphics.setColor(cont[1] / 255, cont[2] / 255, cont[3] / 255)
		love.graphics.rectangle("fill", xc + ox, yc + oy, 1, 1)
	end

end

local _textureIndices = {}
local _textureIndicesName = {}
local _textureAtlasOffsets = {}
local _textureAtlasSizes = {}
function LKVoxR.GenerateTextureAtlas()
	local texCount = 0
	for k, v in ipairs(LKTEX.Textures) do
		texCount = texCount + 1
		print("T: " .. LKTEX.GetNameByIndex(k) .. " = " .. texCount)

		_textureIndices[texCount] = k
		_textureIndicesName[LKTEX.GetNameByIndex(k)] = texCount
	end

	print(texCount .. " textures...")

	LKVoxR._loveTexAtlas = love.graphics.newCanvas(atlas_size, atlas_size)
	LKVoxR._loveTexAtlas:setFilter("nearest", "nearest", 0)

	local tree = newleaf(atlas_size, atlas_size)
	tree.children[1] = newleaf(atlas_size, atlas_size)
	tree.children[2] = newleaf(0, 0)

	love.graphics.setCanvas(LKVoxR._loveTexAtlas)
	love.graphics.clear(1, 0, 0)

	for i = 1, texCount do
		local tex = LKTEX.GetByIndex(_textureIndices[i])
		local ret = insert_into_leaf(tree, tex)

		if not ret then
			error("Atlas creation fail (atlas_size too small?)")
			break
		end
		local texData = tex.data

		local ox, oy = ret[1], ret[2]
		_textureAtlasOffsets[i] = {ox, oy}
		_textureAtlasSizes[i] = {texData[1], texData[2]}

		renderImageData(tex, ox, oy)
	end

	love.graphics.setCanvas()
end


function LKVoxR.RenderAtlasDebug()
	local scl = 1
	love.graphics.draw(LKVoxR._loveTexAtlas, 0, 0, 0, scl)
end


local _voxelTextureIndices = {}
local _voxelAtlasOffsets = {}
local _voxelAtlasSizes = {}
function LKVoxR.GenerateVoxelTextureIndices()
	for i = 1, LKVoxR.GetVoxelCount() do
		local vox = LKVoxR.Voxels[i]
		local texInd = _textureIndicesName[vox.tex]
		print("[" .. vox.name .. "]: " .. vox.tex .. ": " .. LKTEX.GetNameByIndex(texInd))

		local ioff = _textureAtlasOffsets[texInd]
		local isiz = _textureAtlasSizes[texInd]
		_voxelAtlasOffsets[i] = {ioff[1], ioff[2]}
		_voxelAtlasSizes[i] = {isiz[1], isiz[2]}
	end
end

LKVoxR.GenerateTextureAtlas()
LKVoxR.GenerateVoxelTextureIndices()


local _lastW = 0
local _lastH = 0
local function updateCanvas()
	LKVoxR._loveCanvas = love.graphics.newCanvas(LKVOXR_RENDER_RES_X, LKVOXR_RENDER_RES_Y)
	LKVoxR._loveCanvas:setFilter("nearest", "nearest", 0)

	_lastW = LKVOXR_RENDER_RES_X
	_lastH = LKVOXR_RENDER_RES_Y
end


local function sendIfExist(name, ...)
	if LKVoxR._loveShader:hasUniform(name) then
		LKVoxR._loveShader:send(name, ...)
	end
end

local function updateChunkLists()
	local listChunks = {}
	local chunkOrigins = {}

	local ind = 1
	local camPos = LKVoxR.CamPos * 1


	for x = -LKVOXR_CRAD_X, LKVOXR_CRAD_X - 1 do
		for z = -LKVOXR_CRAD_Z, LKVOXR_CRAD_Z - 1 do
			local cx = math.floor(camPos[1] + (x * LKVOXR_CX_P))
			local cy = math.floor(camPos[2])
			local cz = math.floor(camPos[3] + (z * LKVOXR_CZ_P))


			local chunkCurr = LKVoxR.GetWorldChunk(cx, cy, cz)
			if not chunkCurr then
				goto _contSend
			end

			if not chunkCurr._volMap then
				goto _contSend
			end


			local ox, oy, oz = LKVoxR.GetWorldChunkOrigin(cx, cy, cz)
			listChunks[ind] = chunkCurr._volMap
			chunkOrigins[ind] = {ox, oy, oz}
			ind = ind + 1

			::_contSend::
		end
	end

	sendIfExist("chunkOrigins", unpack(chunkOrigins))
	sendIfExist("chunkList", unpack(listChunks))
	sendIfExist("chunkCount", ind - 1)
	sendIfExist("chunkSize", {LKVOXR_CHUNK_X, LKVOXR_CHUNK_Y, LKVOXR_CHUNK_Z})
	sendIfExist("chunkSizeLarge", {LKVOXR_CX_P, LKVOXR_CY_P, LKVOXR_CZ_P})
end



local cloudSz = 512
local canvasClouds = love.graphics.newCanvas(cloudSz, cloudSz)
canvasClouds:setWrap("mirroredrepeat")
local function initializeCloudTexture()
	-- use noise to gen it
	local _oldCanvas = love.graphics.getCanvas()
	local _oldShader = love.graphics.getShader()

	love.graphics.setShader()
	love.graphics.setCanvas(canvasClouds)
	for i = 0, (cloudSz * cloudSz) - 1 do
		local xc = i % cloudSz
		local yc = math.floor(i / cloudSz)

		local xd = xc / cloudSz
		local yd = yc / cloudSz

		local spxVal1 = (LKNoise.Simplex.simplex2D(xd * 1, yd * 1) + 1) * .5
		local spxVal2 = (LKNoise.Simplex.simplex2D(xd * 4, yd * 4) + 1) * .5
		local spxVal3 = (LKNoise.Simplex.simplex2D(xd * 6, yd * 6) + 1) * .5

		local colVal = (spxVal1 * .85) + (spxVal2 * .10) + (spxVal3 * .5)

		love.graphics.setColor(colVal, colVal, colVal, 1)
		love.graphics.rectangle("fill", xc, yc, 1, 1)
	end
	love.graphics.setCanvas(_oldCanvas)
	love.graphics.setShader(_oldShader)
end


function LKVoxR.DrawCloudCanvasTest()
	local scl = 1
	love.graphics.draw(canvasClouds, 0, 0, 0, scl)
end

local function initializeConfigs()
	sendIfExist("steps", LKVOXR_TRACE_STEPS)

	sendIfExist("doFog", LKVOXR_DO_FOG)
	sendIfExist("fogColour", {LKVOXR_FOG_COLOUR[1] / 255, LKVOXR_FOG_COLOUR[2] / 255, LKVOXR_FOG_COLOUR[3] / 255})

	sendIfExist("doBlockShade", LKVOXR_DO_BLOCK_SHADE)
	sendIfExist("blockShadeList", 1, LKVOXR_SIDE_MULS[1], LKVOXR_SIDE_MULS[2], LKVOXR_SIDE_MULS[3])

	sendIfExist("doShadows", LKVOXR_DO_SHADOWS)
	sendIfExist("shadowDir", LKVOXR_SUN_DIR)
end



local _uniformInit = false
local function initializeUniforms()
	local w, h = love.graphics.getDimensions()
	sendIfExist("screenSize", {w, h})
	sendIfExist("camFOV", LKVOXR_FOV)

	sendIfExist("texAtlasUVs", unpack(_voxelAtlasOffsets))
	sendIfExist("texAtlasSize", {atlas_size, atlas_size})
	sendIfExist("texAtlasSizes", unpack(_voxelAtlasSizes))
	sendIfExist("texAtlas", LKVoxR._loveTexAtlas)

	initializeCloudTexture()
	sendIfExist("texCloud", canvasClouds)
	sendIfExist("texCloudSz", cloudSz)

	initializeConfigs()

	_uniformInit = true
end






local _uniformInitTex = false
function LKVoxR.RenderActiveUniverse()
	if _lastW ~= LKVOXR_RENDER_RES_X or _lastH ~= LKVOXR_RENDER_RES_Y then
		updateCanvas()
	end

	local eyeDir = Vector(1, 0, 0)
	eyeDir:Rotate(LKVoxR.CamAngZ)
	eyeDir:Rotate(LKVoxR.CamAngY)


	local camPos = LKVoxR.CamPos * 1

	local oldCanvas = love.graphics.getCanvas()
	love.graphics.setCanvas(LKVoxR._loveCanvas)
	love.graphics.setShader(LKVoxR._loveShader)
	if not _uniformInit then
		initializeUniforms()
	end
	sendIfExist("time", CurTime)


	sendIfExist("camPos", {camPos[1], camPos[2], camPos[3]})
	sendIfExist("camLookAt", {camPos[1] + eyeDir[1], camPos[2] + eyeDir[2], camPos[3] + eyeDir[3]})
	sendIfExist("screenSize", {LKVOXR_RENDER_RES_X, LKVOXR_RENDER_RES_Y})

	updateChunkLists()

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle("fill", 0, 0, LKVOXR_RENDER_RES_X, LKVOXR_RENDER_RES_Y)
	love.graphics.setShader()
	love.graphics.setCanvas(oldCanvas)


	local w, h = love.graphics.getDimensions()
	local wRatio, hRatio = w / LKVOXR_RENDER_RES_X, h / LKVOXR_RENDER_RES_Y

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(LKVoxR._loveCanvas, 0, 0, 0, wRatio, hRatio)
end