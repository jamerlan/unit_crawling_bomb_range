function widget:GetInfo()
    return {
        name      = "Crawling bombs (hold fire and self-d radius) v3",
        desc      = "Sets crawling bombs on hold fire by default and displays self-d radius",
        author    = "[teh]decay aka [teh]undertaker",
        date      = "29 dec 2013",
        license   = "The BSD License",
        layer     = 0,
        version   = 1,
        enabled   = true  -- loaded by default
    }
end

-- project page on github: https://github.com/jamerlan/unit_crawling_bomb_range

--Changelog
-- v2 [teh]decay Advanced Crawling Bombs are cloaked by default (you can configure using "cloakAdvCrawlingBombs" variable) + hide circles when GUI is hidden
-- v3 [teh]decay Draw decloak range for Advanced Crawling Bomb


local cloakAdvCrawlingBombs = true


local GetUnitPosition     = Spring.GetUnitPosition
local glColor = gl.Color
local glDepthTest = gl.DepthTest
local glDrawGroundCircle  = gl.DrawGroundCircle
local GetUnitDefID = Spring.GetUnitDefID
local lower                 = string.lower
local spGetAllUnits = Spring.GetAllUnits
local spGetSpectatingState = Spring.GetSpectatingState
local spGetMyPlayerID		= Spring.GetMyPlayerID
local spGetPlayerInfo		= Spring.GetPlayerInfo
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spIsGUIHidden = Spring.IsGUIHidden

local cmdFireState = CMD.FIRE_STATE
local cmdCloack = CMD.CLOAK

local blastCircleDivs = 100
local weapNamTab		  = WeaponDefNames
local weapTab		      = WeaponDefs
local udefTab				= UnitDefs

local selfdTag = "selfDExplosion"
local aoeTag = "damageAreaOfEffect"

local coreCrawling = UnitDefNames["corroach"]
local coreAdvCrawling = UnitDefNames["corsktl"]
local armCrawling = UnitDefNames["armvader"]


local coreCrawlingId = coreCrawling.id
local coreAdvCrawlingId = coreAdvCrawling.id
local armCrawlingId = armCrawling.id

local crawlingBombs = {}

local spectatorMode = false
local notInSpecfullmode = false

function setBombStates(unitID, unitDefID)
    spGiveOrderToUnit(unitID, cmdFireState, { 0 }, {  })

    if unitDefID == coreAdvCrawlingId and cloakAdvCrawlingBombs then
        spGiveOrderToUnit(unitID, cmdCloack, { 1 }, {})
    end
end

function isBomb(unitDefID)
    if unitDefID == coreCrawlingId or coreAdvCrawlingId == unitDefID or unitDefID == armCrawlingId then
        return true
    end
    return false
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
    if isBomb(unitDefID) then
        crawlingBombs[unitID] = true
        setBombStates(unitID, unitDefID)
    end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    if crawlingBombs[unitID] then
        crawlingBombs[unitID] = nil
    end
end

function widget:UnitEnteredLos(unitID, unitTeam)
    if not spectatorMode then
        local unitDefID = GetUnitDefID(unitID)
        if isBomb(unitDefID) then
            crawlingBombs[unitID] = true
        end
    end
end

function widget:UnitCreated(unitID, unitDefID, teamID, builderID)
    if isBomb(unitDefID) then
        crawlingBombs[unitID] = true
        setBombStates(unitID, unitDefID)
    end
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
    if isBomb(unitDefID) then
        crawlingBombs[unitID] = true
        setBombStates(unitID, unitDefID)
    end
end


function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
    if isBomb(unitDefID) then
        crawlingBombs[unitID] = true
        setBombStates(unitID, unitDefID)
    end
end

function widget:UnitLeftLos(unitID, unitDefID, unitTeam)
    if not spectatorMode then
        if crawlingBombs[unitID] then
            crawlingBombs[unitID] = nil
        end
    end
end

function widget:DrawWorldPreUnit()
    local _, specFullView, _ = spGetSpectatingState()

    if not specFullView then
        notInSpecfullmode = true
    else
        if notInSpecfullmode then
            detectSpectatorView()
        end
        notInSpecfullmode = false
    end

    if spIsGUIHidden() then return end

    glDepthTest(true)

    for unitID in pairs(crawlingBombs) do
        local x,y,z = GetUnitPosition(unitID)
        local udefId = GetUnitDefID(unitID);
        if udefId ~= nil then
            local udef = udefTab[udefId]

            local selfdBlastId = weapNamTab[lower(udef[selfdTag])].id
            local selfdBlastRadius = weapTab[selfdBlastId][aoeTag]

            if udefId == coreAdvCrawlingId then
                glColor(1, .6, .3, .8)
                glDrawGroundCircle(x, y, z, udef["decloakDistance"], blastCircleDivs)
            end

            glColor(1, 0, 0, .7)
            glDrawGroundCircle(x, y, z, selfdBlastRadius, blastCircleDivs)

        end
    end
    glDepthTest(false)
end

function widget:PlayerChanged(playerID)
    detectSpectatorView()
    return true
end

function widget:Initialize()
    detectSpectatorView()
    return true
end

function detectSpectatorView()
    local _, _, spec, teamId = spGetPlayerInfo(spGetMyPlayerID())

    if spec then
        spectatorMode = true
    end

    local visibleUnits = spGetAllUnits()
    if visibleUnits ~= nil then
        for _, unitID in ipairs(visibleUnits) do
            local udefId = GetUnitDefID(unitID)
            if udefId ~= nil then
                if isBomb(udefId) then
                    crawlingBombs[unitID] = true
                end
            end
        end
    end
end
