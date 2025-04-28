local stage_data = {
	["Stage1"] = {
		["Points"] = 2, -- points to complete
		["Time"] = 5, -- seconds till gate appears again
		["Lives"] = 3 -- lives per stage WIP
	},

	["Stage2"] = {
		["Points"] = 2,
		["Time"] = 5,
		["Lives"] = 3
	},
}

function stage_data.ReturnData(stage_name, stage_key)
    return stage_data[stage_name][stage_key]
end

return stage_data