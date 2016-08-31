#!/bin/bash
docker stop jupyterhub
docker rm jupyterhub
docker run -itd \
-v $(pwd):/home/jupyterhub \
-p 0.0.0.0:8000:8000 \
--name jupyterhub \
hermantolentino/anaconda-jupyterhub \
jupyterhub --no-ssl
