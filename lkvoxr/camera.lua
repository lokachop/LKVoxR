LKVoxR = LKVoxR or {}

LKVoxR.CamPos = Vector(4, 6, 4)
LKVoxR.CamAng = Vector(0, 0, 0)
LKVoxR.CamAngX = Vector(0, 0, 0)
LKVoxR.CamAngY = Vector(0, 0, 0)
LKVoxR.CamAngZ = Vector(0, 0, 0)


function LKVoxR.SetCamPos(pos)
	LKVoxR.CamPos = pos
end

function LKVoxR.SetCamAng(ang)
	LKVoxR.CamAng = ang
end

function LKVoxR.UpdateCamAng(dp, dy, dr)
	LKVoxR.CamAngX[1] = (LKVoxR.CamAngX[1] + (dp or 0)) % 360
	LKVoxR.CamAngY[2] = (LKVoxR.CamAngY[2] + (dy or 0)) % 360
	LKVoxR.CamAngZ[3] = (LKVoxR.CamAngZ[3] + (dr or 0)) % 360



	LKVoxR.CamAng[1] = LKVoxR.CamAngZ[1]
	LKVoxR.CamAng[2] = -LKVoxR.CamAngY[2]
	LKVoxR.CamAng[3] = -LKVoxR.CamAngZ[3]
end

-- OVERRIDE: input
function LKVoxR.NoclipCam(dt)
	local dtMul = dt
	if love.keyboard.isDown("lshift") then
		dtMul = dt * 4
	end

	local fow = LKVoxR.CamAng:Right()
	fow:Mul(dtMul)

	local rig = -LKVoxR.CamAng:Forward()
	rig:Mul(dtMul)

	local up = -LKVoxR.CamAng:Up()
	up:Mul(dtMul)

	if love.keyboard.isDown("w") then
		LKVoxR.SetCamPos(LKVoxR.CamPos + fow)
	end

	if love.keyboard.isDown("s") then
		LKVoxR.SetCamPos(LKVoxR.CamPos - fow)
	end

	if love.keyboard.isDown("a") then
		LKVoxR.SetCamPos(LKVoxR.CamPos - rig)
	end

	if love.keyboard.isDown("d") then
		LKVoxR.SetCamPos(LKVoxR.CamPos + rig)
	end

	if love.keyboard.isDown("space") then
		LKVoxR.SetCamPos(LKVoxR.CamPos + up)
	end

	if love.keyboard.isDown("lctrl") then
		LKVoxR.SetCamPos(LKVoxR.CamPos - up)
	end

	if love.keyboard.isDown("left") then
		LKVoxR.UpdateCamAng(
			0,
			128 * dt,
			0
		)
	end

	if love.keyboard.isDown("right") then
		LKVoxR.UpdateCamAng(
			0,
			-128 * dt,
			0
		)
	end

	if love.keyboard.isDown("up") then
		LKVoxR.UpdateCamAng(
			0,
			0,
			-128 * dt
		)
	end

	if love.keyboard.isDown("down") then
		LKVoxR.UpdateCamAng(
			0,
			0,
			128 * dt
		)
	end
end