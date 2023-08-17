function love.load()
	love.filesystem.load("/lkvoxr/lkvoxr.lua")()
	CurTime = 0


	UnivTest = LKVoxR.NewUniverse("test1")
end

function love.update(dt)
	CurTime = CurTime + dt

	LKVoxR.PushUniverse(UnivTest)
		--LKVoxR.NoclipCam(dt)
		LKVoxR.DynScaleThink(dt)
		LKVoxR.PlayerController(dt)
	LKVoxR.PopUniverse()
end

function love.keypressed(key)
	LKVoxR.ToggleMouseGrab(key)
end

function love.mousemoved(mx, my, dx, dy)
	LKVoxR.LookAround(dx, dy)
end

function love.mousepressed(x, y, button)
	if LKVoxR.InputLock then
		local w, h = love.graphics.getDimensions()
		x = math.floor(w * .5)
		y = math.floor(h * .5)
	end


	local dir = LKVoxR.ScreenToWorldDir(x, y)

	LKVoxR.PushUniverse(UnivTest)
	if button == 1 then -- break
		local hit, side, dist, hitPos, hitNormal, voxID, mapPos = LKVoxR.RaycastWorld(LKVoxR.CamPos, dir)

		LKVoxR.SetWorldContents(mapPos[1], mapPos[2], mapPos[3], 0)
	elseif button == 2 then -- place
		local hit, side, dist, hitPos, hitNormal, voxID, mapPos = LKVoxR.RaycastWorld(LKVoxR.CamPos, dir)

		local calcPos = mapPos + hitNormal
		LKVoxR.SetWorldContents(calcPos[1], calcPos[2], calcPos[3], 3)
	end

	LKVoxR.PopUniverse()
end

local canvasTest = love.graphics.newCanvas(love.graphics.getDimensions())
--canvasTest:setFilter("nearest", "nearest", 0)
function love.draw()
	--love.graphics.clear(.1, .15, .2)
	love.graphics.setCanvas(canvasTest)
	love.graphics.setBlendMode("alpha")
		LKVoxR.PushUniverse(UnivTest)
			LKVoxR.RenderActiveUniverse()
		LKVoxR.PopUniverse()
	love.graphics.setCanvas()



	love.graphics.setBlendMode("alpha", "premultiplied")
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(canvasTest, 0, 0)
end