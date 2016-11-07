local upstream_share = ngx.shared.www_upstream_dict;
local worker_pid_dict = ngx.shared.worker_pid_dict;

require "dumper"
local json = require("json");
local http = require("resty.http");

local upstream = require "ngx.upstream"
local get_servers = upstream.get_servers
local get_upstreams = upstream.get_upstreams

local us = get_upstreams()
-- local concat = table.concat

function mysplit(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
                i = i + 1
        end
        return t
end






function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end



function json_call2(url, method, ...)
  local JSONRequestArray = {
    id=tostring(math.random()),
    ["method"]=method,
    params = ...
  }

  local httpResponse, result , code
  
  local ltn12 = require('ltn12')
  local resultChunks = {}

  local httpc = http.new()

  local res, err = httpc:request_uri(url, {
    method = "GET",   
    headers = {
      ["Content-Type"] = "application/json",
    }
  })

  if not res then
    ngx.say("failed to request: ", err)
    return
  end

--  httpResponse = table.concat(res.body)
  httpResponse = res.body  
  -- Check the http response code
  -- ngx.say("httpResponse = " .. httpResponse)  

  if (res.status~=200) then
    return nil, "HTTP ERROR: " .. res.status
  end
  -- And decode the httpResponse and check the JSON RPC result code
  result = json.decode( httpResponse )

  -- ngx.say("result=", DataDumper(result) , "<br>")   

  if result then
    return result, nil
  else
    return result, error
  end
end



function status_parsing()

    local dyn_status = {}
    for _, u in ipairs(us) do
        local srvs, err = upstream.get_primary_peers(u)
        if not srvs then
            ngx.say("failed to get servers in upstream ", u)
        else
          for _, srv in ipairs(srvs) do
            if tostring(srv.down) == "true" then
              dyn_status[srv.name] = 0
            else
              dyn_status[srv.name] = 1
            end
          end      
        end
    end

     local health_check, error2 = json_call2("http://127.0.0.1/status?format=json")

     local down_count = health_check.servers.generation 
     
     -- ngx.print(down_count);

    --ngx.say("result=", DataDumper(health_check) , "<br>")   


    local result, error = json_call2("http://127.0.0.1/vtstatus/format/json","GET")

    for i in pairs(result.upstreamZones) do   

        for k in pairs(result.upstreamZones[i]) do
          
    --      ngx.print(i , ",", k , " <br>")

        if down_count > 0 then
           for ii in pairs(health_check.servers.server) do    
              local name     = health_check.servers.server[ii].name 
              local upstream = health_check.servers.server[ii].upstream
              local status   = health_check.servers.server[ii].status
              
              if status == "down" and result.upstreamZones[i][k].server == name and i == upstream   then  
                 result.upstreamZones[i][k].down = "down"

              end
            end
        end

    --      if down_count > 0  and 
            
            result.upstreamZones[i][k].dyn_status = dyn_status[result.upstreamZones[i][k].server] 
        end
    end   

    local result = json.encode(result)
    -- ngx.log(ngx.ERR, result)
    local upstream_status_dict = ngx.shared.upstream_status_dict;
    upstream_status_dict:set("status_json",result)
end




local delay = 1
local worker_pid = ngx.worker.pid()

worker_pid_dict:set(worker_pid , worker_pid, 0 )

worker_pid_dict:set("status_parsing_worker" , worker_pid, 0 )


local handler
handler = function (premature)
    -- do some routine job in Lua just like a cron job           
    

    local status_parsing_worker = worker_pid_dict:get("status_parsing_worker");

    

    if  worker_pid ==  status_parsing_worker then
      status_parsing();
      -- ngx.log(ngx.ERR, "status_parsing_worker : " , status_parsing_worker );
    end


    for kkk, vvv in ipairs(upstream_share:get_keys(100)) do
        
        local status = upstream_share:get(vvv)
       -- ngx.log(ngx.INFO, worker_pid .. " key [" , kkk  , "] => ", vvv, " -> ", status)
        local split_data = mysplit(vvv , ",")

        local pid           = split_data[1]
        local upstream_name = split_data[2]
        local ipaddr        = split_data[3]
        local index         = split_data[4]                
        
        if  tonumber(pid) == tonumber(worker_pid)  then
            ngx.log(ngx.INFO, pid, "/ ", upstream_name , " / ", ipaddr ," / ", status ," / ", index )

            if string.match( status , "down" ) then                
                local upstream_ctl, err = upstream.set_peer_down(upstream_name, false, index, true)                               
                if not upstream_ctl then
                     ngx.log(ngx.ERR, "upstream.set_peer_down()" , upstream_name , " / ", ipaddr ," / ", status ," / ", index  , err)
                else
                    upstream_share:delete(vvv)  
                end
            elseif string.match ( status, "up" ) then                 
                local upstream_ctl, err = upstream.set_peer_down(upstream_name, false, index, false)                 
                if not upstream_ctl then                
                    ngx.log(ngx.ERR, "upstream.set_peer_down()" , upstream_name , " / ", ipaddr ," / ", status ," / ", index  , err)                    
                else
                   upstream_share:delete(vvv)   
                end

            end

         
       end
   end


    if premature then
        return
    end
    local ok, err = ngx.timer.at(delay, handler)
    if not ok then
        ngx.log(ngx.ERR, "failed to create the timer: ", err)
    return
    end
end

local ok, err = ngx.timer.at(delay, handler)
if not ok then
    ngx.log(ngx.ERR, "failed to create the timer: ", err)
    return
end


-- upstream_share:init_background_thread()
-- https_upstream:init_background_thread()