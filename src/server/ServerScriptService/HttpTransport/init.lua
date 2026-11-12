--!strict
local HttpTransport = {}

local HttpService = game:GetService("HttpService")

export type HttpMethod = "GET" | "POST" | "PATCH" | "DELETE"

export type HttpRequest = {
    Url: string,
    Method: HttpMethod,
    Headers: {[string]: string | Secret}?,
    Body: string?
}

export type HttpResult = {
    Ok: boolean,
    StatusCode: number?,
    Body: string?,
    Error: string?
}

export type HttpResponse = {
    Success: boolean,
    StatusCode: number,
    StatusMessage: string?,
    Body: string?
}

function HttpTransport.Request(request: HttpRequest): HttpResult
    local didSend, responseOrError = pcall(function()
        return HttpService:RequestAsync({
            Url = request.Url,
            Method = request.Method,
            Headers = request.Headers,
            Body = request.Body,
        })
    end)

    if not didSend then
        return table.freeze({
            Ok = false,
            Error = tostring(responseOrError),
        })
    end

    return HttpTransport.ToResult(responseOrError :: HttpResponse)
end

function HttpTransport.ToResult(response: HttpResponse): HttpResult
    local isSuccessful = response.StatusCode >= 200 and response.StatusCode < 300
    local errorText: string? = nil
    if not isSuccessful then
        errorText = response.StatusMessage or `HTTP {response.StatusCode}`
    end

    return table.freeze({
        Ok = isSuccessful,
        StatusCode = response.StatusCode,
        Body = response.Body,
        Error = errorText,
    })
end

function HttpTransport.Get(url: string, headers: {[string]: string | Secret}?): HttpResult
    return HttpTransport.Request({ Url = url, Method = "GET", Headers = headers })
end

function HttpTransport.Post(url: string, body: string, headers: {[string]: string | Secret}?): HttpResult
    return HttpTransport.Request({ Url = url, Method = "POST", Headers = headers, Body = body })
end

function HttpTransport.Patch(url: string, body: string, headers: {[string]: string | Secret}?): HttpResult
    return HttpTransport.Request({ Url = url, Method = "PATCH", Headers = headers, Body = body })
end

function HttpTransport.Delete(url: string, headers: {[string]: string | Secret}?): HttpResult
    return HttpTransport.Request({ Url = url, Method = "DELETE", Headers = headers })
end

table.freeze(HttpTransport)
return HttpTransport
