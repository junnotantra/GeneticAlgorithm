local gen_length = 4
local gen_in_chromosome = 9
local chromosome_length = gen_in_chromosome * gen_length
local population_size = 40
local target_result = 25
local crossover_rate = 0.7
local mutation_rate = 0.001
local max_loop = 10000

local chromosome = {}
chromosome.__index = chromosome

function chromosome:New()
	local self = setmetatable({}, chromosome)
	self.data = self:Generate()
	self.decoded, self.decodedString = self:Decode()
	self.result = self:Eval()
	self.score = self:CalculateFitness()
	return self
end

function chromosome:Generate()
	local temp = ""
	for i=1,chromosome_length do
		temp = temp .. math.random(0,1)
	end
	return temp
end

function chromosome:Decode()
	local result = {}
	for i=1,gen_in_chromosome do
		local part = string.sub(self.data, (i*gen_length-3), (i*gen_length))
		if(part == "0000") then table.insert(result, "0")
		elseif(part == "0001") then table.insert(result, "1")
		elseif(part == "0010") then table.insert(result, "2")
		elseif(part == "0011") then table.insert(result, "3")
		elseif(part == "0100") then table.insert(result, "4")
		elseif(part == "0101") then table.insert(result, "5")
		elseif(part == "0110") then table.insert(result, "6")
		elseif(part == "0111") then table.insert(result, "7")
		elseif(part == "1000") then table.insert(result, "8")
		elseif(part == "1001") then table.insert(result, "9")
		elseif(part == "1010") then table.insert(result, "+")
		elseif(part == "1011") then table.insert(result, "-")
		elseif(part == "1100") then table.insert(result, "*")
		elseif(part == "1101") then table.insert(result, "/")
		else
		end
	end
	
	local content = "operator"
	local i=1
	while i<=#result do
		local temp = tonumber(result[i])
		if(temp) then
			if(content == "number") then
				table.remove(result, i)
			else
				if(result[i-1] == "/" and result[i] == 0) then
					table.remove(result, i)
				else					
					content = "number"
					i = i+1
				end
			end
		else
			if(content == "number") then
				content = "operator"
				i = i+1
			else
				table.remove(result, i)
			end
		end
	end
	if(not tonumber(result[#result])) then table.remove(result, #result) end
	if(not tonumber(result[#result])) then table.remove(result, #result) end
	
	local resultString = ""
	for k,v in ipairs(result) do
		resultString = resultString .. v
	end
	
	return result, resultString
end

function chromosome:Eval()
	local operator
	local operand1 = 0
	local operand2 = 0
	for k,v in ipairs(self.decoded) do
		if(type(tonumber(v)) == "number") then
			if(not operator) then
				if(operand1 == 0) then
					operand1 = v
				else
					operand1 = tonumber(operand1 .. v)
				end
			else
				if(operand2 == 0) then
					operand2 = v
				else
					operand2 = tonumber(operand2 .. v)
				end
			end
		else
			if(not operator) then
				operator = v
			else
				if(operator == "+") then operand1 = operand1 + operand2
				elseif(operator == "-") then operand1 = operand1 - operand2
				elseif(operator == "*") then operand1 = operand1 * operand2
				elseif(operator == "/") then operand1 = operand1 / operand2 
				end
				operand2 = 0
				operator = v
			end
		end
	end
	if(operator == "+") then operand1 = operand1 + operand2
	elseif(operator == "-") then operand1 = operand1 - operand2
	elseif(operator == "*") then operand1 = operand1 * operand2
	elseif(operator == "/") then operand1 = operand1 / operand2 
	end
	return operand1
end

function chromosome:Crossover(c2)
	local rand = math.random(1, chromosome_length)
	local c1_f = string.sub(self.data, 1, rand)
	local c1_b = string.sub(self.data, rand, chromosome_length)
	local c2_f = string.sub(c2.data, 1, rand)
	local c2_b = string.sub(c2.data, rand, chromosome_length)
	self.data = c1_f .. c2_b
	c2.data = c2_f .. c1_f
end

function chromosome:Mutation()
	local result = ""
	for i=1,chromosome_length do
		local temp string.sub(self.data, i, i)
		if(temp == "0") then
			result = result .. "1"
		else
			result = result .. "0"
		end
	end
	return result
end

function chromosome:CalculateFitness()
	local calc = self.result
	if(calc == target_result) then
		return 1
	else
		local temp = math.abs(1 / (calc - target_result))
		return tonumber(string.format("%." .. (3 or 0) .. "f", temp)) or 0
	end
end

function chromosome:Recalculate()
	self.decoded, self.decodedString = self:Decode()
	self.result = self:Eval()
	self.score = self:CalculateFitness()
end

local function SelectBest(pop)
	local best = 0
	local best_index
	for k,v in ipairs(pop) do
		if(v.score > best) then
			best_index = k
			best = v.score
		end
	end
	return pop[best_index]
end

local function GeneratePool()
	local population = {}
	for i=1,population_size do
		table.insert(population, chromosome:New())
	end
	return population
end

local function Selection(pool)
	local result
	local total = 0
	for k,v in ipairs(pool) do
		total = total + v.score
	end
	
	local tot_target = total * math.random()
	local tot_now = 0
	for k,v in ipairs(pool) do
		tot_now = tot_now + v.score
		if(tot_now >= tot_target) then
			result = v
			table.remove(pool, k)
			break
		end
	end
	return result, pool
end

local function Main()
	-- Generate population
	local population = GeneratePool()
	local new_population = {}
	local generation = 0
	while true do
		new_population = {}
		generation = generation + 1
		
		for i=#population,2,-2 do
			-- Selection
			local c1, c2
			c1, population = Selection(population)
			c2, population = Selection(population)
			
			-- Crossover
			if(crossover_rate > math.random()) then
				c1:Crossover(c2)
			end
			
			-- Mutation
			if(mutation_rate > math.random()) then
				c1:Mutation()
				c2:Mutation()
			end
			
			-- Rescore
			c1:Recalculate()
			c2:Recalculate()
			
			-- Check if c1 or c2 is the answer
			if(c1.result == target_result) then 
				print ("Generations : " .. generation .. ", Solution : " .. c1.decodedString)
				return
			elseif(c2.result == target_result) then 
				print ("Generations : " .. generation .. ", Solution : " .. c2.decodedString)
				return
			else
				table.insert(new_population, c1)
				table.insert(new_population, c2)
			end
		end
		population = new_population
		if(generation > max_loop) then 
			local current_best = SelectBest(population)
			print("Best for now : " .. current_best.decodedString)
			break
		end
	end
end

math.randomseed(os.time())
Main()