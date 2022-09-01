local EASYBOARD = "...1.5...14....67..8...24...63.7..1.9.......3.1..9.52...72...8..26....35...4.9..."
local INVALIDBOARD = "...1.5...24....67..8...24...63.7..1.9.......3.1..9.52...72...8..26....35...4.9..."
local HARDFORBACKTRACKING = "..............3.85..1.2.......5.7.....4...1...9.......5......73..2.1........4...9"
local XWINGEXAMPLE = ".93..456..6...314...46.83.9981345...347286951652.7.4834.6..289....4...1..298...34"

local BOARD
if arg[1] then
	BOARD = arg[1]
else
	BOARD = HARDFORBACKTRACKING
end

local floor = math.floor
local time = os.time

local function stringToMatrix(inp)
	inp = string.gsub(inp, "%.", "0")
	local board = {}
	for i = 1, 9 do
		board[i] = {}
		for j = 1, 9 do
			board[i][j] = tonumber(string.sub(inp, (i-1)*9 + j, (i-1)*9 + j))
		end
	end
	return board
end

local function matrixToString(board)
	local s = ""
	for i = 1, 9 do
		for j = 1, 9 do
			s = s .. board[i][j]
		end
	end
	return string.gsub(s, "0", ".")
end

local function printBoard(board, preclear)
	if preclear then os.execute("cls") end
	if type(board) == "table" then board = matrixToString(board) end
	if type(board) ~= "string" or string.len(board) ~= 81 then print("invalid board") return end
	local separator = "+---+---+---+"
	local boardStr = separator
	for i = 0, 2 do
		for j = 0, 2 do
			local s = "|"
			for k = 0, 2 do
				s = s .. string.sub(board,i*27+j*9+k*3+1,i*27+j*9+k*3+3) .. "|"
			end
			boardStr = boardStr .. "\n" .. s
		end
		boardStr = boardStr .. "\n" .. separator
	end
	print(boardStr)
	print(board)
end

local function isGuessValid(guess, pos, board)
	local x, y = pos.x, pos.y
	if board[x][y] ~= 0 then return false end
	for r = 1, 9 do
		if board[r][y] == guess then return false end
	end
	for c = 1, 9 do
		if board[x][c] == guess then return false end
	end
	local i, j = floor((x-1)/3%3), floor((y-1)/3%3)
	for r = i*3+1,i*3+3 do
		for c = j*3+1,j*3+3 do
			if board[r][c] == guess then return false end
		end
	end
	return true
end

local function brute(input)
	local t0 = time()
	local board, origBoard = stringToMatrix(input), stringToMatrix(input)
	local loc = 0
	local iterations = 0
	while true do
		-- printBoard(board)
		if loc>=81 then return board, iterations end
		iterations = iterations + 1
		if iterations%1000000 == 0 then
			print(floor(iterations/1000000) .. " mil iterations, been running for " .. string.format("%i s (%.2f s per 10 mil)", time()-t0, (time()-t0)/(iterations/10000000)))
		end
		local x, y = floor((loc)/9)+1, loc%9+1
		if x > 9 or x < 1 then
			print("somethign wrong here")
			print("loc", loc)
			printBoard(board)
		end
		if origBoard[x][y] ~= 0 then
			loc = loc + 1
		else
			local g = board[x][y] + 1
			board[x][y] = 0
			if g > 9 then
				loc = loc - 1
				if loc < 0 then error("Invalid board provided (" .. iterations .. " iterations)") end
				while origBoard[floor((loc)/9)+1][loc%9+1] ~= 0 do
					loc = loc - 1
				end
			else
				if isGuessValid(g, {x=x, y=y}, board) then
					board[x][y] = g
					loc = loc + 1
					g = 0
				else
					board[x][y] = g
				end
			end
		end
	end
end

local t0 = time()
local sol, i = brute(BOARD)
printBoard(sol, 1)
print("solved in " .. i .. " guesses")
print("ran for " .. time()-t0 .. " seconds")