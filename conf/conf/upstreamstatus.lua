

local args = ngx.req.get_uri_args()
local i_stream, i_peer, i_name, i_act,  ok, err, cdone, i_temp

i_stream = args["stream"] -- upstream name
i_peer = args["peer"]     -- number
i_name = args["name"]     -- resolved
i_act  = args["act"]  -- action
i_debug  = args["debug"]  -- action


-- ngx.say ("stream : " , i_stream , "\n")
-- ngx.say ("name : " , i_name , "\n")
-- ngx.say ("act : " , i_act , "\n")

local concat = table.concat
local upstream = require "ngx.upstream"
local get_servers = upstream.get_servers
local get_upstreams = upstream.get_upstreams

local us = get_upstreams()


-- local http = require("socket.http")
-- local rocks = require "luarocks.loader"

-- package.path=package.path .. "/usr/local/lib/lua/5.1/;;"

local json = require("json");
local http = require("socket.http");


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

function json_call(url, method, ...)
  local JSONRequestArray = {
    id=tostring(math.random()),
    ["method"]=method,
    params = ...
  }
  local httpResponse, result , code
  local jsonRequest = json.encode(JSONRequestArray)
  -- We use the sophisticated http.request form (with ltn12 sources and sinks) so that
  -- we can set the content-type to text/plain. While this shouldn't strictly-speaking be true,
  -- it seems a good idea (Xavante won't work w/out a content-type header, although a patch
  -- is needed to Xavante to make it work with text/plain)
  local ltn12 = require('ltn12')
  local resultChunks = {}
  httpResponse, code = http.request(
    { ['url'] = url,
      sink = ltn12.sink.table(resultChunks),
      method = 'GET',
      headers = { ['content-type']='application/json', ['content-length']=string.len(jsonRequest) },
      source = ltn12.source.string(jsonRequest)
    }
  )
  httpResponse = table.concat(resultChunks)
  -- Check the http response code
  -- ngx.say("httpResponse = " .. httpResponse)  

  if (code~=200) then
    return nil, "HTTP ERROR: " .. code
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


ngx.say(package.cpath .. "<br>")
--ngx.say(package.path)
require "dumper"


local result, error = json_call("http://127.0.0.1/vtstatus/format/json","GET")

-- ngx.say("result=", DataDumper(result.upstreamZones) , "<br>") 
-- ngx.say("error=", DataDumper(error) , "<br>") 
ngx.print('<html><head> <meta charset=utf-8> <title>nginx status monitor</title> <style> body { background: white; color: black; font-family: \'Open Sans\', Helvetica, Arial, sans-serif } h1 { margin: .5em 0 0 0 } h2 { margin: .8em 0 .3em 0 } h3 { margin: .5em 0 .3em 0 } table { font-size: .8em; margin: .5em 0; border-collapse: collapse; border-bottom: 1px #f2f4f7 solid } thead th { font-size: 1em; background: #f2f4f7; padding: .2em .5em; border: .4em solid #FFF } tbody tr.odd { background: #f5f5f5 } tbody th { text-align: left } tbody td { height: 1.5em; text-align: right } tbody td.key { font-size: 1em; background: #f2f4f7; padding: .2em .5em; border: .4em solid #FFF } </style></head>')
ngx.print("<script> function getReqSec(key,value){ var now = Number(value) - Number(localStorage[key]); localStorage[key]=value; return now }; function bTh(a) { var c = 1024; if (typeof a !== 'number') { return a } if (a < c) { return a + ' B' } if (a < (c * c)) { return (a / c).toFixed(1) +  ' KiB' } if (a < (c * c * c)) { return (a / (c * c)).toFixed(1) + ' MiB' } return (a / (c * c * c)).toFixed(2) + ' GiB' }</script>")

ngx.print('<link rel="stylesheet" href="http://fonts.googleapis.com/css?family=Open+Sans:300,400,700,800" type="text/css">')
ngx.print('<body> <h1><img width="40px" src="https://avatars1.githubusercontent.com/u/10335008?v=3&s=84"> Nginx Status Monitor</h1>')

