const server = http.createServer(app);
var WebSocket = require('faye-websocket');
var net = require('net');
var tc;

function createTcpSocket(ws, tip, tport) {
    var tc = net.connect({
      host: tip,
      port: tport
    }, function () {
        // logger.warn('connected to tcp server. ip =', tip, 'port =', tport);
    });
    tc.on('data', function (data) {
        // logger.warn('tcp socket received: %s', data)
        ws.send(data);
    });
    tc.on('end', function () {
        // logger.warn('disconnected from tcp server.');
        ws.close();
    });
    tc.on('error', function () {
        // logger.warn('tcp socket connection error');
        ws.send("HTTP/1.1 503 Service Unavailable\r\n\r\n")
        ws.close();
    });
    return tc;
}

server.on('upgrade', function(request, socket, body) {
    if (WebSocket.isWebSocket(request)) {
        var ws = new WebSocket(request, socket, body);
        var stage = 0;
        ws.on("message", function(event) {
            if (tc != null && stage === 1) {
                // logger.warn("tc write data");
                tc.write(event.data);
            } else if (stage === 0) {
                var header = Buffer.from(event.data).toString().split(" ");
                // logger.warn(header);
                if (header[0] == "CONNECT") {
                    var addr = header[1].split(":");
                    var tip = addr[0];
                    var tport = Number(addr[1]);
                    tc = createTcpSocket(ws, tip, tport);
                    stage = 1;
                    ws.send("HTTP/1.1 200 Connection Established\r\n\r\n")
                }
            }
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
