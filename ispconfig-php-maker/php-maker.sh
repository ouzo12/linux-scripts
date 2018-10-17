#!/bin/bash
phpversion=7.2.11
installdir=/opt/php-72
builddir=/usr/local/src
# re-use this port if upgrading existing php version (example 7.2.1 to 7.2.2)
fpmport=127.0.0.1:7777
initdfile=php-72-fpm


#install dependencies
apt-get install -y build-essential libfcgi-dev libfcgi0ldbl libjpeg62-turbo-dev libmcrypt-dev libssl-dev libc-client2007e libc-client2007e-dev libxml2-dev libbz2-dev libcurl4-openssl-dev libjpeg-dev libpng-dev libfreetype6-dev libkrb5-dev libpq-dev libxml2-dev libxslt1-dev

# making --with-imap working
if [ ! -h /usr/lib/x86_64-linux-gnu/libc-client.a ]; then
	ln -s /usr/lib/libc-client.a /usr/lib/x86_64-linux-gnu/libc-client.a
fi

# dont edit below
phpfile=php-$phpversion.tar.bz2

if [ ! -d $installdir ];then
	mkdir -p $installdir
fi
if [ ! -d $builddir ];then
	mkdir -p $builddir
fi

cd $builddir

if [ ! -f $builddir/$phpfile ]; then
	echo downloading php version $phpversion
	wget -nv http://de2.php.net/get/$phpfile/from/this/mirror -O $phpfile
else
	echo "version already downloaded"
	echo "CTRL+C if this is wrong. Otherwise wait 10 sec"
#	sleep 10
fi
tar jxf $phpfile
cd php-$phpversion
make clean
./configure --prefix=$installdir --enable-intl --with-pdo-pgsql --with-zlib-dir --with-freetype-dir --enable-mbstring --with-libxml-dir=/usr --enable-soap --enable-calendar --with-curl --with-mcrypt --with-zlib --with-gd --with-pgsql --disable-rpath --enable-inline-optimization --with-bz2 --with-zlib --enable-sockets --enable-sysvsem --enable-sysvshm --enable-pcntl --enable-mbregex --enable-exif --enable-bcmath --with-mhash --enable-zip --with-pcre-regex --with-pdo-mysql --with-mysqli --with-mysql-sock=/var/run/mysqld/mysqld.sock --with-jpeg-dir=/usr --with-png-dir=/usr --enable-gd-native-ttf --with-openssl --with-fpm-user=www-data --with-fpm-group=www-data --with-libdir=/lib/x86_64-linux-gnu --enable-ftp --with-imap --with-imap-ssl --with-kerberos --with-gettext --with-xmlrpc --with-xsl --enable-opcache --enable-fpm
make
make install

echo "copy php.ini files and other stuff"
cat /usr/local/src/php-$phpversion/php.ini-production | sed -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' > $installdir/lib/php.ini.ok
cat $installdir/lib/php.ini.ok | sed -e 's/short_open_tag = Off/short_open_tag = On/g' > $installdir/lib/php.ini.ok.bak
cat $installdir/lib/php.ini.ok.bak | sed -e 's/upload_max_filesize = 2M/upload_max_filesize = 32M/g' > $installdir/lib/php.ini.ok
cat $installdir/lib/php.ini.ok | sed -e 's/post_max_size = 8M/post_max_size = 32M/g' > $installdir/lib/php.ini.ok.bak
cat $installdir/lib/php.ini.ok.bak | sed -e 's/;date.timezone =/date.timezone = "Europe\/Copenhagen"/g' > $installdir/lib/php.ini
rm -f $installdir/lib/php.ini.ok $installdir/lib/php.ini.ok.bak
echo "zend_extension=opcache.so
extension=memcached.so
" >> $installdir/lib/php.ini

cat $installdir/etc/php-fpm.conf.default | sed -e 's/;pid = run\/php-fpm.pid/pid = run\/php-fpm.pid/g' > $installdir/etc/php-fpm.conf
cat $installdir/etc/php-fpm.d/www.conf.default | sed -e "s/127.0.0.1:9000/$fpmport/g" > $installdir/etc/php-fpm.d/www.conf

echo "creating init.d file"

