local log = [[Hora                               Piloto             Nº Volta   Tempo Volta       Velocidade média da volta
23:49:08.277      038 – F.MASSA                           1		1:02.852                        44,275
23:49:10.858      033 – R.BARRICHELLO                     1		1:04.352                        43,243
23:49:11.075      002 – K.RAIKKONEN                       1             1:04.108                        43,408
23:49:12.667      023 – M.WEBBER                          1		1:04.414                        43,202
23:49:30.976      015 – F.ALONSO                          1		1:18.456			35,47
23:50:11.447      038 – F.MASSA                           2		1:03.170                        44,053
23:50:14.860      033 – R.BARRICHELLO                     2		1:04.002                        43,48
23:50:15.057      002 – K.RAIKKONEN                       2             1:03.982                        43,493
23:50:17.472      023 – M.WEBBER                          2		1:04.805                        42,941
23:50:37.987      015 – F.ALONSO                          2		1:07.011			41,528
23:51:14.216      038 – F.MASSA                           3		1:02.769                        44,334
23:51:18.576      033 – R.BARRICHELLO		          3		1:03.716                        43,675
23:51:19.044      002 – K.RAIKKONEN                       3		1:03.987                        43,49
23:51:21.759      023 – M.WEBBER                          3		1:04.287                        43,287
23:51:46.691      015 – F.ALONSO                          3		1:08.704			40,504
23:52:01.796      011 – S.VETTEL                          1		3:31.315			13,169
23:52:17.003      038 – F.MASS                            4		1:02.787                        44,321
23:52:22.586      033 – R.BARRICHELLO		          4		1:04.010                        43,474
23:52:22.120      002 – K.RAIKKONEN                       4		1:03.076                        44,118
23:52:25.975      023 – M.WEBBER                          4		1:04.216                        43,335
23:53:06.741      015 – F.ALONSO                          4		1:20.050			34,763
23:53:39.660      011 – S.VETTEL                          2		1:37.864			28,435
23:54:57.757      011 – S.VETTEL                          3		1:18.097			35,633]]

-- Performance optimization
local math_floor = math.floor
local string_format = string.format
local string_find = string.find
local string_gmatch = string.gmatch
local string_gsub = string.gsub
local string_match = string.match
local string_rep = string.rep
local string_sub = string.sub
local table_concat = table.concat
local table_sort = table.sort

-- Removes the first line
local posFirstBreakLine = string_find(log, '\n', nil, true) -- Plain find to avoid pattern and unnecessary process
log = string_sub(log, posFirstBreakLine + 1)

-- Time handlers
local timeToMilliseconds = function(time)
	local hour, min, sec, ms = string_match(time, "^(%d*):?(%d+):(%d+)%.(%d+)") -- Lua is pattern only, no regex
	hour = (tonumber(hour) or 0) * 36e8 -- 60k^2 ms = 1 hr
	min = tonumber(min) * 60000 -- 60k ms = 1 min
	sec = tonumber(sec) * 1000 -- 1k ms = 1s
	return hour + min + sec + tonumber(ms) -- Time in ms
end

local millisecondsToTime = function(ms)
	local min = math_floor(ms / 60000 % 60) -- Using math.floor because lua 5.3 has int and double, and using %f would round it.
	local sec = math_floor(ms / 1000 % 60)
	ms = math_floor(ms % 1000)
	return string_format("%02d:%02d.%03d", min, sec, ms)
end

-- Extra data
local highestLapDetected = 0 -- Tends to be 4
local bestLapDriver

 -- Main table where the drivers are stored
local driver = { }

-- Filter the log data
local driverData -- Not to get created many times in the loop
for time, code, name, lap, lapTime, avgVel in string_gmatch(log, "(%S+).-(%d+) – (%S+).-(%d).-(%S+).-(%S+)") do -- Not filtering the pattern with formats now because the values will be handled later
	if not driver[code] then
		driver[code] = {
			time = 0,
			code = code,
			name = name,
			laps = 0,
			lapsTime = 0,
			avgVel = 0,
			-- Extra
			bestLapTime = nil,
			bestLap = nil
		}
	end
	driverData = driver[code]

	driverData.time = time

	lap = tonumber(lap)
	driverData.laps = lap
	if lap > highestLapDetected then
		highestLapDetected = lap
	end

	lapTime = timeToMilliseconds(lapTime)
	driverData.lapsTime = driverData.lapsTime + lapTime
	if not driverData.bestLapTime or (lapTime < driverData.bestLapTime) then
		driverData.bestLapTime = lapTime
		driverData.bestLap = lap

		if not bestLapDriver or (lapTime < bestLapDriver.bestLapTime) then
			bestLapDriver = driverData
		end
	end

	driverData.avgVel = driverData.avgVel + tonumber((string_gsub(avgVel, ',', '.'))) -- Removes the commma and makes it a number. Using another ( ) because string.gsub returns two values and it only needs the first one.
