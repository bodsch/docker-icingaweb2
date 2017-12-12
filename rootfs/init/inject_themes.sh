
for f in $(ls -1 /init/themes/*.less)
do
  echo " [i] install custom theme: ${f}"
  cp ${f} /usr/share/webapps/icingaweb2/public/css/themes/
done

#  sed -i 's|font-size: 0.875em;|font-size: 1em;|g' /usr/share/webapps/icingaweb2/public/css/icinga/*.less && \
#  sed -i 's|font-size: 0.750em;|font-size: 1em;|g' /usr/share/webapps/icingaweb2/public/css/icinga/*.less && \