cat > $builddir/$initdfile << EOF
#! /bin/sh
### BEGIN INIT INFO
# Provides:          $initdfile
# Required-Start:    \$all
# Required-Stop:     \$all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts $initdfile
# Description:       starts the PHP FastCGI Process Manager daemon
### END INIT INFO
php_fpm_BIN=$installdir/sbin/php-fpm
php_fpm_CONF=$installdir/etc/php-fpm.conf
php_fpm_PID=$installdir/var/run/php-fpm.pid
php_opts="--fpm-config \$php_fpm_CONF"
wait_for_pid () {
        try=0
        while test \$try -lt 35 ; do
                case "\$1" in
                        'created')
                        if [ -f "\$2" ] ; then
                                try=''
                                break
                        fi
                        ;;
                        'removed')
                        if [ ! -f "\$2" ] ; then
                                try=''
                                break
                        fi
                        ;;
                esac
                echo -n .
                try=\`expr \$try + 1\`
                sleep 1
        done
}
case "\$1" in
        start)
                echo -n "Starting php-fpm "
                \$php_fpm_BIN \$php_opts
                if [ "\$?" != 0 ] ; then
                        echo " failed"
                        exit 1
                fi
                wait_for_pid created \$php_fpm_PID
                if [ -n "\$try" ] ; then
                        echo " failed"
                        exit 1
                else
                        echo " done"
                fi
        ;;
        stop)
                echo -n "Gracefully shutting down php-fpm "
                if [ ! -r \$php_fpm_PID ] ; then
                        echo "warning, no pid file found - php-fpm is not running ?"
                        exit 1
                fi
                kill -QUIT \`cat \$php_fpm_PID\`
                wait_for_pid removed \$php_fpm_PID
                if [ -n "\$try" ] ; then
                        echo " failed. Use force-exit"
                        exit 1
                else
                        echo " done"
                       echo " done"
                fi
        ;;
        force-quit)
                echo -n "Terminating php-fpm "
                if [ ! -r \$php_fpm_PID ] ; then
                        echo "warning, no pid file found - php-fpm is not running ?"
                        exit 1
                fi
                kill -TERM \`cat \$php_fpm_PID\`
                wait_for_pid removed \$php_fpm_PID
                if [ -n "\$try" ] ; then
                        echo " failed"
                        exit 1
                else
                        echo " done"
                fi
        ;;
        restart)
                \$0 stop
                \$0 start
        ;;
        reload)
                echo -n "Reload service php-fpm "
                if [ ! -r \$php_fpm_PID ] ; then
                        echo "warning, no pid file found - php-fpm is not running ?"
                        exit 1
                fi
                kill -USR2 \`cat \$php_fpm_PID\`
                echo " done"
        ;;
        *)
                echo "Usage: \$0 {start|stop|force-quit|restart|reload}"
                exit 1
        ;;
esac

EOF

echo "Adding $initdfile to /etc/init.d"
chmod +x $builddir/$initdfile
mv -f $builddir/$initdfile /etc/init.d/$initdfile
insserv $initdfile

echo "Building memcached"
cd $builddir
if [ -d $builddir/php-memcached-$phpversion ]; then
	cd $builddir/php-memcached-$phpversion
	git pull
else
	git clone https://github.com/php-memcached-dev/php-memcached php-memcached-$phpversion
	cd php-memcached-$phpversion
fi
$installdir/bin/phpize
./configure --with-php-config=$installdir/bin/php-config
make
make install
cd $installdir/etc
pecl -C ./pear.conf update-channels
pecl -C ./pear.conf install xdebug

cat > $builddir/$initdfile.service << EOF
[Unit]
Description=The PHP $phpversion FastCGI Process Manager
After=network.target

[Service]
Type=simple
PIDFile=$installdir/var/run/php-fpm.pid
ExecStart=$installdir/sbin/php-fpm --nodaemonize --fpm-config $installdir/etc/php-fpm.conf
ExecReload=/bin/kill -USR2 \$MAINPID

[Install]
WantedBy=multi-user.target

EOF

echo "move to /lib/systemd/system/$initdfile.service"
mv $builddir/$initdfile.service /lib/systemd/system/$initdfile.service
systemctl enable $initdfile.service
systemctl daemon-reload
systemctl restart $initdfile.service

echo "

If using ISPConfig you can add the alternative php version with following settings

	Path to the PHP-FPM init script: $initdfile
	Path to the php.ini directory: $installdir/lib
	Path to the PHP-FPM pool directory: $installdir/etc/php-fpm.d

"

exit
