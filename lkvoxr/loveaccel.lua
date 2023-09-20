LKVoxR = LKVoxR or {}

function LKVoxR.VoxIDToRGB(id)
	return bit.band(bit.rshift(id, 16), 0xff) / 255, bit.band(bit.rshift(id, 8), 0xff) / 255, bit.band(id, 0xff) / 255
end


function LKVoxR.UpdateVolMap(chunk, x, y, z, to)
	if not chunk._volMap then
		LKVoxR.GenerateVolMap(chunk)
	end

	local indLayer = (y + 1)
	love.graphics.setCanvas(chunk._volMap, indLayer)

	love.graphics.setColor(LKVoxR.VoxIDToRGB(to))
	love.graphics.rectangle("fill", x, z, 1, 1)

	love.graphics.setCanvas()
end


function LKVoxR.GenerateVolMap(chunk)
	chunk._volMap = love.graphics.newCanvas(LKVOXR_CX_P, LKVOXR_CZ_P, LKVOXR_CY_P, {
		type = "volume",
		format = "normal",
		readable = true
	})
	chunk._volMap:setFilter("nearest", "nearest", 0)


	local _oldCanvas = love.graphics.getCanvas()
	local _oldShader = love.graphics.getShader()
	for y = 0, LKVOXR_CY_P - 1 do
		local indLayer = (y + 1)
		love.graphics.setShader()
		love.graphics.setCanvas(chunk._volMap, indLayer)

		for i = 0, (LKVOXR_CX_P * LKVOXR_CZ_P) - 1 do
			local xc = (i % LKVOXR_CX_P)
			local zc = math.floor(i / LKVOXR_CX_P) % LKVOXR_CZ_P

			local ind = xc + (y * LKVOXR_CX_P) + (zc * LKVOXR_CX_P * LKVOXR_CY_P)

			local cont = chunk[ind]
			love.graphics.setColor(LKVoxR.VoxIDToRGB(cont))
			love.graphics.rectangle("fill", xc, zc, 1, 1)
		end

		love.graphics.setCanvas(_oldCanvas)
		love.graphics.setShader(_oldShader)

	end
end
