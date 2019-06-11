#!/bin/bash

set -e


CURL=$(which curl 2> /dev/null)
NC=$(which nc 2> /dev/null)
NC_OPTS="-z"

inspect() {

  echo ""
  echo "inspect needed containers"
  for d in $(docker ps | tail -n +2 | awk  '{print($1)}')
  do
    # docker inspect --format "{{lower .Name}}" ${d}
    c=$(docker inspect --format '{{with .State}} {{$.Name}} has pid {{.Pid}} {{end}}' ${d})
    s=$(docker inspect --format '{{json .State.Health }}' ${d} | jq --raw-output .Status)

    printf "%-40s - %s\n"  "${c}" "${s}"
  done
}


wait_for_icingaweb() {

  echo -e "\nwait for icingaweb"
  RETRY=35

  until [[ ${RETRY} -le 0 ]]
  do
    timeout 1 bash -c "cat < /dev/null > /dev/tcp/localhost/443" 2> /dev/null
    if [ $? -eq 0 ]
    then
      break
    else
      sleep 10s
      RETRY=$(expr ${RETRY} - 1)
    fi
  done

#  until [[ ${RETRY} -le 0 ]]
#  do
#    ${NC} ${NC_OPTS} localhost 80 < /dev/null > /dev/null
#
#    [[ $? -eq 0 ]] && break
#
#    sleep 10s
#    RETRY=$((expr RETRY - 1))
#  done

  if [[ $RETRY -le 0 ]]
  then
    echo "could not connect to icingaweb"
    exit 1
  fi
  echo ""
#   sleep 2s
}


head() {

  curl \
    --insecure \
    --location \
    https://localhost/icinga/authentication/login?_checkCookie=1
}



running_containers=$(docker ps | tail -n +2  | wc -l)

if [[ ${running_containers} -eq 5 ]] || [[ ${running_containers} -gt 4 ]]
then
  inspect

  wait_for_icingaweb

  head

  exit 0
else
  echo "the test setup needs 4 containers"
  echo "only ${running_containers} running"
  echo "please run "
  echo " make compose-file"
  echo " docker-compose up -d"
  echo "before"
  echo "or check your system"

  exit 1
fi


