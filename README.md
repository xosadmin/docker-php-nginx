# docker-php-nginx
A container that offers php environment with Nginx
  
Usage: Create container from docker hub:  
`` docker run -p 80:80 -p 443:443 -v /path/to/website:/var/www/html -e domain=<your-domain> xosadmin/docker-php-nginx ``  
Optional parameter(s):  
- TZ=<time-zone> # Specify time zone that container uses
- ssl=True # Enable SSL support
- email=<your-email> # Optional, only required if intended to use Let's Encrypt
- ``-v /path/to/ssl/dir:/etc/nginx/ssl`` # Map the folder contains SSL certificate and key to container. The SSL certificate and key must named as ``server.crt`` and ``server.key``.  
Note: if ``email`` is specified, Nginx will not adopt SSL certificate in mapped folder.  
  