

local args = ngx.req.get_uri_args()
local i_stream, i_peer, i_name, i_act,  ok, err, cdone, i_temp

i_stream = args["stream"] -- upstream name
i_peer = args["peer"]     -- number
i_name = args["name"]     -- resolved
i_act  = args["act"]  -- action
i_debug  = args["debug"]  -- action


ngx.say("Nginx Worker PID: ", ngx.worker.pid() , "<br>")
-- ngx.say("Package cpath: " .. package.cpath .. "<br>")


-- local hc = require "healthcheck"
-- ngx.say("========")
-- ngx.print(hc.status_page())
-- ngx.say("========")


-- ngx.say ("stream : " , i_stream , "\n")
-- ngx.say ("name : " , i_name , "\n")
-- ngx.say ("act : " , i_act , "\n")

local concat = table.concat
local upstream = require "ngx.upstream"
local get_servers = upstream.get_servers
local get_upstreams = upstream.get_upstreams

local upstream_share = ngx.shared.www_upstream_dict;
local worker_pid_dict = ngx.shared.worker_pid_dict;

local us = get_upstreams()


-- local http = require("socket.http")
-- local rocks = require "luarocks.loader"

-- package.path=package.path .. "/usr/local/lib/lua/5.1/;;"

local json = require("json");


-- local http = require("socket.http");


--ngx.say(package.path)
require "dumper"



