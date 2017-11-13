
for f in $(ls -1 /init/themes/*.less)
do
  echo " [i] install custom theme: ${f}"
  cp -v ${f} /usr/share/webapps/icingaweb2/public/css/themes/
done