ngx.print('<div id="serverInfos"><h2>Server main status</h2> <table><thead><tr> <th rowspan="2">Version</th> <th rowspan="2">Uptime</th> <th colspan="4">Connections</th> <th colspan="5">Requests</th></tr><tr><th>active</th><th>reading</th><th>writing</th><th>waiting</th><th>accepted</th><th>handled</th><th>Total</th><th>Req/s</th></tr></thead><tbody>')
ngx.print('<tr><td>' .. result.nginxVersion .. '</td>')
-- ngx.print('<td>' .. result.connections .. '</td>')
-- ngx.print("Nginx Version = " .. result.nginxVersion)
-- ngx.print("<br><span style=\"background:green; color:white;\">connections -> ")
uptime = os.date("!%X" , math.floor( (result.nowMsec - result.loadMsec) / 1000) )
ngx.print('<td>' .. uptime .. '</td>')
ngx.print('<td>' .. result.connections.active .. '</td>')
ngx.print('<td>' .. result.connections.reading .. '</td>')
ngx.print('<td>' .. result.connections.writing .. '</td>')
ngx.print('<td>' .. result.connections.waiting .. '</td>')
ngx.print('<td>' .. result.connections.handled .. '</td>')
ngx.print('<td>' .. result.connections.accepted .. '</td>')
ngx.print('<td>' .. result.connections.requests .. '</td>')




-- ngx.print("<script> var server_main_status_req = Number(" .. result.connections.requests ..") - Number(localStorage['server_main_status_req_pre']) ;</script>")
-- ngx.print("<script> localStorage['server_main_status_req_pre']=" .. result.connections.requests  .. ";</script>")
-- ngx.print("<td> <script> document.write(server_main_status_req);</script></td></tr></tbody></table></div>")

ngx.print("<td> <script> document.write(getReqSec('server_main_status_req',".. result.connections.requests  .. "));</script></td></tr></tbody></table></div>")

ngx.print('<div id="serverZones"><h2>Server zones</h2><table>  <thead><tr><th rowspan="2">Zone</th><th colspan="2">Requests</th><th colspan="6">Responses</th><th colspan="4">Traffic</th></tr><tr><th>Total</th><th>Req/s</th><th>1xx</th><th>2xx</th><th>3xx</th><th>4xx</th><th>5xx</th><th>Total</th><th>Sent</th><th>Rcvd</th><th>Sent/s</th><th>Rcvd/s</th></tr></thead><tbody>')
 


-- ngx.print("<br><span style=\"background:green; color:white;\">serverZones ->  ")

for i in pairs(result.serverZones) do   
    
    ngx.say("<tr><td class='odd'>  " .. i  .. "</td>");
    -- ngx.say(result.serverZones.i);    
    ngx.say("<td>" , result.serverZones[i].requestCounter , "</td>") 
    ngx.say("<td>" , "N/A" , "</td>") 
    
    local reponse_sum = 0
    for k, v in spairs(result.serverZones[i].responses) do   
        reponse_sum = reponse_sum + v        
        ngx.say(" <td> "  .. v  .. "</td>");                            
    end
    ngx.say("<td>" , reponse_sum , "</td>")     
    ngx.say("<td>" , result.serverZones[i].inBytes , "</td>")     
    ngx.say("<td>" , result.serverZones[i].outBytes , "</td>")         
    ngx.say("<td>" , "N/A" , "</td>")    
    ngx.say("<td>" , "N/A", "</tr>")
end    
ngx.say("</tbody></table></div>")

ngx.print('<div id="upstreamZones"><h2>Upstreams</h2>')



