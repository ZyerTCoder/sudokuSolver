--[[
reference: https://www.sudokuwiki.org/sudoku.htm
TODO
naked pairs/triples
hidden pairs/triples
--]]


local EASYBOARD = "...1.5...14....67..8...24...63.7..1.9.......3.1..9.52...72...8..26....35...4.9..."
local INVALIDBOARD = "...1.5...24....67..8...24...63.7..1.9.......3.1..9.52...72...8..26....35...4.9..."
local HARDFORBACKTRACKING = "..............3.85..1.2.......5.7.....4...1...9.......5......73..2.1........4...9"
local XWINGEXAMPLE = ".93..456..6...314...46.83.9981345...347286951652.7.4834.6..289....4...1..298...34"
local hiddenSingles = "200070038000006070300040600008020700100000006007030400004080009060400000910060002"
local nakedPairs = "400000938032094100095300240370609004529001673604703090957008300003900400240030709"
local hiddenPairs = "000000000904607000076804100309701080008000300050308702007502610000403208000000000"
local pointingPairs = "017903600000080000900000507072010430000402070064370250701000065000030000005601720"
local solved = "246975138589316274371248695498621753132754986657839421724183569865492317913567842"

local BOARD
if arg[1] then
	BOARD = arg[1]
else
	BOARD = hiddenSingles
end

local Sudoku = {board = BOARD}

local floor = math.floor
local time = os.time
local ceil = math.ceil

function Sudoku:iterateBoard()
		local r = 1
		local c = 0
		return function()
			if c >= 9 then
				c = 0
				r = r + 1
				if r > 9 then
					return nil
				end
			end
			c = c + 1
			return r, c
		end
	end

local function stringToMatrix(inp)
	inp = string.gsub(inp, "%.", "0")
	local board = {}
	for r = 1, 9 do
		board[r] = {}
		for c = 1, 9 do
			board[r][c] = tonumber(string.sub(inp, (r-1)*9 + c, (r-1)*9 + c))
		end
	end
	return board
end

local function matrixToString(board)
	local s = ""
	for i, j in Sudoku:iterateBoard() do
		if type(board[i][j]) == "table" then
			board[i][j] = "."
		end
		s = s .. board[i][j]
	end

	return string.gsub(s, "0", ".")
end

function Sudoku:new(input)
	local o = {}
	o = stringToMatrix(input)
	o.unsolvedCells = 81
	-- populate possibilities and count solves cells
	for i, j in Sudoku:iterateBoard() do
		if o[i][j] == 0 then
			o[i][j] = {1, 1, 1, 1, 1, 1, 1, 1, 1}
		else
			o.unsolvedCells = o.unsolvedCells - 1
		end
	end
	setmetatable(o, self)
	self.__index = self
	return o
end

function Sudoku.printSudoku(board, preclear)
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

function Sudoku.printSudokuLarge(board, preclear)
	if preclear then os.execute("cls") end
	if type(board) ~= "table" then print("invalid board given to printSudokuLarge") end

	local separator = "++---+---+---++---+---+---++---+---+---++"
	-- poss 123 for col 1 row 1
	-- poss 123 for col 2 row 1
	-- poss 123 for col 9 row 1
	-- poss 435 for col 1-9 row 1
	local boardStr = separator .. "\n" .. separator
	for i = 1, 9 do
		for k = 1, 9, 3 do
			local s = "||"
			for j = 1, 9 do
				if type(board[i][j]) == "table" then
					for a = k, k+2 do
						if board[i][j][a] ~= 0 then
							s = s .. a
						else
							s = s .. "."
						end
					end
					s = s .. "|"
				else -- board has digit here
					if k == 1 or k == 7 then
						s = s .. "   |"
					else
						s = s .. " " .. board[i][j] .. " |"
					end
				end
				if j % 3 == 0 then
					s = s .. "|"
				end
			end
			boardStr = boardStr .. "\n" .. s
		end
		boardStr = boardStr ..  "\n" .. separator
		if i % 3 == 0 then
			boardStr = boardStr ..  "\n" .. separator
		end
	end
	print(boardStr)
end

function Sudoku.isSolvedIncorrectly(board)
	for r = 1, 9 do
		local set = {}
		for c = 1, 9 do
			if set[board[r][c]] then
				return r, c
			end
			set[board[r][c]] = true
		end
	end

	for c = 1, 9 do
		local set = {}
		for r = 1, 9 do
			if set[board[r][c]] then
				return r, c
			end
			set[board[r][c]] = true
		end
	end

	for b = 0, 8 do
		local set = {}
		local x, y = floor(b/3), b%3
		for rr = x*3+1,x*3+3 do
			for cc = y*3+1, y*3+3 do
				if set[board[rr][cc]] then
					return rr, cc
				end
				set[board[rr][cc]] = true
			end
		end
	end
end

function Sudoku.isGuessValid(board, guess, pos)
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

function Sudoku.brute(input)
	local t0 = time()
	local board, origSudoku = stringToMatrix(input), stringToMatrix(input)
	local loc = 0
	local iterations = 0
	while true do
		-- printSudoku(board)
		if loc>=81 then return board, iterations end
		iterations = iterations + 1
		if iterations%1000000 == 0 then
			print(floor(iterations/1000000) .. " mil iterations, been running for " .. string.format("%i s (%.2f s per 10 mil)", time()-t0, (time()-t0)/(iterations/10000000)))
		end
		local x, y = floor((loc)/9)+1, loc%9+1
		if x > 9 or x < 1 then
			print("somethign wrong here")
			print("loc", loc)
			printSudoku(board)
		end
		if origSudoku[x][y] ~= 0 then
			loc = loc + 1
		else
			local g = board[x][y] + 1
			board[x][y] = 0
			if g > 9 then
				loc = loc - 1
				if loc < 0 then error("Invalid board provided (" .. iterations .. " iterations)") end
				while origSudoku[floor((loc)/9)+1][loc%9+1] ~= 0 do
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

