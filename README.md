# **WebSocket Webshell，一种新型WebShell技术**

## 兼容性测试

#### （1）目前测试通过

Tomcat、Spring、Jetty、WebSphere、WebLogic、Resin

Nodejs （无法动态注入，需要修改代码后重启服务）

#### （2）还未进行测试

Jboss(WildFly)

#### （3）~~无法使用的场景~~

~~1.使用了Nginx等代理，未配置Header转发 支持WebSocket~~ 已支持

~~2.使用了CDN，CDN供应商未支持WebSocket服务~~ 已支持

#### （4）~~必须注入内存~~

已支持jsp文件连接WebSocket


## 详细介绍

- ### [websocket 内存马介绍](/static/websocket1.md)
- ### [websocket 内存马代理](/static/websocketproxy.md)
- ### [websocket 多功能shell实现](/static/websocket2.md)
- ### [无需注入，可以绕过Nginx、CDN代理限制的 WebSocket jsp马](/static/wsNotAddEndpoint.md)

## 版权声明

完整代码：[https://github.com/veo/wsMemShell](https://github.com/veo/wsMemShell)

本文章著作权归作者所有。转载请注明出处！[https://github.com/veo](https://github.com/veo)

# 安恒星火实验室

<h1 align="center">
  <img src="static/starfile.jpeg" alt="starfile" width="200px">
  <br>
</h1>
专注于实战攻防与研究，研究涉及实战攻防、威胁情报、攻击模拟与威胁分析等，团队成员均来自行业具备多年实战攻防经验的红队、蓝队和紫队专家。本着以攻促防的核心理念，通过落地 ATT&CK 攻防全景知识库，全面构建实战化、常态化、体系化的企业安全建设与运营。

**目前实验室有岗位在招，实验室位于广州白云，期待您的参与**

简历投递邮箱：MHg3ODc3Njg2ZjYxNmQ2OTQwNjY2Zjc4NmQ2MTY5NmMyZTYzNmY2ZA==
