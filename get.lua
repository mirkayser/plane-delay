-- LuaJIT script setting HTTP method, body, and adding a header

wrk.method = 'GET'
wrk.body   = '{"x": [1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0]}'
wrk.headers['Content-Type'] = 'application/json'
