function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local newObject = {}
        lookup_table[object] = newObject
        for key, value in pairs(object) do
            newObject[_copy(key)] = _copy(value)
        end
        return setmetatable(newObject, getmetatable(object))
    end
    return _copy(object)
end

function class(classname, super)
    local superType = type(super)
    local cls

    if superType ~= "function" and superType ~= "table" then
        superType = nil
        super = nil
    end

    if superType == "function" or (super and super.__ctype == 1) then
        -- inherited from native C++ Object
        cls = {}

        if superType == "table" then
            -- copy fields from super
            for k,v in pairs(super) do cls[k] = v end
            cls.__create = super.__create
            cls.super    = super
        else
            cls.__create = super
        end

        cls.ctor    = function() end
        cls.__cname = classname
        cls.__ctype = 1

        function cls.new(...)
            local instance = cls.__create(...)
            -- copy fields from class to native object
            for k,v in pairs(cls) do instance[k] = v end
            instance.class = cls
            instance:ctor(...)
            return instance
        end

    else
        -- inherited from Lua Object
        if super then
            cls = clone(super)
            cls.super = super
        else
            cls = {ctor = function() end}
        end

        cls.__cname = classname
        cls.__ctype = 2 -- lua
        cls.__index = cls

        function cls.new(...)
            local instance = setmetatable({}, cls)
            instance.class = cls
            instance:ctor(...)
            return instance
        end
    end

    return cls
end

-- 分隔字符串
function string.split(str, flag)
    local tab = {}
    while true do
        -- 在字符串中查找分割的标签
        local n = string.find(str, flag)
        if n then
            -- 截取分割标签之前的字符串
            local first = string.sub(str, 1, n-1) 
            -- str 赋值为分割之后的字符串
            str = string.sub(str, n+1, #str) 
            -- 把截取的字符串 保存到table中
            table.insert(tab, first)
        else
            table.insert(tab, str)
            break
        end
    end
    return tab
end

function string.trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
 end

function dump(value, desciption, nesting)
    if type(nesting) ~= "number" then nesting = 3 end  
  
    local lookupTable = {}  
    local result = {}  
  
    local function _v(v)  
        if type(v) == "string" then  
            v = "\"" .. v .. "\""  
        end  
        return tostring(v)  
    end  
  
    local traceback = string.split(debug.traceback("", 2), "\n")  
    print("dump from: " .. string.trim(traceback[3]))  
  
    local function _dump(value, desciption, indent, nest, keylen)  
        desciption = desciption or "<var>"  
        spc = ""  
        if type(keylen) == "number" then  
            spc = string.rep(" ", keylen - string.len(_v(desciption)))  
        end  
        if type(value) ~= "table" then  
            result[#result +1 ] = string.format("%s%s%s = %s", indent, _v(desciption), spc, _v(value))  
        elseif lookupTable[value] then  
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, desciption, spc)  
        else  
            lookupTable[value] = true  
            if nest > nesting then  
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, desciption)  
            else  
                result[#result +1 ] = string.format("%s%s = {", indent, _v(desciption))  
                local indent2 = indent.."    "  
                local keys = {}  
                local keylen = 0  
                local values = {}  
                for k, v in pairs(value) do  
                    keys[#keys + 1] = k  
                    local vk = _v(k)  
                    local vkl = string.len(vk)  
                    if vkl > keylen then keylen = vkl end  
                    values[k] = v  
                end  
                table.sort(keys, function(a, b)  
                    if type(a) == "number" and type(b) == "number" then  
                        return a < b  
                    else  
                        return tostring(a) < tostring(b)  
                    end  
                end)  
                for i, k in ipairs(keys) do  
                    _dump(values[k], k, indent2, nest + 1, keylen)  
                end  
                result[#result +1] = string.format("%s}", indent)  
            end  
        end  
    end  
    _dump(value, desciption, "- ", 1)  
  
    for i, line in ipairs(result) do  
        print(line)  
    end  
end  
