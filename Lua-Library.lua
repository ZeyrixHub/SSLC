---------------------------------------------------------------------
-- SSLC – Secret Simple Language Code
-- Full Lua library
-- Author: ZeyrixHUB
-- License: MIT
---------------------------------------------------------------------

local sslc = {}

---------------------------------------------------------------------
-- ALPHABET MAPS
---------------------------------------------------------------------
local letters = {
  A="///", B="//", C="/", D="-/", E="--/", F="---/",
  G="+/",  H="++/", I="+++/",
  J="___", K="__", L="_", M="-_", N="--_", O="---_",
  P="+_",  Q="++_", R="+++_",
  S="###", T="##", U="#",
  V="-#",  W="--#", X="---#", Y="+#", Z="++#"
}

local numbers = {
  ["0"]="$", ["1"]="*", ["2"]="**", ["3"]="***",
  ["4"]="-*", ["5"]="--*", ["6"]="---*",
  ["7"]="+*", ["8"]="++*", ["9"]="+++*"
}

local decodeMap = {}
for k,v in pairs(letters) do decodeMap[v] = k end
for k,v in pairs(numbers) do decodeMap[v] = k end

---------------------------------------------------------------------
-- INTERNAL HELPERS
---------------------------------------------------------------------
local function flushNumbers(buf)
  local out = {}
  for token in buf:gmatch("%$|[%-%+]*%*+") do
    if decodeMap[token] then table.insert(out, decodeMap[token]) end
  end
  return table.concat(out)
end

---------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------

function sslc.encode(text)
  text = string.upper(text)
  local out, numBuffer = {}, ""
  for i = 1, #text do
    local ch = text:sub(i,i)
    if ch == " " then
      table.insert(out, "^")
    elseif letters[ch] then
      table.insert(out, letters[ch] .. ".")
    elseif numbers[ch] then
      table.insert(out, numbers[ch])
    else
      table.insert(out, ch)
    end
  end
  return table.concat(out)
end

function sslc.decode(code)
  local result, buf, numBuf = {}, "", ""
  local function flushNum()
    if #numBuf > 0 then
      table.insert(result, flushNumbers(numBuf))
      numBuf = ""
    end
  end

  for i = 1, #code do
    local c = code:sub(i,i)
    if c == "^" then
      flushNum()
      table.insert(result, " ")
    elseif c == "." then
      if decodeMap[buf] then table.insert(result, decodeMap[buf]) end
      buf = ""
    elseif c == "!" then
      flushNum()
    else
      buf = buf .. c
      if c == "*" or c == "$" then
        numBuf = numBuf .. buf
        buf = ""
      end
      if decodeMap[buf] and buf:match("[/_#]$") then
        table.insert(result, decodeMap[buf])
        buf = ""
      end
    end
  end
  flushNum()
  return table.concat(result)
end

function sslc.autoPrint(secret)
  print(sslc.decode(secret))
end

function sslc.isValid(secret)
  local ok, _ = pcall(function() sslc.decode(secret) end)
  return ok
end

function sslc.stats(secret)
  local lettersCount = select(2, secret:gsub("[/#+_%-]+%.*",""))
  local numbersCount = select(2, secret:gsub("[%*%$]+",""))
  local spaces       = select(2, secret:gsub("%^",""))
  return {
    letters = lettersCount,
    numbers = numbersCount,
    spaces  = spaces
  }
end

---------------------------------------------------------------------
-- OPTIONAL: Command-Line Interface
---------------------------------------------------------------------
if ... == nil then
  local arg = _G.arg or {}
  if #arg < 2 then
    print("Usage: lua sslc.lua encode|decode \"text\"")
    os.exit(0)
  end
  local mode, text = arg[1], table.concat(arg, " ", 2)
  if mode:lower():sub(1,1) == "e" then
    print(sslc.encode(text))
  else
    print(sslc.decode(text))
  end
end

return sslc
