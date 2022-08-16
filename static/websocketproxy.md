## 代理

WebSocket是一种全双工通信协议，它可以用来做代理，且速度和普通的TCP代理一样快，这也是我研究websocket内存马的原因。

例如有一台不出网主机，有反序列化漏洞。

以前在这种场景下，可能会考虑上reGeorg或者利用端口复用来搭建代理。

现在可以利用反序列化漏洞直接注入websocket代理内存马，然后直接连上用上全双工通信协议的代理。

注入完内存马以后，使用 Gost：[https://github.com/go-gost/gost](https://github.com/go-gost/gost) 连接代理

```
./gost -L "socks5://:1080" -F "ws://127.0.0.1:8080?path=/proxy"
```

然后连接本地1080端口socks5即可使用代理