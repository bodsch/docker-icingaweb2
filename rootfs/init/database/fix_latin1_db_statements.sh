
# this part is hard and need discussion!
# when we remove all 'latin1_general_ci' parts has this possible bad side effects
#
# i hope, this works well, when the charset of database utf8 is

# grep only the 'icingaweb_db' section of our configuration
charset=$(grep -A10 '\[icingaweb_db\]' /etc/icingaweb2/resources.ini | \
  grep '^charset' | \
  tr -d ' ' | \
  uniq | \
  awk -F '=' '{printf $2}' | \
  sed -e 's|"||g')

if [[ "${charset}" = "utf8" ]]
then
  # charset    = "utf8"
  cd /usr/share/webapps/icingaweb2/modules/monitoring/library/Monitoring/Backend/Ido/Query
  sed -i 's| COLLATE latin1_general_ci||g' *.php
fi
