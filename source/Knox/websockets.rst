Включение WebSocket
=====================


Включение протокола связи WebSocket для **Knox Gateway** допускает применение прокси-приложений, использующих данное соединения (например, **Zeppelin**).

WebSocket -- это протокол связи, позволяющий осуществлять полнодуплексную связь по одному TCP-соединению. **Knox** предоставляет встроенную поддержку WebSocket, но в настоящее время поддерживаются только текстовые сообщения.

По умолчанию в **Knox Gateway** функция WebSocket отключена. Однако для работы сервиса **Zeppelin UI** (``<role>ZEPPELINUI</role>``) данная функциональность должна быть включена; для этого необходимо:

1. В файле */conf/gateway-site.xml* изменить значение параметра *gateway.websocket.feature.enabled* на *true*:

  ::
  
   <property>
         <name>gateway.websocket.feature.enabled</name>
         <value>true</value>
         <description>Enable/Disable websocket feature.</description>
     </property>

2. В файле */conf/{topology}.xml* изменить правило топологии:

  ::
  
   <service>
         <role>WEBSOCKET</role>
         <url>ws://myhost:9999/ws</url>
     </service>

3. Перезапустить шлюз по команде:

  :command:`cd $gateway bin/gateway.sh stop bin/gateway.sh start`
  