end
driverData = nil

local driverByLap = { }
-- Puts the drivers in their respective laps
-- This is necessary because if one driver was faster but was one lap before, it would win (which is incorrect). Example: A at lap 2 time 2h and B at lap 3 and time 3h. A would win if the lap is not handled.
local currentLap
for _, driverData in next, driver do
	if not driverByLap[driverData.laps] then
		driverByLap[driverData.laps] = {
			_index = 0 -- Setting an index counter instead of tbl[#tbl + 1] / table.insert is just performance optimization.
		}
	end
	currentLap = driverByLap[driverData.laps]

	driverData.time = timeToMilliseconds(driverData.time)
	driverData._lapsTime = millisecondsToTime(driverData.lapsTime) -- Display only, since lapsTime of the winner will be necessary.
	driverData.bestLapTime = millisecondsToTime(driverData.bestLapTime)

	currentLap._index = currentLap._index + 1
	currentLap[currentLap._index] = driverData
end
currentLap = nil

driver = { } -- Refreshed because it will be overwritten with the new sequence
local driverIndex = 0
-- Sorts the extracted data in their respective laps
for lap = highestLapDetected, 1, -1 do
	if driverByLap[lap] then -- If there's any driver that stopped in that specific lap
		table_sort(driverByLap[lap], function(driver1, driver2) -- Sorts based on the laps time. (crescent)
			return driver1.lapsTime < driver2.lapsTime
		end)

		for d = 1, driverByLap[lap]._index do -- Inserts the data already in order / sorted.
			driverIndex = driverIndex + 1
			driver[driverIndex] = driverByLap[lap][d]
		end
	end
end
driverByLap = nil

-- Display the results
local getFieldValue = function(fieldName, data)
	-- Inserts spaces to make a readable table
	-- Example:
	--[[
		-- Wrong
		Field1 | Field2 | Field3
		1 | 2 | 3

		-- Formated
		Field1 | Field2 | Field3
		1      | 2      | 3
	]] 
	return data .. string_rep(' ', #fieldName - #tostring(data))
end

local output = {
	[1] = "Posicao",
	[2] = "Codigo Piloto",
	[3] = "Nome do Piloto",
	[4] = "Qtde Voltas Completadas",
	[5] = "Tempo Total de Prova",
	[6] = "Melhor tempo e volta",
	[7] = "Velocidade media",
	[8] = "Tempo após vencedor"
}
local outputFields = #output

for d = 1, driverIndex do 
	driverData = driver[d]

	output[outputFields + d] = table_concat({ -- table.concat is faster than concatenating strings individually
		[1] = getFieldValue(output[1], d),
		[2] = getFieldValue(output[2], driverData.code),
		[3] = getFieldValue(output[3], driverData.name),
		[4] = getFieldValue(output[4], driverData.laps),
		[5] = getFieldValue(output[5], driverData._lapsTime),
		[6] = getFieldValue(output[6], driverData.bestLapTime .. " (volta " .. driverData.bestLap .. ")"),
		[7] = getFieldValue(output[7], string_format("%2.3f", (driverData.avgVel / driverData.laps))),
		[8] = getFieldValue(output[8], millisecondsToTime(driverData.time - bestLapDriver.time))
	}, " | ")
end

print("Melhor volta da corrida:\n\tCódigo do piloto: " .. bestLapDriver.code .. "\n\tNome do piloto: " .. bestLapDriver.name .. "\n\tTempo: " .. bestLapDriver.bestLapTime .. " (volta " .. bestLapDriver.bestLap .. ")\n")
print(table_concat(output, " | ", 1, outputFields) .. "\n" .. table_concat(output, '\n', outputFields + 1))
