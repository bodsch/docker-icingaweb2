
return

# this part is hard and need discussion!
# when we remove all 'latin1_general_ci' parts has this possible bad side effects
#
cd /usr/share/webapps/icingaweb2/modules/monitoring/library/Monitoring/Backend/Ido/Query
sed -i 's| COLLATE latin1_general_ci||g' *.php
