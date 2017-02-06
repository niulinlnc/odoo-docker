
FROM elicocorp/odoo-china:10.0
MAINTAINER Elico Corp <contact@elico-corp.com>

# FIX odoo.conf

ADD sources/odoo.conf /opt/odoo/etc/odoo.conf

# FIX boot
ADD bin /app/bin/