-- dum = {}
-- dum[2] = 1
-- dum[1111] = 1
-- ngx.print("size= " .. #dum  .. "<br>")

-- -- ;text = cjson.encode(value)

-- -- ngx.say("stat_dict=", DataDumper(stat_dict) , "<br>") 
-- ngx.print(dum.x)

-- if i_debug  then
--     ngx.say("DEBUG -- upstream=", DataDumper(us) , "<br>") 
-- end




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
                       ngx.print( "(" .. count .. ") Find out - " ..  v  .. " / " ..  upstream_name .. "\n <br>" )

                        local rnd = math.random(os.time());

                        if type(v) == "string" and string.match( i_act , "down" ) then
                        
                            local upstream_ctl, err = upstream.set_peer_down(upstream_name, false, count, true)                               
                            ngx.say ("(" .. count .. ") act : " , i_act , " / ",  err,  "\n")        

                            for k , worker_id in pairs(worker_pid_dict:get_keys(100)) do                                                                        
                                local dic_key = worker_id .. "," .. upstream_name .."," ..  v .. "," .. count .. "," .. rnd                                
                                local succ, err, forcible  = upstream_share:set( dic_key ,"down" ,3 )     
                                if err then
                                    ngx.log(ngx.ERR, "PID: " .. worker_id .. " / upstream_share:set() error: ", err)
                                    return
                                end
                            end

                                                       
                        elseif type(v) == "string" and string.match( i_act , "up" ) then  
                           
                            local upstream_ctl, err = upstream.set_peer_down(upstream_name, false, count, false) 
                                ngx.say ("(" .. count .. ") act : " , i_act , " / ",  err,  "\n") 
                                for k , worker_id in pairs(worker_pid_dict:get_keys(100)) do    
                                    local dic_key = worker_id .. "," .. upstream_name .."," ..  v .. "," .. count .. "," .. rnd
                                    local succ, err, forcible =  upstream_share:set( dic_key ,"up" , 3 )

                                    if err then
                                         ngx.log(ngx.ERR, "upstream_share:set() error: ", err)
                                         return
                                     end
                                end
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

ngx.print("<br><br><br><br><br>")

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
        
        -- ngx.print("<form action=\"/upstreams\" method=\"GET\">")
        
        
        local p_state = p_up;


        if srv.down == true then 
            p_state = p_down 
        else
            srv.down = "up"
        end
        
        local span = "<form><span type=\"text\" "..p_state.. ">"
        ngx.print(span)
        ngx.say(srv.name ,  " /  " , srv.fails, " / " , srv.down)        
        
        

        if srv.down == true then
            is_down  = 1;
            ngx.print("<input type=\"hidden\" name=\"act\" value=\"up\">")                
            ngx.print("<input type=\"hidden\" name=\"name\" value=\"",srv.name,"\">")
            ngx.print("<input type=\"submit\" value=\"Up\">")
            ngx.print("<input type=\"hidden\" name=\"stream\" value=\"",u,"\">",  srv.down)  
            ngx.print(srvs.down)                 
        end


        if is_down == 0 then
            ngx.print("<input type=\"hidden\" name=\"act\" value=\"down\">")                
            ngx.print("<input type=\"hidden\" name=\"name\" value=\"",srv.name,"\">")
            ngx.print("<input type=\"submit\" value=\"Down\">")
            ngx.print("<input type=\"hidden\" name=\"stream\" value=\"",u,"\">",  srv.down)   
        end

        ngx.print("</span></form>")

        
        -- ngx.print("<form action=\"/upstreams\" method=\"GET\">")

        -- for k, v in pairs(srv) do

        --   if k ==       "name"   then l_state = 1  servername = v-- which fields do we want to see?
        --     elseif k == "server" then l_state = 1
        --     elseif k == "fails"  then l_state = 1
        --     elseif k == "down"   then l_state = 1
        --     -- values: current_weight, weight, id, fail_timeout, fails, down, effective_weight, name, server, max_fails
        --   end
        --   if l_state == 1 then
        -- --    if l_first == 1 then ngx.print("<tr><td></td></tr><tr><td></td></tr>"); l_first = 0 end
            
        --     p_state = ""
        --     if k == "name" then p_state = p_name end  -- set a color for specific fields
        --     if k == "down" then p_state = p_down end
        --     if k == "down" and tostring(v) == "false" then p_state = p_up end
  
        --     -- local p_test = "<span type=\"text\" "..p_state.. "> "..k.." : "..tostring(v).. " / " .."</span>"
        --     local p_test = "<span type=\"text\" "..p_state.. "> "..k.." : "..tostring(v).. " / " .."</span>"            
                    
        --     ngx.print(p_test)            
                        
        --     if k == "down" then                
        --       if tostring(v) == "true" then 
        --         is_down = 1;
        --         ngx.print("<input type=\"hidden\" name=\"act\" value=\"up\">")                
        --         ngx.print("<input type=\"hidden\" name=\"name\" value=\"",servername,"\">")
        --         ngx.print("<input type=\"submit\" value=\"Up\">")
        --         ngx.print("<input type=\"hidden\" name=\"stream\" value=\"",u,"\">", tostring(v) ,  "</form>")  
        --         ngx.print(srvs.down)              
                           
        --       end
        --     else           
        --         -- ngx.print("<span style=\"vertical-align:middle\"><form action=\"/upstreams\" method=\"GET\">")              
        --         -- ngx.print("<input type=\"hidden\" name=\"act\" value=\"down\">")                
        --         -- ngx.print("<input type=\"hidden\" name=\"name\" value=\"",servername,"\">")
        --         -- ngx.print("<input type=\"submit\" value=\"Down\">")
        --         -- ngx.print("<input type=\"hidden\" name=\"stream\" value=\"",u,"\"></form> <span>")
        --     end
        --   end
        --   l_state = 0
        -- end
        -- if is_down == 0 then
        --     ngx.print("<input type=\"hidden\" name=\"act\" value=\"down\">")                
        --     ngx.print("<input type=\"hidden\" name=\"name\" value=\"",servername,"\">")
        --     ngx.print("<input type=\"submit\" value=\"Down\">")
        --     ngx.print("<input type=\"hidden\" name=\"stream\" value=\"",u,"\">", tostring(v) ,  "</form>")   
        -- end
      end
    end
  -- ngx.print("<br>")
end

for kk , vv in pairs(upstream_share:get_keys(100)) do
    ngx.print ("<span> upstream_share dic_key - ")
    ngx.print( "[", kk ,"]" , " / " , vv , "<br> </span>");

end



ngx.print("</body></html>\n")