for i in pairs(result.upstreamZones) do   
    ngx.say("<h3>  " .. i  .. " </h3>");
    ngx.say('<table><thead><tr><th rowspan="2">Server</th><th rowspan="2">State</th><th rowspan="2">Response Time</th><th rowspan="2">Weight</th><th rowspan="2">MaxFails</th><th rowspan="2">FailTimeout</th><th colspan="2">Requests</th><th colspan="6">Responses</th><th colspan="4">Traffic</th></tr><tr><th>Total</th><th>Req/s</th><th>1xx</th><th>2xx</th><th>3xx</th><th>4xx</th><th>5xx</th><th>Total</th><th>Sent</th><th>Rcvd</th><th>Sent/s</th><th>Rcvd/s</th></tr></thead><tbody>')  
    -- ngx.say("result=", DataDumper(result.upstreamZones[i]) , "<br>") 

    for k in pairs(result.upstreamZones[i]) do

      ngx.say("<tr><td>" .. result.upstreamZones[i][k].server  .. "</td>")
      ngx.say("<td>" .. "state"  .. "</td>")
      ngx.say("<td>" .. result.upstreamZones[i][k].responeMsec  .. "</td>")
      ngx.say("<td>" .. result.upstreamZones[i][k].weight  .. "</td>")
      ngx.say("<td>" .. result.upstreamZones[i][k].maxFails  .. "</td>")
      ngx.say("<td>" .. result.upstreamZones[i][k].failTimeout  .. "</td>")
      ngx.say("<td>" .. result.upstreamZones[i][k].requestCounter  .. "</td>")      
      
      ngx.say("<td>" .. "reqs"  .. "</td>")      
      -- ngx.say("result=", DataDumper(result.upstreamZones[i][k].responses) , "<br>") 
      local status_sum = 0;
        for code, status in pairs(result.upstreamZones[i][k].responses) do 
            status_sum = status_sum + status
            ngx.say("<td>" .. status .. "</td>")    
        end
      ngx.say("<td>" .. status_sum .. "</td>")    
    
      ngx.say("<td>" .. result.upstreamZones[i][k].outBytes  .. "</td>")     
      ngx.say("<td>" .. result.upstreamZones[i][k].inBytes  .. "</td>") 

      ngx.say("<td>" .. "r/q" .. "</td>") 
      ngx.say("<td>" .. "r/q" .. "</td></tr>")       

    end
    

    -- ngx.say(result.serverZones.i);    
    -- for k, v in pairs(result.upstreamZones[i]) do           
    --     ngx.say("  " .. k .. " : " .. v );                            
    -- end
ngx.say("</tbody></table></div>")
end    

ngx.print("<br>");



