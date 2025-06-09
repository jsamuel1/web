<?
--[[
*  Pi-hole: A black hole for Internet advertisements
*  (c) 2024 Pi-hole, LLC (https://pi-hole.net)
*  Network-wide ad blocking via your own hardware.
*
*  Model Context Protocol (MCP) Server Endpoint
*  This file provides MCP support for Pi-hole web interface
*
*  This file is copyright under the latest version of the EUPL.
*  Please see LICENSE file for your rights under this license.
--]]

-- Load the API helper module
local mcp_api = require('scripts.lua.mcp_api')
local json = mcp_api.json

-- MCP Protocol Handler with real API integration
local function handle_mcp_request(request)
    local method = request.method
    local params = request.params or {}
    local id = request.id
    
    -- Initialize response
    if method == "initialize" then
        return {
            jsonrpc = "2.0",
            id = id,
            result = {
                protocolVersion = "2024-11-05",
                capabilities = {
                    resources = {},
                    tools = {}
                },
                serverInfo = {
                    name = "pi-hole",
                    version = "6.0"
                }
            }
        }
    
    -- List available resources with full API coverage
    elseif method == "resources/list" then
        return {
            jsonrpc = "2.0",
            id = id,
            result = {
                resources = {
                    -- Statistics Resources
                    {
                        uri = "pihole://stats/summary",
                        name = "Pi-hole Statistics Summary",
                        description = "Overall DNS query statistics and blocking metrics",
                        mimeType = "application/json"
                    },
                    {
                        uri = "pihole://stats/query_types",
                        name = "Query Types Statistics",
                        description = "Breakdown of DNS query types (A, AAAA, PTR, etc.)",
                        mimeType = "application/json"
                    },
                    {
                        uri = "pihole://stats/upstreams",
                        name = "Upstream DNS Statistics",
                        description = "Statistics for upstream DNS servers",
                        mimeType = "application/json"
                    },
                    {
                        uri = "pihole://stats/top_clients",
                        name = "Top Clients Statistics",
                        description = "Most active DNS clients",
                        mimeType = "application/json"
                    },
                    {
                        uri = "pihole://stats/top_domains",
                        name = "Top Domains Statistics", 
                        description = "Most queried domains",
                        mimeType = "application/json"
                    },
                    {
                        uri = "pihole://history/queries",
                        name = "Query History",
                        description = "DNS query history over time",
                        mimeType = "application/json"
                    },
                    {
                        uri = "pihole://history/clients",
                        name = "Client History",
                        description = "Client activity history over time",
                        mimeType = "application/json"
                    },
                    -- Configuration Resources
                    {
                        uri = "pihole://config/current",
                        name = "Current Configuration",
                        description = "Current Pi-hole configuration settings",
                        mimeType = "application/json"
                    },
                    -- Management Resources
                    {
                        uri = "pihole://domains/all",
                        name = "All Domains",
                        description = "All configured domains (blocked and allowed)",
                        mimeType = "application/json"
                    },
                    {
                        uri = "pihole://domains/blocked",
                        name = "Blocked Domains",
                        description = "Currently blocked domains and patterns",
                        mimeType = "application/json"
                    },
                    {
                        uri = "pihole://domains/allowed",
                        name = "Allowed Domains",
                        description = "Currently allowed domains and patterns",
                        mimeType = "application/json"
                    },
                    {
                        uri = "pihole://lists/all",
                        name = "All Lists",
                        description = "All configured blocklists and allowlists",
                        mimeType = "application/json"
                    },
                    {
                        uri = "pihole://clients/all",
                        name = "All Clients",
                        description = "All configured network clients",
                        mimeType = "application/json"
                    },
                    {
                        uri = "pihole://groups/all",
                        name = "All Groups",
                        description = "All configured client and domain groups",
                        mimeType = "application/json"
                    },
                    -- System Resources
                    {
                        uri = "pihole://system/info",
                        name = "System Information",
                        description = "Pi-hole system information and status",
                        mimeType = "application/json"
                    },
                    {
                        uri = "pihole://system/ftl",
                        name = "FTL Information",
                        description = "FTL daemon information and statistics",
                        mimeType = "application/json"
                    },
                    {
                        uri = "pihole://system/version",
                        name = "Version Information",
                        description = "Pi-hole component versions",
                        mimeType = "application/json"
                    },
                    {
                        uri = "pihole://network/gateway",
                        name = "Network Gateway",
                        description = "Network gateway information",
                        mimeType = "application/json"
                    },
                    {
                        uri = "pihole://network/interfaces",
                        name = "Network Interfaces",
                        description = "Network interface information",
                        mimeType = "application/json"
                    },
                    {
                        uri = "pihole://system/messages",
                        name = "System Messages",
                        description = "Pi-hole system messages and alerts",
                        mimeType = "application/json"
                    }
                }
            }
        }
    
    -- Read resource content using real API calls
    elseif method == "resources/read" then
        local uri = params.uri
        local content = ""
        local mimeType = "application/json"
        
        -- Map URI to API endpoint
        local endpoint_map = {
            ["pihole://stats/summary"] = "/stats/summary",
            ["pihole://stats/query_types"] = "/stats/query_types", 
            ["pihole://stats/upstreams"] = "/stats/upstreams",
            ["pihole://stats/top_clients"] = "/stats/top_clients",
            ["pihole://stats/top_domains"] = "/stats/top_domains",
            ["pihole://history/queries"] = "/history",
            ["pihole://history/clients"] = "/history/clients",
            ["pihole://config/current"] = "/config",
            ["pihole://domains/all"] = "/domains",
            ["pihole://lists/all"] = "/lists",
            ["pihole://clients/all"] = "/clients",
            ["pihole://groups/all"] = "/groups",
            ["pihole://system/info"] = "/info/system",
            ["pihole://system/ftl"] = "/info/ftl",
            ["pihole://system/version"] = "/info/version",
            ["pihole://network/gateway"] = "/network/gateway",
            ["pihole://network/interfaces"] = "/network/interfaces",
            ["pihole://system/messages"] = "/messages"
        }
        
        local endpoint = endpoint_map[uri]
        if endpoint then
            local data, error_msg = mcp_api.call_pihole_api(endpoint, "GET")
            if data then
                -- Handle special filtering for domain resources
                if uri == "pihole://domains/blocked" then
                    data = mcp_api.filter_domains(data, "deny")
                elseif uri == "pihole://domains/allowed" then
                    data = mcp_api.filter_domains(data, "allow")
                end
                
                content = json.encode(data)
            else
                return {
                    jsonrpc = "2.0",
                    id = id,
                    error = {
                        code = -32603,
                        message = "Internal error: " .. (error_msg or "Unknown error")
                    }
                }
            end
        else
            return {
                jsonrpc = "2.0",
                id = id,
                error = {
                    code = -32602,
                    message = "Resource not found: " .. uri
                }
            }
        end
        
        return {
            jsonrpc = "2.0",
            id = id,
            result = {
                contents = {
                    {
                        uri = uri,
                        mimeType = mimeType,
                        text = content
                    }
                }
            }
        }
    
    -- List available tools
    elseif method == "tools/list" then
        return {
            jsonrpc = "2.0",
            id = id,
            result = {
                tools = {
                    -- Resource Reader Tools (GET operations for each resource)
                    {
                        name = "get_stats_summary",
                        description = "Get Pi-hole statistics summary",
                        inputSchema = {
                            type = "object",
                            properties = {}
                        }
                    },
                    {
                        name = "get_query_types",
                        description = "Get DNS query types breakdown",
                        inputSchema = {
                            type = "object",
                            properties = {}
                        }
                    },
                    {
                        name = "get_upstreams",
                        description = "Get upstream DNS server statistics",
                        inputSchema = {
                            type = "object",
                            properties = {}
                        }
                    },
                    {
                        name = "get_top_clients",
                        description = "Get top DNS clients",
                        inputSchema = {
                            type = "object",
                            properties = {}
                        }
                    },
                    {
                        name = "get_top_domains",
                        description = "Get top queried domains",
                        inputSchema = {
                            type = "object",
                            properties = {}
                        }
                    },
                    {
                        name = "get_all_domains",
                        description = "Get all configured domains",
                        inputSchema = {
                            type = "object",
                            properties = {}
                        }
                    },
                    {
                        name = "get_blocked_domains",
                        description = "Get blocked domains only",
                        inputSchema = {
                            type = "object",
                            properties = {}
                        }
                    },
                    {
                        name = "get_allowed_domains",
                        description = "Get allowed domains only",
                        inputSchema = {
                            type = "object",
                            properties = {}
                        }
                    },
                    {
                        name = "get_system_info",
                        description = "Get system information",
                        inputSchema = {
                            type = "object",
                            properties = {}
                        }
                    },
                    -- Management Tools
                    {
                        name = "block_domain",
                        description = "Add a domain to the blocklist",
                        inputSchema = {
                            type = "object",
                            properties = {
                                domain = {
                                    type = "string",
                                    description = "Domain name to block (e.g., example.com)"
                                },
                                comment = {
                                    type = "string",
                                    description = "Optional comment for the blocked domain"
                                }
                            },
                            required = {"domain"}
                        }
                    },
                    {
                        name = "allow_domain",
                        description = "Add a domain to the allowlist",
                        inputSchema = {
                            type = "object",
                            properties = {
                                domain = {
                                    type = "string",
                                    description = "Domain name to allow (e.g., example.com)"
                                },
                                comment = {
                                    type = "string",
                                    description = "Optional comment for the allowed domain"
                                }
                            },
                            required = {"domain"}
                        }
                    },
                    {
                        name = "block_regex",
                        description = "Add a regex pattern to the blocklist",
                        inputSchema = {
                            type = "object",
                            properties = {
                                pattern = {
                                    type = "string",
                                    description = "Regex pattern to block"
                                },
                                comment = {
                                    type = "string",
                                    description = "Optional comment for the blocked pattern"
                                }
                            },
                            required = {"pattern"}
                        }
                    },
                    -- Query and Analysis Tools
                    {
                        name = "query_logs",
                        description = "Search DNS query logs",
                        inputSchema = {
                            type = "object",
                            properties = {
                                domain = {
                                    type = "string",
                                    description = "Filter by domain name"
                                },
                                client = {
                                    type = "string", 
                                    description = "Filter by client IP address"
                                },
                                limit = {
                                    type = "number",
                                    description = "Maximum number of results to return",
                                    default = 100
                                }
                            }
                        }
                    },
                    {
                        name = "check_domain_status",
                        description = "Check if a domain is blocked or allowed",
                        inputSchema = {
                            type = "object",
                            properties = {
                                domain = {
                                    type = "string",
                                    description = "Domain to check"
                                }
                            },
                            required = {"domain"}
                        }
                    }
                }
            }
        }
    
    -- Execute tool with comprehensive coverage
    elseif method == "tools/call" then
        local tool_name = params.name
        local args = params.arguments or {}
        
        -- Resource Reader Tools (map to resource URIs)
        local resource_tool_map = {
            ["get_stats_summary"] = "pihole://stats/summary",
            ["get_query_types"] = "pihole://stats/query_types",
            ["get_upstreams"] = "pihole://stats/upstreams",
            ["get_top_clients"] = "pihole://stats/top_clients",
            ["get_top_domains"] = "pihole://stats/top_domains",
            ["get_all_domains"] = "pihole://domains/all",
            ["get_blocked_domains"] = "pihole://domains/blocked",
            ["get_allowed_domains"] = "pihole://domains/allowed",
            ["get_system_info"] = "pihole://system/info"
        }
        
        -- Handle resource reader tools
        if resource_tool_map[tool_name] then
            local uri = resource_tool_map[tool_name]
            local endpoint_map = {
                ["pihole://stats/summary"] = "/stats/summary",
                ["pihole://stats/query_types"] = "/stats/query_types", 
                ["pihole://stats/upstreams"] = "/stats/upstreams",
                ["pihole://stats/top_clients"] = "/stats/top_clients",
                ["pihole://stats/top_domains"] = "/stats/top_domains",
                ["pihole://domains/all"] = "/domains",
                ["pihole://system/info"] = "/info/system"
            }
            
            local endpoint = endpoint_map[uri]
            if endpoint then
                local data, error_msg = mcp_api.call_pihole_api(endpoint, "GET")
                if data then
                    -- Handle special filtering for domain resources
                    if uri == "pihole://domains/blocked" then
                        data = mcp_api.filter_domains(data, "deny")
                    elseif uri == "pihole://domains/allowed" then
                        data = mcp_api.filter_domains(data, "allow")
                    end
                    
                    return {
                        jsonrpc = "2.0",
                        id = id,
                        result = {
                            content = {
                                {
                                    type = "text",
                                    text = json.encode(data)
                                }
                            }
                        }
                    }
                else
                    return {
                        jsonrpc = "2.0",
                        id = id,
                        result = {
                            isError = true,
                            content = {
                                {
                                    type = "text",
                                    text = "Error: " .. (error_msg or "Unknown error")
                                }
                            }
                        }
                    }
                end
            end
        
        -- Management Tools
        elseif tool_name == "block_domain" then
            local domain = args.domain
            local comment = args.comment or ""
            
            if not domain then
                return {
                    jsonrpc = "2.0",
                    id = id,
                    result = {
                        isError = true,
                        content = {
                            {
                                type = "text",
                                text = "Error: domain parameter is required"
                            }
                        }
                    }
                }
            end
            
            local data, error_msg = mcp_api.call_pihole_api("/domains/deny/exact", "POST", {
                domain = {domain},
                comment = comment
            })
            
            if data then
                return {
                    jsonrpc = "2.0",
                    id = id,
                    result = {
                        content = {
                            {
                                type = "text",
                                text = "Successfully added domain '" .. domain .. "' to blocklist" .. (comment ~= "" and " with comment: " .. comment or "")
                            }
                        }
                    }
                }
            else
                return {
                    jsonrpc = "2.0",
                    id = id,
                    result = {
                        isError = true,
                        content = {
                            {
                                type = "text",
                                text = "Error blocking domain: " .. (error_msg or "Unknown error")
                            }
                        }
                    }
                }
            end
            
        elseif tool_name == "allow_domain" then
            local domain = args.domain
            local comment = args.comment or ""
            
            if not domain then
                return {
                    jsonrpc = "2.0",
                    id = id,
                    result = {
                        isError = true,
                        content = {
                            {
                                type = "text",
                                text = "Error: domain parameter is required"
                            }
                        }
                    }
                }
            end
            
            local data, error_msg = mcp_api.call_pihole_api("/domains/allow/exact", "POST", {
                domain = {domain},
                comment = comment
            })
            
            if data then
                return {
                    jsonrpc = "2.0",
                    id = id,
                    result = {
                        content = {
                            {
                                type = "text",
                                text = "Successfully added domain '" .. domain .. "' to allowlist" .. (comment ~= "" and " with comment: " .. comment or "")
                            }
                        }
                    }
                }
            else
                return {
                    jsonrpc = "2.0",
                    id = id,
                    result = {
                        isError = true,
                        content = {
                            {
                                type = "text",
                                text = "Error allowing domain: " .. (error_msg or "Unknown error")
                            }
                        }
                    }
                }
            end
            
        elseif tool_name == "block_regex" then
            local pattern = args.pattern
            local comment = args.comment or ""
            
            if not pattern then
                return {
                    jsonrpc = "2.0",
                    id = id,
                    result = {
                        isError = true,
                        content = {
                            {
                                type = "text",
                                text = "Error: pattern parameter is required"
                            }
                        }
                    }
                }
            end
            
            local data, error_msg = mcp_api.call_pihole_api("/domains/deny/regex", "POST", {
                domain = {pattern},
                comment = comment
            })
            
            if data then
                return {
                    jsonrpc = "2.0",
                    id = id,
                    result = {
                        content = {
                            {
                                type = "text",
                                text = "Successfully added regex pattern '" .. pattern .. "' to blocklist" .. (comment ~= "" and " with comment: " .. comment or "")
                            }
                        }
                    }
                }
            else
                return {
                    jsonrpc = "2.0",
                    id = id,
                    result = {
                        isError = true,
                        content = {
                            {
                                type = "text",
                                text = "Error blocking regex: " .. (error_msg or "Unknown error")
                            }
                        }
                    }
                }
            end
            
        elseif tool_name == "query_logs" then
            local domain_filter = args.domain
            local client_filter = args.client
            local limit = args.limit or 100
            
            -- Build query parameters
            local query_params = "?limit=" .. limit
            if domain_filter then
                query_params = query_params .. "&domain=" .. domain_filter
            end
            if client_filter then
                query_params = query_params .. "&client=" .. client_filter
            end
            
            local data, error_msg = mcp_api.call_pihole_api("/queries" .. query_params, "GET")
            
            if data then
                return {
                    jsonrpc = "2.0",
                    id = id,
                    result = {
                        content = {
                            {
                                type = "text",
                                text = "DNS Query Logs:\n" .. json.encode(data)
                            }
                        }
                    }
                }
            else
                return {
                    jsonrpc = "2.0",
                    id = id,
                    result = {
                        isError = true,
                        content = {
                            {
                                type = "text",
                                text = "Error querying logs: " .. (error_msg or "Unknown error")
                            }
                        }
                    }
                }
            end
            
        elseif tool_name == "check_domain_status" then
            local domain = args.domain
            
            if not domain then
                return {
                    jsonrpc = "2.0",
                    id = id,
                    result = {
                        isError = true,
                        content = {
                            {
                                type = "text",
                                text = "Error: domain parameter is required"
                            }
                        }
                    }
                }
            end
            
            -- Check domain status by querying domains list
            local data, error_msg = mcp_api.call_pihole_api("/domains", "GET")
            
            if data and data.domains then
                local status = "not configured"
                for _, domain_entry in ipairs(data.domains) do
                    if domain_entry.domain == domain then
                        status = domain_entry.type .. " (" .. domain_entry.kind .. ")"
                        if not domain_entry.enabled then
                            status = status .. " - disabled"
                        end
                        break
                    end
                end
                
                return {
                    jsonrpc = "2.0",
                    id = id,
                    result = {
                        content = {
                            {
                                type = "text",
                                text = "Domain '" .. domain .. "' status: " .. status
                            }
                        }
                    }
                }
            else
                return {
                    jsonrpc = "2.0",
                    id = id,
                    result = {
                        isError = true,
                        content = {
                            {
                                type = "text",
                                text = "Error checking domain status: " .. (error_msg or "Unknown error")
                            }
                        }
                    }
                }
            end
        else
            return {
                jsonrpc = "2.0",
                id = id,
                error = {
                    code = -32602,
                    message = "Unknown tool: " .. tool_name
                }
            }
        end
    
    else
        return {
            jsonrpc = "2.0",
            id = id,
            error = {
                code = -32601,
                message = "Method not found: " .. method
            }
        }
    end
end

-- Main request handling
if mg.request_info.request_method == "POST" then
    -- Handle MCP JSON-RPC requests
    local body = mg.read()
    
    if not body or body == "" then
        mg.write("HTTP/1.1 400 Bad Request\r\n")
        mg.write("Content-Type: application/json\r\n")
        mg.write("\r\n")
        mg.write(json.encode({
            jsonrpc = "2.0",
            error = {
                code = -32700,
                message = "Parse error: Empty request body"
            }
        }))
        return
    end
    
    local success, request = pcall(json.decode, body)
    if not success then
        mg.write("HTTP/1.1 400 Bad Request\r\n")
        mg.write("Content-Type: application/json\r\n")
        mg.write("\r\n")
        mg.write(json.encode({
            jsonrpc = "2.0",
            error = {
                code = -32700,
                message = "Parse error: Invalid JSON"
            }
        }))
        return
    end
    
    local response = handle_mcp_request(request)
    
    mg.write("HTTP/1.1 200 OK\r\n")
    mg.write("Content-Type: application/json\r\n")
    mg.write("Access-Control-Allow-Origin: *\r\n")
    mg.write("Access-Control-Allow-Methods: POST, GET, OPTIONS\r\n")
    mg.write("Access-Control-Allow-Headers: Content-Type\r\n")
    mg.write("\r\n")
    mg.write(json.encode(response))

elseif mg.request_info.request_method == "GET" then
    -- Handle Server-Sent Events for MCP notifications
    mg.write("HTTP/1.1 200 OK\r\n")
    mg.write("Content-Type: text/event-stream\r\n")
    mg.write("Cache-Control: no-cache\r\n")
    mg.write("Connection: keep-alive\r\n")
    mg.write("Access-Control-Allow-Origin: *\r\n")
    mg.write("\r\n")
    
    -- Send initial connection confirmation
    mg.write("data: " .. json.encode({type = "connected", message = "Pi-hole MCP server connected"}) .. "\n\n")
    
    -- Keep connection alive with periodic pings
    -- In a real implementation, this would handle notifications
    local count = 0
    while count < 10 do  -- Limit for demo purposes
        mg.sleep(5000)  -- 5 second intervals
        mg.write("data: " .. json.encode({type = "ping", timestamp = os.time()}) .. "\n\n")
        count = count + 1
    end

elseif mg.request_info.request_method == "OPTIONS" then
    -- Handle CORS preflight requests
    mg.write("HTTP/1.1 200 OK\r\n")
    mg.write("Access-Control-Allow-Origin: *\r\n")
    mg.write("Access-Control-Allow-Methods: POST, GET, OPTIONS\r\n")
    mg.write("Access-Control-Allow-Headers: Content-Type\r\n")
    mg.write("Content-Length: 0\r\n")
    mg.write("\r\n")

else
    -- Method not allowed
    mg.write("HTTP/1.1 405 Method Not Allowed\r\n")
    mg.write("Content-Type: application/json\r\n")
    mg.write("\r\n")
    mg.write(json.encode({
        error = "Method not allowed. Use POST for MCP requests or GET for SSE."
    }))
end
?>
