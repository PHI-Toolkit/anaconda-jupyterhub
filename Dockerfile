
# based on https://github.com/ContinuumIO/docker-images/blob/master/miniconda/Dockerfile
FROM debian:8.5

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV CONDA_HOME /opt/conda
ENV NB_USER jupyterhub
ENV NB_UID 1000
ENV NB_USER_SHELL /bin/bash

RUN \
    apt-get update --fix-missing && \
    apt-get install -y wget bzip2 ca-certificates libglib2.0-0 libxext6 libsm6 libxrender1 git \
      virtualenv

RUN \
    echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-4.0.5-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p $CONDA_HOME && \
    rm ~/miniconda.sh

# This is a default user you can use to log in to JupyterHub
#   login: jupyterhub
#   password: Password1
# You can create your own account by entering the bash shell and creating your own user account or
#   change "jupyterhub" and "Password1" below.
RUN \
    useradd -m -s $NB_USER_SHELL -u $NB_UID $NB_USER && \
    echo jupyterhub:Password1 | chpasswd

RUN \
    usermod -aG sudo $NB_USER && \
    echo "cacert=/etc/ssl/certs/ca-certificates.crt" > /home/$NB_USER/.curlrc

# This certificate link is important later for installing R and R packages
RUN mkdir -p /etc/pki/tls/certs/ && \
    ln -s /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt

# Generate self-signed certificate
RUN openssl genrsa -des3 -passout pass:x -out server.pass.key 2048 && \
    openssl rsa -passin pass:x -in server.pass.key -out server.key && \
    rm server.pass.key
RUN openssl req -new -key server.key -out server.csr \
    -subj "/C=US/ST=GA/L=Atlanta/O=OrgName/OU=IT Department/CN=example.com" && \
    openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
RUN cp server.crt /etc/ssl/certs/ && \
    cp server.key /etc/ssl/certs/

RUN \
    $CONDA_HOME/bin/conda install -c conda-forge jupyterhub && \
    $CONDA_HOME/bin/conda install anaconda-nb-extensions -c anaconda-nb-extensions && \
    $CONDA_HOME/bin/conda install -c anaconda-nb-extensions nbsetuptools=0.1.5 && \
    $CONDA_HOME/bin/conda install -c r r-essentials

RUN \
    $CONDA_HOME/bin/conda create --name python27 python=2 anaconda && \
    $CONDA_HOME/bin/conda create --name python35 python=3 anaconda

RUN ln -sf /bin/bash /bin/sh
RUN \
    source /opt/conda/envs/python27/bin/activate python27 && \
    $CONDA_HOME/bin/conda install -c conda-forge tensorflow && \
    $CONDA_HOME/bin/conda install -c anaconda nltk=3.2.1 && \
    $CONDA_HOME/bin/conda install -c asmeurer theano=0.7.0 && \
    $CONDA_HOME/bin/pip install git+git://github.com/fchollet/keras.git && \
    source deactivate

RUN \
    source /opt/conda/envs/python35/bin/activate python35 && \
    $CONDA_HOME/bin/conda install -c conda-forge tensorflow && \
    $CONDA_HOME/bin/conda install -c anaconda nltk=3.2.1 && \
    $CONDA_HOME/bin/conda install -c asmeurer theano=0.7.0 && \
    $CONDA_HOME/bin/pip install git+git://github.com/fchollet/keras.git && \
    source deactivate

RUN apt-get install -y curl grep sed dpkg locate && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean

ENV PATH $CONDA_HOME/bin:$PATH

RUN \
    $CONDA_HOME/bin/conda install jupyter

EXPOSE 8000

ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD [ "/bin/bash" ]
