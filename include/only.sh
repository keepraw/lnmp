#!/usr/bin/env bash

Nginx_Dependent()
{
    if [ "$PM" = "yum" ]; then
        rpm -e httpd httpd-tools --nodeps
        yum -y remove httpd*
        for packages in make gcc gcc-c++ gcc-g77 wget crontabs zlib zlib-devel openssl openssl-devel perl patch bzip2;
        do yum -y install $packages; done
        if [ "${DISTRO}" = "Fedora" ] || echo "${CentOS_Version}" | grep -Eqi "^9"; then
            dnf install chkconfig -y
        fi
    elif [ "$PM" = "apt" ]; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        [[ $? -ne 0 ]] && apt-get update --allow-releaseinfo-change -y
        dpkg -P apache2 apache2-doc apache2-mpm-prefork apache2-utils apache2.2-common
        for removepackages in apache2 apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-doc apache2-mpm-worker;
        do apt-get purge -y $removepackages; done
        for packages in debian-keyring debian-archive-keyring build-essential gcc g++ make autoconf automake wget cron openssl libssl-dev zlib1g zlib1g-dev bzip2;
        do apt-get --no-install-recommends install -y $packages; done
    fi
}

Install_Only_Nginx()
{
    clear
    echo "+-----------------------------------------------------------------------+"
    echo "|              Install Nginx for LNMP, Written by Licess                |"
    echo "+-----------------------------------------------------------------------+"
    echo "|                     A tool to only install Nginx.                     |"
    echo "+-----------------------------------------------------------------------+"
    echo "|           For more information please visit https://lnmp.org          |"
    echo "+-----------------------------------------------------------------------+"
    Press_Install
    Echo_Blue "Install dependent packages..."
    cd ${cur_dir}/src
    Get_Dist_Version
    Modify_Source
    Nginx_Dependent
    cd ${cur_dir}/src
    Download_Files ${Download_Mirror}/web/pcre/${Pcre_Ver}.tar.bz2 ${Pcre_Ver}.tar.bz2
    Install_Pcre
    if [ `grep -L '/usr/local/lib'    '/etc/ld.so.conf'` ]; then
        echo "/usr/local/lib" >> /etc/ld.so.conf
    fi
    ldconfig
    Download_Files ${Download_Mirror}/web/nginx/${Nginx_Ver}.tar.gz ${Nginx_Ver}.tar.gz
    Install_Nginx
    StartUp nginx
    rm -rf ${cur_dir}/src/${Nginx_Ver}
    [[ -d "${cur_dir}/src/${Openssl_Ver}" ]] && rm -rf ${cur_dir}/src/${Openssl_Ver}
    [[ -d "${cur_dir}/src/${Openssl_New_Ver}" ]] && rm -rf ${cur_dir}/src/${Openssl_New_Ver}
    StartOrStop start nginx
    Add_Iptables_Rules
    \cp ${cur_dir}/conf/index.html ${Default_Website_Dir}/index.html
    \cp ${cur_dir}/conf/lnmp /bin/lnmp
    Check_Nginx_Files
}

DB_Dependent()
{
    if [ "$PM" = "yum" ]; then
        yum -y remove mysql-server mysql mysql-libs mariadb-server mariadb mariadb-libs
        rpm -qa|grep mysql
        if [ $? -ne 0 ]; then
            rpm -e mysql mysql-libs --nodeps
            rpm -e mariadb mariadb-libs --nodeps
        fi
        for packages in make cmake gcc gcc-c++ gcc-g77 flex bison wget zlib zlib-devel openssl openssl-devel ncurses ncurses-devel libaio-devel rpcgen libtirpc-devel patch cyrus-sasl-devel pkg-config pcre-devel libxml2-devel hostname ncurses-compat-libs numactl-devel;
        do yum -y install $packages; done
        if echo "${CentOS_Version}" | grep -Eqi "^8" || echo "${RHEL_Version}" | grep -Eqi "^8" || echo "${Rocky_Version}" | grep -Eqi "^8" || echo "${Alma_Version}" | grep -Eqi "^8"; then
            Check_PowerTools
            dnf --enablerepo=${repo_id} install rpcgen -y
            dnf install libarchive -y

            dnf install gcc-toolset-10 -y
        fi

        if echo "${CentOS_Version}" | grep -Eqi "^9"; then
            for cs9packages in oniguruma-devel libzip-devel libtirpc-devel;
            do dnf --enablerepo=crb install ${cs9packages} -y; done
        fi

        if [ "${DISTRO}" = "Oracle" ] && echo "${Oracle_Version}" | grep -Eqi "^8"; then
            Check_Codeready
            dnf --enablerepo=${repo_id} install rpcgen re2c -y
            dnf install libarchive -y
        fi

        if [ "${DISTRO}" = "Fedora" ] || echo "${CentOS_Version}" | grep -Eqi "^9"; then
            dnf install chkconfig -y
        fi
    elif [ "$PM" = "apt" ]; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        [[ $? -ne 0 ]] && apt-get update --allow-releaseinfo-change -y
        for removepackages in mysql-client mysql-server mysql-common mysql-server-core-5.5 mysql-client-5.5 mariadb-client mariadb-server mariadb-common;
        do apt-get purge -y $removepackages; done
        dpkg -l |grep mysql
        dpkg -P mysql-server mysql-common libmysqlclient15off libmysqlclient15-dev
        dpkg -P mariadb-client mariadb-server mariadb-common
        for packages in debian-keyring debian-archive-keyring build-essential gcc g++ make cmake autoconf automake wget openssl libssl-dev zlib1g zlib1g-dev libncurses5 libncurses5-dev bison libaio-dev libtirpc-dev libsasl2-dev pkg-config libpcre2-dev libxml2-dev libtinfo-dev libnuma-dev;
        do apt-get --no-install-recommends install -y $packages; done
    fi
}

