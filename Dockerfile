FROM docker.io/library/perl

COPY Docker/bootstrap.sh /tmp/
RUN chmod +x /tmp/bootstrap.sh
RUN /tmp/bootstrap.sh

COPY Docker/entrypoint /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint

COPY Docker/linux-random-service.conf /etc/

ENTRYPOINT ["/usr/local/bin/entrypoint"]
