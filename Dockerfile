FROM ubuntu:14.04
MAINTAINER Ongood <admin@ongood.cn>

# generate locales
RUN locale-gen en_US.UTF-8 && update-locale
RUN echo 'LANG="en_US.UTF-8"' > /etc/default/locale

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8


# Ubuntu CN mirror
# 2 reasons to set the mirror after apt-get update:
#  1) Docker Hub takes more than 15 minutes to fetch the packages list since the mirror server is in China
#  2) apt repository format is subject to race conditions when a mirror is updated (http://askubuntu.com/a/160179)
RUN sed -i 's/archive\.ubuntu\.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list

# Add PostgreSQL's repository. It contains the most recent stable release
#     of PostgreSQL, ``9.4``.
# install dependencies as distrib packages when system bindings are required
# some of them extend the basic odoo requirements for a better "apps" compatibility
# most dependencies are distributed as wheel packages at the next step
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  apt-get update && \
  apt-get -yq install \
    adduser \
    ghostscript \
    postgresql-client-9.4 \
    python \
    python-pip \
    python-imaging \
    python-pychart python-libxslt1 xfonts-base xfonts-75dpi \
    libxrender1 libxext6 fontconfig \
    python-zsi \
    python-lasso \
    libzmq3 \
    # libpq-dev is needed to install pg_config which is required by psycopg2
    libpq-dev \
    # These libraries are needed to install the pip modules
    python-dev \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    libldap2-dev \
    libsasl2-dev \
    libssl-dev \
    # CN fonts
    ttf-wqy-zenhei \
    # Librairies required for LESS
    node-less \
    nodejs \
    npm \
    # This library is necessary to upgrade PIL/pillow module
    libjpeg8-dev \
    # Git is required to clone Odoo OCB project
    git
    
# pip CN mirror
RUN mkdir -p ~/pip && \
  echo "[global]" > ~/pip/pip.conf && \
  echo "index-url = https://pypi.mirrors.ustc.edu.cn/simple" >> ~/pip/pip.conf

# Install Odoo python dependencies
ADD sources/pip-req.txt /opt/sources/pip-req.txt
RUN pip install -r /opt/sources/pip-req.txt

# SM: Install LESS
RUN npm install -g less less-plugin-clean-css && \
  ln -s /usr/bin/nodejs /usr/bin/node

# must unzip this package to make it visible as an odoo external dependency
RUN easy_install -UZ py3o.template

# install wkhtmltopdf based on QT5
# Warning: do not use latest version (0.12.2.1) because it causes the footer issue (see https://github.com/odoo/odoo/issues/4806)
ADD /sources/wkhtmltox.deb /opt/sources/wkhtmltox.deb
RUN dpkg -i /opt/sources/wkhtmltox.deb

# create the odoo user
RUN adduser --home=/opt/odoo --disabled-password --gecos "" --shell=/bin/bash odoo

# changing user is required by openerp which won't start with root
# makes the container more unlikely to be unwillingly changed in interactive mode
USER odoo

RUN /bin/bash -c "mkdir -p /opt/odoo/{bin,etc,sources/odoo,additional_addons,data}"
RUN /bin/bash -c "mkdir -p /opt/odoo/var/{run,log,egg-cache}"

# Add Odoo OCB sources and remove .git folder in order to reduce image size
WORKDIR /opt/odoo/sources
RUN git clone https://github.com/OCA/OCB.git -b 10.0 --depth=1 odoo && \
  rm -rf odoo/.git
  
# Google links CN mirror
RUN sed -i "s/fonts\.googleapis\.com/fonts.lug.ustc.edu.cn/g" `grep 'fonts\.googleapis\.com' -rl /opt/odoo/sources/odoo/addons`

# Execution environment
USER 0
ADD sources/odoo.conf /opt/sources/odoo.conf
WORKDIR /app
VOLUME ["/opt/odoo/var", "/opt/odoo/etc", "/opt/odoo/additional_addons", "/opt/odoo/data"]
# Set the default entrypoint (non overridable) to run when starting the container
ENTRYPOINT ["/app/bin/boot"]
CMD ["help"]
# Expose the odoo ports (for linked containers)
EXPOSE 8069 8072
ADD bin /app/bin/
