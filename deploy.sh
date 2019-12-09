#!/bin/bash

echo BUILDING

elm make src/HubNetworkWebClient.elm

echo TRANSFERING

cp index.html backend/statics/.

echo STARTING SERVER

cd backend
sudo ./server.py