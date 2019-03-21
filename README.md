# ServerDispatcher
This application is written with open source languages FPC and PHP. Itm combines the functions of the directional port-scanner and client-server application. Client part: being on a computer with several server programs, periodically checks whether these servers listen to incoming connections on specified ports, and reports this to the server part at the specified address. Server part: Listens to port 10001 / tcp, and analyzes incoming streams. Having found a clear signature, selects from it the address of the client who sent the message, as well as the status, number, and protocol of the port about which the client reports, and writes the received data into the specified database table

### To use it
* On client side, (where sitting with monitored servers)
unpack client and modify config.txt
```
    DB_SERVER: <IP of the server wher to send data>
    SCAN_INTERVAL: <Chcek interval>
    PORT_SCAN:
    <Monitored protocol 1>:<Monitored port 1>
    <Monitored protocol 1>:<Monitored port 1>
    <And so on...>
```    
     
* On server side (where db and php server runes)
Modify the sd_server.php, lines 7-11 - it's your mysql db params
