--!native
--!optimize 2
--!strict
local SEQ = {
    [0] = "A","B","C","D","E","F","G","H",
    "I","J","K","L","M","N","O","P",
    "Q","R","S","T","U","V","W","X",
    "Y","Z","a","b","c","d","e","f",
    "g","h","i","j","k","l","m","n",
    "o","p","q","r","s","t","u","v",
    "w","x","y","z","0","1","2","3",
    "4","5","6","7","8","9","+","/",
}
local INDEX_BUF = buffer.create(256)
for i = 0, 255 do
    buffer.writeu8(INDEX_BUF, i, 0)
end
for i, v in ipairs(SEQ) do
    buffer.writeu8(INDEX_BUF, string.byte(v), i)
end
buffer.writeu8(INDEX_BUF, string.byte("="), 0)
local b64 = {}
function b64.encode(str: string)
    local len = #str
    local out = table.create(math.ceil(len / 3) * 4)
    local index = 1
    for i = 1, len, 3 do
        local b0 = string.byte(str, i)
        local b1 = string.byte(str, i + 1)
        local b2 = string.byte(str, i + 2)
        local n =
            bit32.lshift(b0, 16)
            + bit32.lshift(b1 or 0, 8)
            + (b2 or 0)
        out[index]     = SEQ[bit32.extract(n, 18, 6)]
        out[index + 1] = SEQ[bit32.extract(n, 12, 6)]
        out[index + 2] = b1 and SEQ[bit32.extract(n, 6, 6)] or "="
        out[index + 3] = b2 and SEQ[bit32.band(n, 63)] or "="
        index += 4
    end
    return table.concat(out)
end
function b64.decode(input: string)
    local len = #input
    local out = buffer.create((len // 4) * 3)
    local outIndex = 0
    for i = 1, len, 4 do
        local c0, c1, c2, c3 = string.byte(input, i, i + 3)
        local n =
            bit32.lshift(buffer.readu8(INDEX_BUF, c0), 18)
            + bit32.lshift(buffer.readu8(INDEX_BUF, c1), 12)
            + bit32.lshift(buffer.readu8(INDEX_BUF, c2), 6)
            + buffer.readu8(INDEX_BUF, c3)
        local b0 = bit32.extract(n, 16, 8)
        local b1 = bit32.extract(n, 8, 8)
        local b2 = bit32.band(n, 0xFF)
        buffer.writeu8(out, outIndex, b0)
        outIndex += 1
        if c2 ~= 61 then
            buffer.writeu8(out, outIndex, b1)
            outIndex += 1
        end
        if c3 ~= 61 then
            buffer.writeu8(out, outIndex, b2)
            outIndex += 1
        end
    end
    return buffer.tostring(out)
end
return b64
