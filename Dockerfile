FROM nginx:1.23.2-alpine

RUN apk add zola

ENV build /build

RUN mkdir $build
WORKDIR $build

COPY . .
RUN zola build
RUN mv ./public/* /usr/share/nginx/html
RUN sed -i 's/^    #error_page/    error_page/' /etc/nginx/conf.d/default.conf # Ehhhh, good enough
