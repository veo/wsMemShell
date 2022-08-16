## 1.前言

WebSocket是一种全双工通信协议，即客户端可以向服务端发送请求，服务端也可以主动向客户端推送数据。这样的特点，使得它在一些实时性要求比较高的场景效果斐然（比如微信朋友圈实时通知、在线协同编辑等）。主流浏览器以及一些常见服务端通信框架（Tomcat、Spring、Jetty、WebSphere、WebLogic等）都对WebSocket进行了技术支持。

本文都以Tomcat进行介绍讨论，其他框架也可实现WebSocket内存马

## 2.版本

2013年以前还没出JSR356标准，Tomcat就对Websocket做了支持，自定义API，再后来有了JSR356，Tomcat立马紧跟潮流，废弃自定义的API，实现JSR356那一套，这就使得在Tomcat7.0.47之后的版本和之前的版本实现方式并不一样，接入方式也改变了。

JSR356 是java制定的websocket编程规范，属于Java EE 7 的一部分，所以要实现websocket功能并不需要任何第三方依赖。

## 3.服务端实现方式

#### （1）注解方式

```
@ServerEndpoint(value = "/ws/{userId}", encoders = {MessageEncoder.class}, decoders = {MessageDecoder.class}, configurator = MyServerConfigurator.class)
```

Tomcat在启动时会默认通过 WsSci 内的 ServletContainerInitializer 初始化 Listener 和 servlet。然后再扫描 `classpath`下带有 `@ServerEndpoint`注解的类进行 `addEndpoint`加入websocket服务

所以即使 Tomcat 没有扫描到 `@ServerEndpoint`注解的类，也会进行Listener和 servlet注册，这就是为什么所有Tomcat启动都能在memshell scanner内看到WsFilter

![static-1](1.png)

#### （2）继承抽象类Endpoint方式

继承抽象类 `Endpoint`方式比加注解 `@ServerEndpoint`方式更麻烦，主要是需要自己实现 `MessageHandler`和 `ServerApplicationConfig`。`@ServerEndpoint`的话都是使用默认的，原理上差不多，只是注解更自动化，更简洁

可以用代码更方便的控制 ServerEndpointConfig 内的属性

```
ServerEndpointConfig serverEndpointConfig = ServerEndpointConfig.Builder.create(WebSocketServerEndpoint3.class, "/ws/{userId}").decoders(decoderList).encoders(encoderList).configurator(new MyServerConfigurator()).build();
```

## 3.websocket内存马实现方法

之前提到过 Tomcat 在启动时会默认通过 WsSci 内的 ServletContainerInitializer 初始化 Listener 和 servlet。然后再扫描 `classpath`下带有 `@ServerEndpoint`注解的类进行 `addEndpoint`加入websocket服务

那如果在服务启动后我们再 addEndpoint 加入websocket服务行不行呢？答案是肯定的，而且非常简单只需要三步。创建一个ServerEndpointConfig，获取ws ServerContainer，加入 ServerEndpointConfig，即可

```
ServerEndpointConfig config = ServerEndpointConfig.Builder.create(EndpointInject.class, "/ws").build();
ServerContainer container = (ServerContainer) req.getServletContext().getAttribute(ServerContainer.class.getName());
container.addEndpoint(config);
```

## 4.效果

首先利用i.jsp注入一个websocket服务，路径为/x，注入后利用ws连接即可执行命令

![static-2](2.png)

且通过memshell scanner查询不到任何异常（因为根本就没注册新的 Listener、servlet 或者 Filter）

![static-3](3.png)