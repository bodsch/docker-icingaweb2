#
# Script to create users

ICINGAWEB_ADMIN_USER=${ICINGAWEB_ADMIN_USER:-"icinga"}
ICINGAWEB_ADMIN_PASS=${ICINGAWEB_ADMIN_PASS:-"icinga"}

ICINGAWEB2_USERS=${ICINGAWEB2_USERS:-"${ICINGAWEB_ADMIN_USER}:${ICINGAWEB_ADMIN_PASS}"}

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
    echo "quit"
  ) | mysql ${MYSQL_OPTS}

  if [[ $? -gt 0 ]]
  then
    log_error "can't create the icingaweb user"
    exit 1
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

      log_info "  - '${user}'"

      insert_user_into_database ${user} ${pass}

      users_list=("${users_list[@]}" "${user}")
    done
  fi

  lst=$( IFS=','; echo "${users_list[*]}" );

  insert_users_into_role ${lst}
}


create_login_user

# EOF

