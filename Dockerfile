FROM nginx

RUN rm /usr/share/nginx/html/index.html
LABEL version="1.0"\
       name="udacity"

COPY index.html /usr/share/nginx/html/
