#!/bin/bash
cd ~/Marzban-node
docker compose down --remove-orphans
docker compose up -d
