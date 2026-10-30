# written by hkspark 
# https://github.com/hkspark
#
sudo openssl req -x509 -nodes -days 366 \
-newkey rsa:2048 \
-keyout /etc/ssl/private/vsftpd.pem \
-out /etc/ssl/certs/vsftpd.pem
sudo systemctl restart vsftpd