function Sudoku.setSolvedCell(self, r, c, n, tech)
	self[r][c] = n
	self.unsolvedCells = self.unsolvedCells - 1
	local rows = "ABCDEFGHI"
	print("Set " .. rows:sub(r,r) .. c .. " to " .. n .. ", " .. tech)
end

function Sudoku.isCellSolved(self, r, c)
	return type(self[r][c]) == "number"
end

function Sudoku.isCellUnsolved(self, r, c)
	return type(self[r][c]) == "table"
end

function Sudoku.clearBadPossibilities(self)
	local didAnything = false
	for r, c in self:iterateBoard() do
		if self:isCellUnsolved(r, c) then
			-- check row
			for cc = 1, 9 do
				if cc ~= c and self:isCellSolved(r, cc) and self[r][c][self[r][cc]] ~= 0 then
					self[r][c][self[r][cc]] = 0
					didAnything = true
				end
			end
			-- check col
			for rr = 1, 9 do
				if rr ~= r and self:isCellSolved(rr, c) and self[r][c][self[rr][c]] ~= 0 then
					self[r][c][self[rr][c]] = 0
					didAnything = true
				end
			end
			-- check box
			local x, y = floor((r-1)/3%3), floor((c-1)/3%3)
			for rr = x*3+1,x*3+3 do
				for cc = y*3+1, y*3+3 do
					if (rr ~= r or cc ~= c) and self:isCellSolved(rr, cc) and self[r][c][self[rr][cc]] ~= 0 then
						self[r][c][self[rr][cc]] = 0
						didAnything = true
					end
				end
			end
		end
	end
	return didAnything
end

function Sudoku.checkSolvedCells(self) -- naked single
	local didAnything = false
	for r, c in self:iterateBoard() do
		if self:isCellUnsolved(r, c) then
			local possibilities = 0
			local index = 0
			for i = 1, 9 do
				if self[r][c][i] == 1 then
					possibilities = possibilities + 1
					index = i
				end
			end
			if possibilities == 1 then
				self:setSolvedCell(r, c, index, "naked single")
				didAnything = true
			end
		end
	end
	return didAnything
end

function Sudoku.hiddenSingles(self)
	-- try to find some way of breaking out of the for n loop after the flag goes to false
	local didAnything = false
	local hiddenSinglesFound = {}
	for r, c in self:iterateBoard() do
		if self:isCellUnsolved(r, c) then
			for n, v in pairs(self[r][c]) do
				if v == 1 then
					local uniqueIn = {row = true, col = true, box = true}
					-- check row
					for cc = 1, 9 do
						if cc ~= c and self:isCellUnsolved(r,cc) and self[r][cc][n] == 1 then
							uniqueIn.row = false
						end
					end
					-- check col
					for rr = 1, 9 do
						if rr ~= r and self:isCellUnsolved(rr,c) and self[rr][c][n] == 1 then
							uniqueIn.col = false
						end
					end
					-- check box
					local x, y = floor((r-1)/3%3), floor((c-1)/3%3)
					for rr = x*3+1,x*3+3 do
						for cc = y*3+1, y*3+3 do
							if (rr ~= r or cc ~= c) and self:isCellUnsolved(rr,cc) and self[rr][cc][n] == 1 then
								uniqueIn.box = false
							end
						end
					end
					local uniqueInStr = ""
					for k, b in pairs(uniqueIn) do
						if b then uniqueInStr = uniqueInStr .. k .. " " end
					end
					if uniqueInStr ~= "" then
						hiddenSinglesFound[#hiddenSinglesFound+1] = {r, c, n, "hidden single: unique in " .. uniqueInStr}
					end
				end
			end
		end
	end
	if #hiddenSinglesFound > 0 then
		didAnything = true
	end
	for _, t in pairs(hiddenSinglesFound) do
		self:setSolvedCell(table.unpack(t))
	end
	return didAnything
end

function Sudoku.smartSolve(self)

	local techniques = {
		{tech = self.checkSolvedCells, name = "checkSolvedCells"}, -- naked singles
		{tech = self.clearBadPossibilities, name = "clearBadPossibilities"},
		{tech = self.hiddenSingles, name = "hiddenSingles"},
	}

	local techUsed = {}
	local iterations = 0
	while self.unsolvedCells ~= 0 do
		iterations = iterations + 1
		local didAnything = false
		for i, tech in ipairs(techniques) do
			didAnything = tech.tech(self)
			-- self:printSudokuLarge()
			print("Applied " .. tech.name)
			if didAnything then
				techUsed[tech.name] = true
				if i > 1 then break end
			end
		end
		print("Iterations:" .. iterations, "Unsolved:" .. self.unsolvedCells)
		if not didAnything and self.unsolvedCells > 0 then
			print("Can't solve this sudoku with current techniques")
			break
		end
	end
	self:printSudokuLarge()
	print(matrixToString(self))
	print("Tech used:")
	for k, _ in pairs(techUsed) do print(k) end
end

local t0 = time()

sudoku = Sudoku:new(BOARD)
sudoku:smartSolve()
local r, c = sudoku:isSolvedIncorrectly()
if r then
	print("Solved incorrectly at", r, c)
end
-- print("solved in " .. i .. " guesses")
print("ran for " .. time()-t0 .. " seconds")