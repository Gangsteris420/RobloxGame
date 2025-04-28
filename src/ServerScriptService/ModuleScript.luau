local TriggeredCounter = {}
local EventCounter = {}
EventCounter.__index = EventCounter

function ExploitCheck(player_data, name_of_event, uuid) -- checking how many times was stageStarted triggered
    if player_data then
        local count = 0
        if player_data[name_of_event] ~= nil then
            for _, _ in pairs(player_data[name_of_event]) do
                count = count + 1
            end
        end

        if count > 0 then
            print("constructor is being spammed!")

            if not TriggeredCounter[uuid] then
                TriggeredCounter[uuid] = {}
                TriggeredCounter[uuid].TimesTriggered = 0
                TriggeredCounter[uuid].EventName = "TriggeredCounter"
                TriggeredCounter[uuid].Time = os.clock()
            end

            -- either make this table reset when cheater dropped or when loop ended
            TriggeredCounter[uuid].TimesTriggered = TriggeredCounter[uuid].TimesTriggered + 1

            return true, TriggeredCounter[uuid]
        end
    end
    return nil
end

EventCounter.new = function(player_data, name_of_event, uuid, stage) -- constructor, .new, __init, etc. (same thing)
    local state, return_back = ExploitCheck(player_data, name_of_event, uuid)

    if state == nil then
        local self = setmetatable({}, EventCounter)
        self[name_of_event] = {}
        self[name_of_event].Time = require(game:GetService("ServerScriptService").StageData).ReturnData(stage, "Time")
        return self
    else
        return return_back
    end
end

-- also need to test whether its for everyone or each player
function EventCounter:Count() -- need to pass info so the stage time key could be found
    local Time = self.StageStarted.Time
    
    for i = 1, Time, 1 do
		task.wait(1)
        print("looping", i)
		if i == Time then
			-- need to trigger a onClientEvent to reset attributes
		end
	end
end

return EventCounter