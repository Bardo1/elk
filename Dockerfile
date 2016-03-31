FROM logstash:2.3.0

# Just copy the configuration
RUN mkdir -p /etc/logstash/conf
COPY logstash.conf /etc/logstash/conf/logstash.conf

CMD ["logstash", "agent", "-f", "/etc/logstash/conf/logstash.conf"]