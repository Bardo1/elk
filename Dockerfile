FROM logstash:2.3.0

# Just copy the configuration
RUN mkdir -p /etc/logstash/conf
COPY logstash.conf /etc/logstash/conf/logstash.conf
COPY docker-entrypoint.sh /

RUN chmod +x /docker-entrypoint.sh

CMD ["logstash", "agent", "-f", "/etc/logstash/conf/logstash.conf"]