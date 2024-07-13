return function(key, baseUrl)
    return {
        key = key,
        baseUrl = baseUrl,
        http = require("Lib.HttpService"),
        request = function(self, model, messages, responseFormat)
            local headers = {
                ["Authorization"] = "Bearer " .. self.key
            }
            local data = {
                model = model,
                messages = messages,
                response_format = {
                    type = responseFormat
                }
            }
            local url = self.baseUrl .. "/chat/completions"
            local code, body, headers = self.http:Post(url, data, headers)
            local jsonBody = self.http:JSONDecode(body)
            if jsonBody then
                if code == 200 then
                    return true, jsonBody
                else
                    return false, jsonBody
                end
            else
                return false, body
            end
        end,
        quickRequest = function(self, model, messages, responseFormat)
            local headers = {
                ["Authorization"] = "Bearer " .. self.key
            }
            local data = {
                model = model,
                messages = messages,
                response_format = {
                    type = responseFormat
                }
            }
            local url = self.baseUrl .. "/chat/completions"
            local code, body, headers = self.http:Post(url, data, headers)
            local jsonBody = self.http:JSONDecode(body)
            if jsonBody then
                if code == 200 then
                    return true, jsonBody.choices[1]
                else
                    return false, jsonBody.error.message
                end
            else
                return false, body
            end
        end
    }
end
