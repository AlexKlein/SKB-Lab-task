#!/bin/bash

#******************************* HISTORY *******************************************
#Date        Author            ID       Description
#----------  ---------------  --------  --------------------------------------------
#2018-11-09  Klein A.M.       [000000]  Procedure creation.
#******************************* HISTORY *******************************************

# attributes of database
DB_HostName="localhost"
DB_Port="1521"
DB_SID="XE"
DB_UserName="HR"
DB_Password="hr"

# file creation with script for installation Oracle objects
sc_file="orainstsc.txt"

# writing objects in common order
echo "`date` : Script file filling"
	
find  ora/ -maxdepth 3 -type f | grep tables      > "${sc_file}"
find  ora/ -maxdepth 3 -type f | grep sequences  >> "${sc_file}"
find  ora/ -maxdepth 3 -type f | grep views      >> "${sc_file}"
find  ora/ -maxdepth 3 -type f | grep functions  >> "${sc_file}"
find  ora/ -maxdepth 3 -type f | grep procedures >> "${sc_file}"
find  ora/ -maxdepth 3 -type f | grep packages   >> "${sc_file}"

echo "`date` : Script file filled"

# function for database status checking
db_statuscheck() {
    echo "`date` : Trying to connect as "${DB_UserName}"@"${DB_SID}""
    echo "`date` : Connection string in use is : (DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST="${DB_HostName}")(PORT="${DB_Port}")))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME="${DB_SID}")))"
    echo "exit" | sqlplus "${DB_UserName}/${DB_Password}@(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=${DB_HostName})(PORT=${DB_Port})))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=${DB_SID})))" | grep -q "Connected to:" > /dev/null

	if [ $? -eq 0 ] 
	then
		DB_STATUS="UP"
		export DB_STATUS
		
		echo "`date` : Connection is possible"
		
    else
		DB_STATUS="DOWN"
		export DB_STATUS
		
		echo "`date` : Connection is impossible"

		exit 1
	fi
}

# function for start installing Oracle objects
install_ora() {
    db_statuscheck
    
    if [[ "$DB_STATUS" == "DOWN" ]] 
    then
        exit 1
    fi
        
    if [[ "$DB_STATUS" == "UP" ]] 
    then

        # installing objects through script file
        for file in `cat orainstsc.txt`
        do

            echo "`date` : Installing script in $file"
            echo "`date` : Executed script output:"
            sqlplus -s -L ""${DB_UserName}"/"${DB_Password}"@(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST="${DB_HostName}")(PORT="${DB_Port}")))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME="${DB_SID}")))" <<EOF
            @$file;
            commit;
            quit;
EOF
        done

        echo "`date` : Installation completed"
    else
        exit
    fi
}

# installing Oracle objects
exec_install() {
    echo "`date` : Start of objects installation"
    install_ora
    echo "`date` : Done"
}

#executing installation
exec_install

#removing script file
rm orainstsc.txt