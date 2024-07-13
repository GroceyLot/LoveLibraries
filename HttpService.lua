local HttpService = {}
local json = require("Lib.Json")
local https = require("https")
local socket_url = require("socket.url") -- Add this to use URI encoding

-- Function to perform a GET request
function HttpService:Get(url)
    local code, body, headers = https.request(url)
    return code, body, headers
end

-- Function to perform a POST request
function HttpService:Post(url, data, headers)
    local options = {
        method = "POST",
        headers = headers,
        data = json.encode(data)
    }
    options.headers["Content-Type"] = "application/json"
    local code, body, headers = https.request(url, options)
    return code, body, headers
end

-- Function to encode a Lua table to a JSON string
function HttpService:JSONEncode(table)
    return json.encode(table)
end

-- Function to decode a JSON string to a Lua table
function HttpService:JSONDecode(jsonString)
    return json.decode(jsonString)
end

-- Function to URI encode a string
function HttpService:URIEncode(str)
    if str then
        str = str:gsub("([^%w_%-%.%~])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
    end
    return str
end

-- Function to fetch an image from a URL and return as a Love2D image object
function HttpService:GetImage(url)
    local options = {
        headers = {
            ["User-Agent"] = [[LilGame/0.0 (https://example.org/coolbot/; noemail@gmail.com) generic-library/0.0]]
        }
    }
    local code, body, headers = https.request(url, options)

    if code == 200 then
        local fileData = love.filesystem.newFileData(body, "image.png")
        return love.graphics.newImage(fileData)
    else   
        print(code)
        print(body)
        print(headers)
    end
end

return HttpService
