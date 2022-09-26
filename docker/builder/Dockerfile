FROM jenkins/ssh-agent:jdk11

USER root

RUN apt-get update && \
    apt-get install -y lsb-release apt-transport-https ca-certificates wget

RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php8.1.list

RUN apt-get update && \
    apt-get install -y php8.1 php8.1-common php8.1-mysql php8.1-xmlrpc php8.1-curl php8.1-gd php8.1-cgi php8.1-cli php8.1-fpm php-pear php8.1-dev php8.1-imap php8.1-mbstring php8.1-xml php8.1-tidy php8.1-sqlite3 php8.1-xsl php8.1-gmp php8.1-zip php8.1-soap php-json php-mbstring php-xml php-cli php-curl php-mysql

USER jenkins

RUN mkdir ~/.ssh/ && ssh-keyscan github.com >> ~/.ssh/known_hosts