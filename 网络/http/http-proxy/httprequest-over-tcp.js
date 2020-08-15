var http = require('http');

var options = {
    hostname : '127.0.0.1',
    port     : 8888,
    path     : 'http://tengxunyun:8080',
    method     : 'CONNECT'
};

console.log(10);
var req = http.request(options);
console.log(11);
req.on('connect', function(res, socket) {
    console.log(1);
    socket.write('GET / HTTP/1.1\r\n' +
                 'Host: tengxunyun:8080\r\n' +
                 'Connection: Close\r\n' +
                 '\r\n');
    console.log(2);
    socket.on('data', function(chunk) {
        console.log(3);
        console.log(chunk.toString());
        console.log(4);
    });

    console.log(5);

    socket.on('end', function() {
        console.log(6);
        console.log('socket end.');
        console.log(7);
    });

    console.log(8);
});

req.end();