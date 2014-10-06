FROM ubuntu:trusty
MAINTAINER Arcus "http://arcus.io"
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y wget openjdk-7-jre-headless
RUN cd /opt && wget -nv https://download.elasticsearch.org/logstash/logstash/logstash-1.4.2.tar.gz -O logstash.tar.gz \
  && tar zxf logstash.tar.gz \
  && ln -s logstash-* logstash \
  && rm logstash.tar.gz
ADD haproxy /opt/logstash/patterns/haproxy
ADD run.sh /usr/local/bin/run
RUN chmod +x /usr/local/bin/run

EXPOSE 514
EXPOSE 9200
EXPOSE 9292
EXPOSE 9300
CMD ["/usr/local/bin/run"]
