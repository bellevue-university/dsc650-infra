#!/bin/bash
echo 'param should be container name,like master,worker1 or worker2,or simply no param input at all'
cname=$1
docker-compose up -d && docker-compose logs -f $cname
