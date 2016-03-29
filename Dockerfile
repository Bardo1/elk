# Elasticsearch 2.2.1, Logstash 2.2.2, Kibana 4.4.2

FROM phusion/baseimage
MAINTAINER Paradigma BOL  carrefour-bol@paradigmadigital.com

ENV LOGSTASH_HOME /opt/logstash
ENV LOGSTASH_PACKAGE logstash-2.2.2.tar.gz
ENV KIBANA_HOME /opt/kibana
ENV KIBANA_PACKAGE kibana-4.4.2-linux-x64.tar.gz

### Install Elasticsearch ###

RUN apt-get update -qq \
 && apt-get install -qqy curl

RUN curl http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -
RUN echo deb http://packages.elasticsearch.org/elasticsearch/2.x/debian stable main > /etc/apt/sources.list.d/elasticsearch-2.x.list

RUN apt-get update -qq \
 && apt-get install -qqy \
		elasticsearch=2.2.1 \
		openjdk-7-jdk \
 && apt-get clean

### Install Logstash ###

RUN mkdir ${LOGSTASH_HOME} \
 && curl -O https://download.elasticsearch.org/logstash/logstash/${LOGSTASH_PACKAGE} \
 && tar xzf ${LOGSTASH_PACKAGE} -C ${LOGSTASH_HOME} --strip-components=1 \
 && rm -f ${LOGSTASH_PACKAGE} \
 && groupadd -r logstash \
 && useradd -r -s /usr/sbin/nologin -d ${LOGSTASH_HOME} -c "Logstash service user" -g logstash logstash \
 && mkdir -p /var/log/logstash /etc/logstash/conf.d \
 && chown -R logstash:logstash ${LOGSTASH_HOME} /var/log/logstash

COPY scripts/logstash-init /etc/init.d/logstash
RUN sed -i -e 's#^LS_HOME=$#LS_HOME='$LOGSTASH_HOME'#' /etc/init.d/logstash \
 && chmod +x /etc/init.d/logstash

### Install Kibana ###

RUN mkdir ${KIBANA_HOME} \
 && curl -O https://download.elasticsearch.org/kibana/kibana/${KIBANA_PACKAGE} \
 && tar xzf ${KIBANA_PACKAGE} -C ${KIBANA_HOME} --strip-components=1 \
 && rm -f ${KIBANA_PACKAGE} \
 && groupadd -r kibana \
 && useradd -r -s /usr/sbin/nologin -d ${KIBANA_HOME} -c "Kibana service user" -g kibana kibana \
 && mkdir -p /var/log/kibana \
 && chown -R kibana:kibana ${KIBANA_HOME} /var/log/kibana

COPY scripts/kibana-init /etc/init.d/kibana
RUN sed -i -e 's#^KIBANA_HOME=$#KIBANA_HOME='$KIBANA_HOME'#' /etc/init.d/kibana \
 && chmod +x /etc/init.d/kibana

### Configure Elasticsearch ###

COPY conf/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml

### Configure Logstash ###

# Certs/keys for Beats input
RUN mkdir -p /etc/pki/tls/certs && mkdir /etc/pki/tls/private
COPY certs/logstash-beats.crt /etc/pki/tls/certs/logstash-beats.crt
COPY certs/logstash-beats.key /etc/pki/tls/private/logstash-beats.key

# Logstash filters
COPY conf/02-beats-input.conf /etc/logstash/conf.d/02-beats-input.conf
COPY conf/10-syslog.conf /etc/logstash/conf.d/10-syslog.conf
COPY conf/30-output.conf /etc/logstash/conf.d/30-output.conf

### Start script ###

COPY scripts/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 5601 9200 9300 5044

VOLUME /var/lib/elasticsearch

LABEL io.k8s.description="ElasticSearch, Kibana ang Logstash with filebeat configured" \
	  io.openshift.expose-services="5601,9200,9300,5044" \
      io.openshift.tags="elk,elasticsearch,kibana,logstash,filebeat"

ENV io.k8s.description="ElasticSearch, Kibana ang Logstash with filebeat configured" \
	io.openshift.expose-services="5601,9200,9300,5044" \
    io.openshift.tags="elk,elasticsearch,kibana,logstash,filebeat"

CMD [ "/usr/local/bin/start.sh" ]