dum = {}
dum[2] = 1
dum[1111] = 1
ngx.print("size= " .. #dum  .. "<br>")


-- ;text = cjson.encode(value)

-- ngx.say("stat_dict=", DataDumper(stat_dict) , "<br>") 
ngx.print(dum.x)

if i_debug  then
--     ngx.say("DEBUG -- upstream=", DataDumper(us) , "<br>") 
end


for _, u in ipairs(us) do
--    ngx.say("upstream ", u, ":")
    local upstream_name = u 
    local srvs, err = get_servers(u)   
    if not srvs then
        ngx.say("failed to get servers in upstream \n ", u)
    else
        local count = 0
        for _, srv in ipairs(srvs) do
            local first = true

            for k, v in pairs(srv) do

                if first then
                    first = false
                --    ngx.print(upstream_name , ":    ")
                else
                --    ngx.print(",  ")
                end
                if type(v) == "table" then
                    ngx.print(k, " = {", concat(v, ", "), "}")
                else
                   --  ngx.print(count , "." , k, " = ", v )

--                    if type(v) == "string" and string.match( v , "127.0.0.1:49184") then
                    if type(v) == "string" and string.match( v , i_name ) then                      
                    --   ngx.print (" type :", type(v));
                       ngx.print( "<br> Find out - ", v ," / ", upstream_name, "\n <br>" )
                           
                        if type(v) == "string" and string.match( i_act , "down" ) then                             
                           local upstream_ctl, err = upstream.set_peer_down(upstream_name, false, count, true)
                           ngx.say ("act : " , i_act , "\n")
                           
                        elseif type(v) == "string" and string.match( i_act , "up" ) then  
                           local upstream_ctl, err = upstream.set_peer_down(upstream_name, false, count, false) 
                            ngx.say ("act : " , i_act , "\n")
                        end
                            
                        if not upstream_ctl then
                           ngx.say("failed to down servers in upstream \n", u)
                        else
                           ngx.say("[ OK : ", count , " ]" ,upstream_ctl ,", ",err)
                        end

                    end

                end
                
            end
            ngx.print("\n")
            count = count + 1
        end
    end
end

ngx.print("<br><br>")

for _, u in ipairs(us) do
    local srvs, err = upstream.get_primary_peers(u)
--    ngx.say("<b>Peer status in upstream ", u, ":</b><br>\n<table border=\"1\" CLASS=\"smalltable\">")

    -- ngx.say("srvs=", DataDumper(srvs), "<br><br>")

--    local srvs, err = get_servers(u)
    local p_up = " style=\"background:green; color:white;\""
    local p_down = " style=\"background:red; color:white;\""
    local p_name = " style=\"background:blue; color:white;\""

--    ngx.say("srvs=", DataDumper(srvs), "<br><br>")

    
    
    if not srvs then
        ngx.say("failed to get servers in upstream ", u)
    else
      for _, srv in ipairs(srvs) do

        local r_id = _ - 1
        local l_state = 0
        local l_first = 0
        local is_down = 0
        
        if r_id > 0 then l_first = 1 end
        


        ngx.print("<span style=\"vertical-align:middle\"><form action=\"/upstreams\" method=\"GET\">")

        for k, v in pairs(srv) do

          if k ==       "name"   then l_state = 1  servername = v-- which fields do we want to see?
            elseif k == "server" then l_state = 1
            elseif k == "fails"  then l_state = 1
            elseif k == "down"   then l_state = 1
            -- values: current_weight, weight, id, fail_timeout, fails, down, effective_weight, name, server, max_fails
          end
          if l_state == 1 then
        --    if l_first == 1 then ngx.print("<tr><td></td></tr><tr><td></td></tr>"); l_first = 0 end
            
            p_state = ""
            if k == "name" then p_state = p_name end  -- set a color for specific fields
            if k == "down" then p_state = p_down end
            if k == "down" and tostring(v) == "false" then p_state = p_up end
            if k == "down" then
              if tostring(v) == "true" then
                vv = false
              else
                vv = true
              end
            end
            local p_test = "<span type=\"text\" "..p_state.. "> "..k.." : "..tostring(v).. " / " .."<span>"
                    
            ngx.print(p_test)            
--            ngx.print(p_test)
            --ngx.print("<input type=\"hidden\" name=\"gui\" value=\"1\">")
            
            if k == "down" then                
              if tostring(v) == "true" then 
                is_down = 1;
                ngx.print("<input type=\"hidden\" name=\"act\" value=\"up\">")                
                ngx.print("<input type=\"hidden\" name=\"name\" value=\"",servername,"\">")
                ngx.print("<input type=\"submit\" value=\"Up\">")
                ngx.print("<input type=\"hidden\" name=\"stream\" value=\"",u,"\"></form>")                
                           
              end
            else           
                -- ngx.print("<span style=\"vertical-align:middle\"><form action=\"/upstreams\" method=\"GET\">")              
                -- ngx.print("<input type=\"hidden\" name=\"act\" value=\"down\">")                
                -- ngx.print("<input type=\"hidden\" name=\"name\" value=\"",servername,"\">")
                -- ngx.print("<input type=\"submit\" value=\"Down\">")
                -- ngx.print("<input type=\"hidden\" name=\"stream\" value=\"",u,"\"></form> <span>")
            end
          end
          l_state = 0
        end
        if is_down == 0 then
            ngx.print("<input type=\"hidden\" name=\"act\" value=\"down\">")                
            ngx.print("<input type=\"hidden\" name=\"name\" value=\"",servername,"\">")
            ngx.print("<input type=\"submit\" value=\"Down\">")
            ngx.print("<input type=\"hidden\" name=\"stream\" value=\"",u,"\"></form>")   
        end
      end
    end
  ngx.print("<br>")
end
ngx.print("</body></html>\n")




