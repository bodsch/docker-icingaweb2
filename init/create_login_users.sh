#
# Script to create users

ICINGAWEB_ADMIN_USER=${ICINGAWEB_ADMIN_USER:-"icinga"}
ICINGAWEB_ADMIN_PASS=${ICINGAWEB_ADMIN_PASS:-"icinga"}
ICINGAWEB_DEPLOYER_USER=${ICINGAWEB_DEPLOYER_USER:-"deploy"}
ICINGAWEB_DEPLOYER_PASS=${ICINGAWEB_DEPLOYER_PASS:-"deploy"}

ICINGAWEB2_USERS=${ICINGAWEB2_USERS:-"${ICINGAWEB_ADMIN_USER}:${ICINGAWEB_ADMIN_PASS}"}
ICINGAWEB2_DEPLOYERS=${ICINGAWEB2_DEPLOYERS:-"${ICINGAWEB_DEPLOYER_USER}:${ICINGAWEB_DEPLOYER_PASS}"}

# create the user into the database
#
insert_user_into_database() {

  local user="${1}"
  local pass="${2}"

  pass=$(openssl passwd -1 ${pass})

  # insert default icingauser
  (
    echo "USE ${WEB_DATABASE_NAME};"
    echo "INSERT IGNORE INTO icingaweb_user (name, active, password_hash) VALUES ('${user}', 1, '${pass}');"
    echo "FLUSH PRIVILEGES;"
    echo "quit"
  ) | mysql ${MYSQL_OPTS}

  if [[ $? -gt 0 ]]
  then
    log_error "can't create the icingaweb user the normal way"
    log_error "maybe you've luck trying 'icinga:icinga' but it might become a liability!"
  fi
}

# create (or add) the user(s) to the admin role
#
insert_users_into_role() {

  local user_list="${1}"

  if [[ $(grep -c "\[local admins\]" /etc/icingaweb2/roles.ini) -eq 0 ]]
  then
    cat << EOF > /etc/icingaweb2/roles.ini
[local admins]
users               = "${user_list}"
permissions         = "*"

EOF
  else

    sed -i \
      -e "/^users.*=/s/=.*/= ${user_list}/" \
      /etc/icingaweb2/roles.ini
  fi
}


create_login_user() {

  local users=
  local users_list=()

  [[ -n "${ICINGAWEB2_USERS}" ]] && users=$(echo ${ICINGAWEB2_USERS} | sed -e 's/,/ /g' -e 's/\s+/\n/g' | uniq)

  if [[ -z "${users}" ]]
  then
    log_info "no user found, create default 'admin' user"

    insert_user_into_database ${ICINGAWEB_ADMIN_USER} ${ICINGAWEB_ADMIN_PASSWORD}
  else
    log_info "create local icingaweb users ..."

    for u in ${users}
    do
      user=$(echo "${u}" | cut -d: -f1)
      pass=$(echo "${u}" | cut -d: -f2)

      [[ -z ${pass} ]] && pass=${user}

      log_info "  ${user}"

      insert_user_into_database ${user} ${pass}

      users_list=("${users_list[@]}" "${user}")
    done
  fi

  lst=$( IFS=','; echo "${users_list[*]}" );

  insert_users_into_role ${lst}
}

# create (or add) the user(s) to the deployer role
#
insert_deployer_into_role() {

  local user_list="${1}"

  if [[ $(grep -c "\[deployers\]" /etc/icingaweb2/roles.ini) -eq 0 ]]
  then
    cat << EOF >> /etc/icingaweb2/roles.ini
[deployers]
users       = "${user_list}"
permissions = "module/director,director/api,director/deploy,director/hosts,director/inspect"

EOF
  else

    sed -i \
      -e "/^users.*=/s/=.*/= ${user_list}/" \
      /etc/icingaweb2/roles.ini
  fi
}


create_deployer_user() {

  local users=
  local users_list=()

  [[ -n "${ICINGAWEB2_DEPLOYERS}" ]] && users=$(echo ${ICINGAWEB2_DEPLOYERS} | sed -e 's/,/ /g' -e 's/\s+/\n/g' | uniq)

  if [[ -z "${users}" ]]
  then
    log_info "no deployers defined"
  else
    log_info "create local icingaweb deployers ..."

    for u in ${users}
    do
      user=$(echo "${u}" | cut -d: -f1)
      pass=$(echo "${u}" | cut -d: -f2)

      [[ -z ${pass} ]] && pass=${user}

      log_info "  ${user}"

      insert_user_into_database ${user} ${pass}

      users_list=("${users_list[@]}" "${user}")
    done
  fi

  lst=$( IFS=','; echo "${users_list[*]}" );

  insert_deployer_into_role ${lst}
}


create_login_user
create_deployer_user

# EOF