Install_Database()
{
    echo "============================check files=================================="
    cd ${cur_dir}/src
    if [[ "${DBSelect}" =~ ^[12345]$ ]]; then
        if [[ "${Bin}" = "y" && "${DBSelect}" = "4" ]]; then
            Get_Country
            if [ "${country}" = "CN" ]; then
                Download_Files https://mirrors.aliyun.com/mysql/MySQL-5.7/${Mysql_Ver}-linux-glibc2.12-${DB_ARCH}.tar.gz ${Mysql_Ver}-linux-glibc2.12-${DB_ARCH}.tar.gz
            else
                Download_Files https://cdn.mysql.com/Downloads/MySQL-5.7/${Mysql_Ver}-linux-glibc2.12-${DB_ARCH}.tar.gz ${Mysql_Ver}-linux-glibc2.12-${DB_ARCH}.tar.gz
            fi
            if [ $? -ne 0 ]; then
                Download_Files https://cdn.mysql.com/archives/mysql-5.7/${Mysql_Ver}-linux-glibc2.12-${DB_ARCH}.tar.gz ${Mysql_Ver}-linux-glibc2.12-${DB_ARCH}.tar.gz
            fi
        elif [[ "${Bin}" = "y" && "${DBSelect}" = "5" ]]; then
            Get_Country
            if [ "${country}" = "CN" ]; then
                Download_Files https://mirrors.aliyun.com/mysql/MySQL-8.0/${Mysql_Ver}-linux-glibc2.12-${DB_ARCH}.tar.xz ${Mysql_Ver}-linux-glibc2.12-${DB_ARCH}.tar.xz
            else
                Download_Files https://cdn.mysql.com/Downloads/MySQL-8.0/${Mysql_Ver}-linux-glibc2.12-${DB_ARCH}.tar.xz ${Mysql_Ver}-linux-glibc2.12-${DB_ARCH}.tar.xz
            fi
            if [ $? -ne 0 ]; then
                Download_Files https://cdn.mysql.com/archives/mysql-8.0/${Mysql_Ver}-linux-glibc2.12-${DB_ARCH}.tar.xz ${Mysql_Ver}-linux-glibc2.12-${DB_ARCH}.tar.xz
            fi
        else
            Download_Files ${Download_Mirror}/datebase/mysql/${Mysql_Ver}.tar.gz ${Mysql_Ver}.tar.gz
        fi
    elif [[ "${DBSelect}" =~ ^[6789]|10$ ]]; then
        Download_Files ${Download_Mirror}/datebase/mariadb/${Mariadb_Ver}.tar.gz ${Mariadb_Ver}.tar.gz
    fi
    echo "============================check files=================================="

    Echo_Blue "Install dependent packages..."
    Get_Dist_Version
    Modify_Source
    DB_Dependent
    Check_Openssl
    if [ "${DBSelect}" = "1" ]; then
        Install_MySQL_51
    elif [ "${DBSelect}" = "2" ]; then
        Install_MySQL_55
    elif [ "${DBSelect}" = "3" ]; then
        Install_MySQL_56
    elif [ "${DBSelect}" = "4" ]; then
        Install_MySQL_57
    elif [ "${DBSelect}" = "5" ]; then
        Install_MySQL_80
    elif [ "${DBSelect}" = "6" ]; then
        Install_MariaDB_5
    elif [ "${DBSelect}" = "7" ]; then
        Install_MariaDB_103
    elif [ "${DBSelect}" = "8" ]; then
        Install_MariaDB_104
    elif [ "${DBSelect}" = "9" ]; then
        Install_MariaDB_105
    elif [ "${DBSelect}" = "10" ]; then
        Install_MariaDB_106
    fi
    TempMycnf_Clean

    if [[ "${DBSelect}" =~ ^[6789]|10$ ]]; then
        StartUp mariadb
        StartOrStop start mariadb
    elif [[ "${DBSelect}" =~ ^[12345]$ ]]; then
        StartUp mysql
        StartOrStop start mysql
    fi

    Clean_DB_Src_Dir
    Check_DB_Files
    if [[ "${isDB}" = "ok" ]]; then
        if [[ "${DBSelect}" =~ ^[12345]$ ]]; then
            Echo_Green "MySQL root password: ${DB_Root_Password}"
            Echo_Green "Install ${Mysql_Ver} completed! enjoy it."
        elif [[ "${DBSelect}" =~ ^[6789]|10$ ]]; then
            Echo_Green "MariaDB root password: ${DB_Root_Password}"
            Echo_Green "Install ${Mariadb_Ver} completed! enjoy it."
        fi
    fi
}

Install_Only_Database()
{
    clear
    echo "+-----------------------------------------------------------------------+"
    echo "|      Install MySQL/MariaDB database for LNMP, Written by Licess       |"
    echo "+-----------------------------------------------------------------------+"
    echo "|               A tool to install MySQL/MariaDB for LNMP                |"
    echo "+-----------------------------------------------------------------------+"
    echo "|           For more information please visit https://lnmp.org          |"
    echo "+-----------------------------------------------------------------------+"

    Get_Dist_Name
    Check_DB
    if [ "${DB_Name}" != "None" ]; then
        echo "You have install ${DB_Name}!"
        exit 1
    fi

    Database_Selection
    if [ "${DBSelect}" = "0" ]; then
        echo "DO NOT Install MySQL or MariaDB."
        exit 1
    fi
    Echo_Red "The script will REMOVE MySQL/MariaDB installed via yum or apt-get and it's databases!!!"
    Press_Install
    Install_Database 2>&1 | tee /root/install_database.log
}
