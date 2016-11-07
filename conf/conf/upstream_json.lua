local upstream_status_dict = ngx.shared.upstream_status_dict;
result2 = upstream_status_dict:get("status_json")
ngx.print(result2);
