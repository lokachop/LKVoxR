LKVoxR = LKVoxR or {}
LKVoxR.InputLock = false

LKVoxR.PlayerPos = Vector(0, 32, 0)
LKVoxR.PlayerVel = Vector(0, 0, 0)


function LKVoxR.UpdateCamAng(dp, dy, dr)
	LKVoxR.CamAngY[2] = (LKVoxR.CamAngY[2] + (dy or 0)) % 360
	LKVoxR.CamAngZ[3] = (LKVoxR.CamAngZ[3] + (dr or 0)) % 360

	local relaCheck = (LKVoxR.CamAngZ[3] + 180) % 360
	--print(relaCheck, LKVoxR.CamAngZ[3])
	if relaCheck < 90 then
		LKVoxR.CamAngZ[3] = 270
	end

	if relaCheck > 270 then
		LKVoxR.CamAngZ[3] = 90
	end


	LKVoxR.CamAng[2] = -LKVoxR.CamAngY[2]
	LKVoxR.CamAng[3] = -LKVoxR.CamAngZ[3]
end

function LKVoxR.LookAround(mx, my)
	if not LKVoxR.InputLock then
		return
	end

	local mxReal = -mx / 2
	local myReal = my / 2

	LKVoxR.UpdateCamAng(
		0,
		mxReal,
		myReal
	)
end


local _down = Vector(0, -1, 0)
local _camOff = Vector(0, 1.5, 0)
local _upOne = Vector(0, .01, 0)
local _trDist = .25

function LKVoxR.PlayerController(dt)
	local hit, side, dist, hitPos, hitNormal, voxID, mapPos = LKVoxR.RaycastWorld(LKVoxR.PlayerPos, _down, 2)

	local grounded = false
	local velD = (-LKVoxR.PlayerVel[2]) + .2
	if hit and dist < velD then
		grounded = true
	end

	if not grounded then
		LKVoxR.PlayerVel[2] = LKVoxR.PlayerVel[2] - (dt * .25)
	else
		LKVoxR.PlayerVel[2] = 0
		LKVoxR.PlayerPos[2] = hitPos[2]
	end


	if grounded and love.keyboard.isDown("space") then
		LKVoxR.PlayerVel[2] = 0.15
		LKVoxR.PlayerPos[2] = LKVoxR.PlayerPos[2] + .1
	end

	local vMul = 3
	if love.keyboard.isDown("lshift") then
		vMul = 6
	end

	local fow = LKVoxR.CamAng:Right()
	fow[2] = 0
	fow:Normalize()
	fow:Mul(vMul)

	local rig = -LKVoxR.CamAng:Forward()
	rig[2] = 0
	rig:Normalize()
	rig:Mul(vMul)

	if love.keyboard.isDown("w") then
		LKVoxR.PlayerVel[1] = fow[1]
		LKVoxR.PlayerVel[3] = fow[3]
	end

	if love.keyboard.isDown("s") then
		LKVoxR.PlayerVel[1] = LKVoxR.PlayerVel[1] - fow[1]
		LKVoxR.PlayerVel[3] = LKVoxR.PlayerVel[3] - fow[3]
	end

	if love.keyboard.isDown("a") then
		LKVoxR.PlayerVel[1] = LKVoxR.PlayerVel[1] - rig[1]
		LKVoxR.PlayerVel[3] = LKVoxR.PlayerVel[3] - rig[3]
	end

	if love.keyboard.isDown("d") then
		LKVoxR.PlayerVel[1] = LKVoxR.PlayerVel[1] + rig[1]
		LKVoxR.PlayerVel[3] = LKVoxR.PlayerVel[3] + rig[3]
	end

	LKVoxR.PlayerVel[1] = LKVoxR.PlayerVel[1] * dt
	LKVoxR.PlayerVel[3] = LKVoxR.PlayerVel[3] * dt


	local traceStart = LKVoxR.PlayerPos + _upOne

	local dir = Vector(LKVoxR.PlayerVel[1], 0, 0)
	dir:Normalize()

	hit, side, dist, hitPos, hitNormal, voxID, mapPos = LKVoxR.RaycastWorld(traceStart, dir, 2)
	if (hit and (dist < _trDist)) and hitNormal[1] ~= 0 then
		LKVoxR.PlayerVel[1] = 0
	end

	dir = Vector(0, 0, LKVoxR.PlayerVel[3])
	dir:Normalize()
	hit, side, dist, hitPos, hitNormal, voxID, mapPos = LKVoxR.RaycastWorld(traceStart, dir, 2)
	if (hit and (dist < _trDist)) and hitNormal[3] ~= 0 then
		LKVoxR.PlayerVel[3] = 0
	end


	LKVoxR.PlayerPos = LKVoxR.PlayerPos + LKVoxR.PlayerVel
	LKVoxR.CamPos = LKVoxR.PlayerPos + _camOff
end

function LKVoxR.ToggleMouseGrab(key)
	if key == "tab" then
		LKVoxR.InputLock = not love.mouse.isGrabbed()
		love.mouse.setGrabbed(LKVoxR.InputLock)
		love.mouse.setRelativeMode(LKVoxR.InputLock)
   end
end