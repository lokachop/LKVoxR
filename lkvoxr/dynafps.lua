LKVoxR = LKVoxR or {}

local avgDtSamples = {}
local sID = 0
local sampleCount = 2

local dtTarget = 1 / LKVOXR_DYNFPS_FPS_TARGET
local nextUpgrade = 0
function LKVoxR.DynScaleThink(dt)
    avgDtSamples[sID] = dt
    sID = ((sID + 1) % sampleCount)

    if #avgDtSamples < (sampleCount - 1) then
        return
    end

    local avgDT = 0
    for i = 0, sampleCount - 1 do
        avgDT = avgDT + avgDtSamples[i]
    end
    avgDT = avgDT / sampleCount

    local dtDelta = (dtTarget - avgDT)
    if dtDelta < 0 then
        local newW = math.max(LKVOXR_RENDER_RES_X - LKVOXR_DYNFPS_RES_LOWER_STEP, LKVOXR_DYNFPS_RES_MIN_X)
        local newH = math.max(LKVOXR_RENDER_RES_Y - LKVOXR_DYNFPS_RES_LOWER_STEP, LKVOXR_DYNFPS_RES_MIN_Y)
        if newW == LKVOXR_RENDER_RES_X and newH == LKVOXR_RENDER_RES_Y then
            return
        end


        print(LKVOXR_RENDER_RES_X .. "x" .. LKVOXR_RENDER_RES_Y .. "->" .. newW .. "x" .. newH)

        sID = 0
        avgDtSamples = {}

        LKVoxR.ChangeResolution(
            newW,
            newH
        )
    elseif dtDelta > .0075 and (CurTime > nextUpgrade) then
        local newW = math.min(LKVOXR_RENDER_RES_X + LKVOXR_DYNFPS_RES_LOWER_STEP, LKVOXR_DYNFPS_RES_MAX_X)
        local newH = math.min(LKVOXR_RENDER_RES_Y + LKVOXR_DYNFPS_RES_LOWER_STEP, LKVOXR_DYNFPS_RES_MAX_Y)
        if newW == LKVOXR_RENDER_RES_X and newH == LKVOXR_RENDER_RES_Y then
            return
        end


        nextUpgrade = CurTime + .5
        print(LKVOXR_RENDER_RES_X .. "x" .. LKVOXR_RENDER_RES_Y .. "->" .. newW .. "x" .. newH)

        sID = 0
        avgDtSamples = {}

        LKVoxR.ChangeResolution(newW, newH)
    end
end