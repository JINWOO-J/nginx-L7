local args = ngx.req.get_uri_args()
local i_stream, i_peer, i_name, i_down,  ok, err, cdone, i_temp
i_stream = args["stream"] -- upstream name
i_peer = args["peer"]     -- number
i_name = args["name"]     -- resolved
-- i_server = args["server"] -- from conf
i_down = args["down"]
-- i_vdown = args["vdown"]

if i_down == "1" then i_down = "true" end
if i_down == "0" then i_down = "false" end
cdone = 1
if i_name then i_temp = ngx.re.gsub(i_name, "%3A", ":") end
if i_name then i_name = i_temp end
if i_server then i_temp = ngx.re.gsub(i_server, "%3A", ":") end
if i_server then i_server = i_temp end

ngx.say("down parm : ", i_down)

if i_down and cdone then
  
  local concat = table.concat
                local upstream = require "ngx.upstream"
                local get_servers = upstream.get_servers
                local get_upstreams = upstream.get_upstreams
                local foundit = 0;

                local us = get_upstreams()
                for _, u in ipairs(us) do
                    ngx.say("upstream ", u, ":\\n")
                    local upstream_name = u 
                    local srvs, err = get_servers(u)
                    if not srvs then
                        ngx.say("failed to get servers in upstream ", u)
                    else
                        local count = 0
                        for _, srv in ipairs(srvs) do
                            local first = true
                            
                            for k, v in pairs(srv) do
                                if first then
                                    first = false
                                    -- ngx.print(upstream_name , ":    ")
                                else
                                    -- ngx.print(", ")
                                end
                                
                                

                                if type(v) == "table" then
                                    --ngx.print(k, " = {", concat(v, ", "), "}")
                                else
                                    --ngx.print(count , "." , k, " = ", v)

                                    -- if type(v) == "string" and string.match( v , i_name) then
                                    if type(v) == "string" and v == i_name then                                    
                                      -- ngx.print ("type :", type(v));
                                       -- ngx.say( "-- find ", v, upstream_name, "\n" )
                                       -- ngx.say( "-- find ", v, upstream_name, "\n" )                                       
                                       -- local upstream_ctl, err = upstream.set_peer_down("www_upstream", false, count, true)

                                        foundit = 1
                                        if i_down == "true" then
                                            ok, err = upstream.set_peer_down(i_stream, false, tonumber(count), true)
                                            ngx.print("down ",ok," ",err,"\n")
                                            ngx.say("[ OK ] : index[", count , "] ", i_name , " , " , ok ," , ",err)                                        
                                            
                                        else
                                            ok, err = upstream.set_peer_down(i_stream, false, tonumber(count), false)
                                            ngx.print("up ",ok," ",err,"\n")
                                        end



                                        if not ok then
                                           ngx.say("[ Fail ] failed to down servers in upstream ", u)
                                           

                                        else
                                           ngx.say("[ OK ] " ,err)
                                           return
                                        end

                                    end


                                end
                                
                            end
                          --  ngx.print("\\n")
                            count = count + 1
                        end
                    end
                end
                if foundit == 0 then
                    ngx.say("Can't found it : ", i_name)
                    ngx.status = 410
                    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
                    return
                end

end



return




