FROM ubuntu:22.04
LABEL maintainer="Isaac Huffman <isaacphuffman@gmail.com>"

ARG version=1449

RUN apt-get update
RUN apt-get install -y sudo curl git-core gnupg locales wget software-properties-common
RUN apt-get install -y net-tools zip unzip tar tmux

RUN locale-gen en_US.UTF-8

# add admin
RUN adduser --quiet --disabled-password \
    --shell /bin/bash --home /home/admin \
    --gecos "Admin user" admin
RUN echo "admin:placeholderpassword" | sudo chpasswd
RUN usermod -aG sudo admin

# add game server runner user
RUN adduser --quiet --disabled-password \
    --shell /bin/bash --home /home/game \
    --gecos "Game server runner" game

# need unstable debian repository's nvim
RUN add-apt-repository ppa:neovim-ppa/unstable
RUN apt-get update
RUN apt-get install -y neovim

# download terraria server
# to run this server after these commands, it's sudo -H -u admin /home/admin/TerrariaServer (if as root)
WORKDIR /home/game/
RUN wget "https://terraria.org/api/download/pc-dedicated-server/terraria-server-$version.zip" -O app.zip
RUN sudo chown -R game:game app.zip
RUN unzip app.zip
RUN mv $version/Linux server
RUN rm -rf $version
RUN chmod +x server/TerrariaServer
RUN chmod +x server/TerrariaServer.bin.x86_64

# setup tmux multiplexing
# add start tmux on startup
ADD --chown=root:root gameserver.service /etc/systemd/system/
# startup, stop scripts
ADD --chown=game:game start stop wait server/
# add join console script
ADD --chown=admin:admin console /home/admin/

# start in HOME as admin using bash
RUN sudo -H -u admin echo "cd ~" >> /home/admin/.bashrc
USER admin
ENV TERM xterm
ENV DISPLAY host.docker.internal:0.0
CMD ["bash"]

# to ssh into this server, ssh -i YOUR_KEY.pem admin@YOUR_SERVER_URL
