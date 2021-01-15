
earshot = 100 -- define earshot radius for peds

function sigmoid(x)
    local e = 2.7182818284590
	return (1 / (1 + (e ^ (-x))))
end

-- placeholder fuction --

function callPolice(geo)
    print("Police called! Shots fired at ", geo.x, ",", geo.y, ",", geo.z)
end

function drawBlip(geo, bInfo)
    Citizen.CreateThread(function()
        local blip = AddBlipForCoord(geo.x, geo.y, geo.z)
 
        SetBlipSprite(blip, bInfo.id)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 1.0)
        SetBlipColour(blip, bInfo.colour)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("Shots Fired!")
        AddTextComponentString(bInfo.title)
        EndTextCommandSetBlipName(blip)
        SetBlipAsMissionCreatorBlip(blip,true)
        PulseBlip(blip)
        SetBlipFlashes(blip, true)
        SetBlipFlashInterval(blip, 650)
 
        Citizen.Wait(30000)
        RemoveBlip(blip)
    end)
end

local entityEnumerator = {
    __gc = function(enum)
      if enum.destructor and enum.handle then
        enum.destructor(enum.handle)
      end
      enum.destructor = nil
      enum.handle = nil
    end
  }
  
local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
return coroutine.wrap(function()
    local iter, id = initFunc()
    if not id or id == 0 then
    disposeFunc(iter)
    return
    end
    
    local enum = {handle = iter, destructor = disposeFunc}
    setmetatable(enum, entityEnumerator)
    
    local next = true
    repeat
    coroutine.yield(id)
    next, id = moveFunc(iter)
    until not next
    
    enum.destructor, enum.handle = nil, nil
    disposeFunc(iter)
end)
end
  
function EnumerateObjects()
return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

function EnumeratePeds()
return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end

function EnumerateVehicles()
return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

function EnumeratePickups()
return EnumerateEntities(FindFirstPickup, FindNextPickup, EndFindPickup)
end

function GetNearbyPeds(X, Y, Z, Radius)
	local NearbyPeds = {}
	if tonumber(X) and tonumber(Y) and tonumber(Z) then
		if tonumber(Radius) then
			for Ped in EnumeratePeds() do
				if DoesEntityExist(Ped) then
					local PedPosition = GetEntityCoords(Ped, false)
					if Vdist(X, Y, Z, PedPosition.x, PedPosition.y, PedPosition.z) <= Radius then
						table.insert(NearbyPeds, Ped)
					end
				end
			end
		else
			Log.Warn("GetNearbyPeds: radius invalid")
		end
	else
		Log.Warn("GetNearbyPeds: coordinates invalid")
	end
	return NearbyPeds
end
 
Citizen.CreateThread(function()
 
    local dude = PlayerPedId()
    local bInfo = {title="Shots Fired!", colour=5, id=313}
    local max = 1
    local min = 0
    local curPeds = 0
    local shotRecently = false
    local shotTime = GetGameTimer()
 
    while true do

        local curPeds = 0
        -- Calculate normalized, current, nearby ped deviation (p) --
        local geo = GetEntityCoords(dude)
        local geoStreetHash, geoCrossHash = GetStreetNameAtCoord(geo.x, geo.y, geo.z)
        local geoStreetName = GetStreetNameFromHashKey(geoStreetHash)
        local geoCrossName = GetStreetNameFromHashKey(geoCrossHash)
        local pedTable = GetNearbyPeds(geo.x, geo.y, geo.z, earshot)
        local randP = math.random()
        
        curPeds = #pedTable

        --print(geoStreetName ..geoCrossName)
        if curPeds > max then
            max = curPeds
        end
        if curPeds < min then
            min = curPeds
        end
        
        local d = max - min
        p = (curPeds - min) / d
        if randP < p then
            
        end
 
        -- Listen for shots --
 
        local shooting = IsPedShooting(dude)
 
        if shooting and not shotRecently then
            local geo = GetEntityCoords(dude)
            drawBlip(geo, bInfo)

            -- used for debug

            print("NEARBY PED INFO: max: ", max, " min: ", min, " current: ", curPeds, " P = ", p)

            if randP < p then
                callPolice(geo)
            end

            
            shotRecently = true
            shotTime = GetGameTimer()
            -- TriggerEvent("Chat:Client:Message", "[DISPATCH]", "10-32 ALERT: shots reported at: " .. geoStreetName ..", and " ..geoCrossName, "system")
        end
        
        if shotTime + 2000 < GetGameTimer() then
            shotRecently = false
 
        end
        curPeds = 0
        Citizen.Wait(50)
    end
end)