local i = 0
i += 10
i -= 5
local function func()
	i /= 5
end
func()
local t = {}
t.a = i
t.a *= 2
return t
