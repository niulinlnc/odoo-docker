FROM elicocorp/odoo-china:9.0
MAINTAINER OnGood <contact@ongood.cn>

# FIX odoo.conf

ADD sources/odoo.conf /opt/odoo/etc/odoo.conf

# FIX boot
ADD bin /app/bin/