LKVoxR = LKVoxR or {}

LKVoxR._loveShader = love.graphics.newShader(LKVoxR.RelaPath .. "/shader/voxel.frag")
LKVoxR._loveCanvas = love.graphics.newCanvas(LKVOXR_RENDER_RES_X, LKVOXR_RENDER_RES_Y)

LKVoxR._canvasVolu = love.graphics.newCanvas(LKVOXR_SHADER_VOLTEX_X, LKVOXR_SHADER_VOLTEX_Y, LKVOXR_SHADER_VOLTEX_Z, {
	type = "volume",
	format = "normal",
	readable = true
})

LKVoxR._canvasVolu:setFilter("nearest", "nearest", 0)


local function updateLayer()


end




local _lastFX, _lastFY, _lastFZ
local function updateVolumeImage()
	local camPos = LKVoxR.CamPos
	local fx, fy, fz = math.floor(camPos[1]), math.floor(camPos[2]), math.floor(camPos[3])
	--[[
	if fx == _lastFX and fy == _lastFY and fz == _lastFZ then
		return
	end

	_lastFX = fx
	_lastFY = fy
	_lastFZ = fz
	]]--


	-- trace nearby
	for y = -LKVOXR_SHADER_RENDER_DIST, LKVOXR_SHADER_RENDER_DIST - 1 do
		local indLayer = (y + LKVOXR_SHADER_RENDER_DIST) + 1
		love.graphics.setCanvas(LKVoxR._canvasVolu, indLayer)

		for x = -LKVOXR_SHADER_RENDER_DIST, LKVOXR_SHADER_RENDER_DIST - 1 do
			for z = -LKVOXR_SHADER_RENDER_DIST, LKVOXR_SHADER_RENDER_DIST - 1 do
				local cont = LKVoxR.GetWorldContents(fx + x, fy + y, fz + z)
				if cont == nil then
					cont = 0
				end

				local div = LKVoxR.GetVoxelCount()

				love.graphics.setColor(cont / div, cont / div, cont / div)
				local xp = x + LKVOXR_SHADER_RENDER_DIST
				local zp = z + LKVOXR_SHADER_RENDER_DIST
				love.graphics.rectangle("fill", xp, (LKVOXR_SHADER_RENDER_DIST * 2) - zp, 1, 1)
			end
		end
	end

	love.graphics.setCanvas()
end


local _lastW = 0
local _lastH = 0
local function updateCanvas()
	LKVoxR._loveCanvas = love.graphics.newCanvas(LKVOXR_RENDER_RES_X, LKVOXR_RENDER_RES_Y)
	LKVoxR._loveCanvas:setFilter("nearest", "nearest", 0)

	_lastW = LKVOXR_RENDER_RES_X
	_lastH = LKVOXR_RENDER_RES_Y
end


local function sendIfExist(name, val)
	if LKVoxR._loveShader:hasUniform(name) then
		LKVoxR._loveShader:send(name, val)
	end
end

function LKVoxR.RenderActiveUniverseAccel()
	if _lastW ~= LKVOXR_RENDER_RES_X or _lastH ~= LKVOXR_RENDER_RES_Y then
		updateCanvas()
	end

	updateVolumeImage()

	local w, h = love.graphics.getDimensions()

	local eyeDir = Vector(1, 0, 0)
	eyeDir:Rotate(LKVoxR.CamAngZ)
	eyeDir:Rotate(LKVoxR.CamAngY)



	local camPos = LKVoxR.CamPos
	love.graphics.setShader(LKVoxR._loveShader)
	sendIfExist("camPos", {camPos[1], camPos[2], camPos[3]})
	sendIfExist("camLookAt", {camPos[1] + eyeDir[1], camPos[2] + eyeDir[2], camPos[3] + eyeDir[3]})
	--sendIfExist("camFOV", LKVOXR_FOV)
	sendIfExist("screenSize", {w, h})
	sendIfExist("chunkConts", LKVoxR._canvasVolu)
	sendIfExist("renderDistHalf", LKVOXR_SHADER_RENDER_DIST)
	sendIfExist("indTestAdd", .5)


	love.graphics.draw(LKVoxR._loveCanvas, 0, 0, 0, w, h)
	love.graphics.setShader()


	--[[
	for z = 1, (LKVOXR_SHADER_RENDER_DIST * 2) - 1 do
		local imgData = LKVoxR._canvasVolu:newImageData(z)
		local img = love.graphics.newImage(imgData)
		img:setFilter("nearest", "nearest", 0)


		local _scl = 2
		local xc = (z - 1) * (LKVOXR_SHADER_RENDER_DIST * 2)
		love.graphics.setColor(0.2, 0.4, 0.6, 1)
		love.graphics.rectangle("fill", xc * _scl, 0, LKVOXR_SHADER_VOLTEX_X * _scl, LKVOXR_SHADER_VOLTEX_Y * _scl)


		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(img, xc * _scl, 0, 0, _scl, _scl)
	end
	]]--
end