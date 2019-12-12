#!/bin/bash

server="pi@raspberrypi.local"

echo BUILDING

elm make src/HubNetworkWebClient.elm

echo TRANSFERING

scp index.html $server:~/rpiWebServer/statics/.
cd backend
scp server.py $server:~/rpiWebServer/.

echo STARTING SERVER

ssh $server "echo raspberry | sudo -S killall -v server.py"

ssh $server "echo raspberry | sudo -S ./rpiWebServer/server.py"
