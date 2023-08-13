function love.load()
	love.filesystem.load("/lkvoxr/lkvoxr.lua")()
	CurTime = 0


	UnivTest = LKVoxR.NewUniverse("test1")
	--LKVoxR.PushUniverse(UnivTest)
	--	print("asd", LKVoxR.GetWorldContents(8, 2, 2))
	--LKVoxR.PopUniverse()

	--print(read[1] .. ", " .. read[2] .. ", " .. read[3])
end

function love.update(dt)
	CurTime = CurTime + dt

	LKVoxR.NoclipCam(dt)
end

function love.keypressed(key)
end

function love.mousepressed(x, y, button)
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

function love.draw()
	love.graphics.clear(.1, .15, .2)
	LKVoxR.PushUniverse(UnivTest)
		LKVoxR.RenderActiveUniverse()
	LKVoxR.PopUniverse()
end