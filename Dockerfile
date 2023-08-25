FROM ubuntu:22.04
LABEL maintainer="Isaac Huffman <isaacphuffman@gmail.com>"

ARG version=1449

RUN apt-get update
RUN apt-get install -y sudo curl git-core gnupg locales wget software-properties-common
RUN apt-get install -y net-tools zip unzip tar tmux openssh-server

RUN locale-gen en_US.UTF-8

RUN sudo groupadd console

# add game server runner user
RUN adduser --quiet --disabled-password \
    --shell /bin/bash --home /home/game \
    --gecos "Game server runner" game
RUN usermod -aG console game

# add admin ssh-er
RUN adduser --quiet --disabled-password \
    --shell /bin/bash --home /home/admin \
    --gecos "Administrator" admin
RUN usermod -aG sudo admin
RUN usermod -aG console admin
RUN echo "admin:placeholderpassword" | sudo chpasswd

# need unstable debian repository's nvim
RUN add-apt-repository ppa:neovim-ppa/unstable
RUN apt-get update
RUN apt-get install -y neovim

# add admin scripts
RUN mkdir -p /home/admin/bin
RUN chown -R admin:admin /home/admin/bin
ADD --chown=root:sudo root_start /home/admin/bin
ADD --chown=admin:admin start /home/admin/bin
ADD --chown=admin:admin console /home/admin
ADD --chown=admin:admin force_shutdown /home/admin/bin
RUN chmod g+r /home/admin/bin/root_start # give admin ability to read this
RUN chmod u+x /home/admin/bin/root_start # but only root will execute it
RUN chmod +x /home/admin/bin/start
RUN chmod +x /home/admin/console
RUN chmod +x /home/admin/bin/force_shutdown

# add game userspace server starter script
RUN mkdir -p /home/game/bin
ADD --chown=game:game run /home/game/bin
RUN chmod +x /home/game/bin/run

# make shared session file
RUN touch /var/tmp/session
RUN chown -R game:console /var/tmp/session
RUN chmod g+rwx /var/tmp/session

# resolves "Missing privilege separation directory: /run/sshd"
RUN mkdir -p /run/sshd

# setup terraria server
WORKDIR /home/game/
RUN mkdir -p bin
RUN wget "https://terraria.org/api/download/pc-dedicated-server/terraria-server-$version.zip" -O app.zip
RUN sudo chown -R game:game app.zip
RUN unzip app.zip
RUN mv $version/Linux/* bin
RUN rm -rf $version
RUN chmod +x bin/TerrariaServer
RUN chmod +x bin/TerrariaServer.bin.x86_64

# add game config
RUN mkdir -p data
RUN chown -R game:game data
ADD --chown=game:game defaultserverconfig.txt .

# start in HOME as admin using bash
RUN sudo -H -u admin echo "cd ~" >> /home/admin/.bashrc
USER root
ENV TERM xterm
ENV DISPLAY host.docker.internal:0.0
EXPOSE 22
EXPOSE 7777
CMD /home/admin/bin/root_start

# to start the server locally:
# docker build -f Dockerfile --tag="terraria" .
# docker run -d -p 22:22 -p 7777:7777 --name terraria terraria
#
# to ssh into this server, ssh -i YOUR_KEY.pem admin@YOUR_SERVER_URL
# shutdown with sudo bin/force_shutdown after ssh-ing
# clean up with docker rm terraria
