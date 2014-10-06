#!/bin/bash
CFG=${CFG:-}
ES_HOST=${ES_HOST:-127.0.0.1}
ES_PORT=${ES_PORT:-9300}
EMBEDDED="false"

# check for link configuration via -link elasticsearch:es
if [ -n "$ES_PORT_9300_TCP" ] ; then
    ES_HOST="$ES_PORT_9300_TCP_ADDR"
    ES_PORT="$ES_PORT_9300_TCP_PORT"
fi

if [ "$ES_HOST" = "127.0.0.1" ] ; then
    EMBEDDED="true"
fi

if [ "$CFG" != "" ]; then
    wget $CFG -O /opt/logstash.conf --no-check-certificate
else
    cat << EOF > /opt/logstash.conf
input {
  tcp {
    port => 514
    type => "syslog"
  }
  udp {
    port => 514
    type => "syslog"
  }
}

filter {
  if [type] == "syslog" {
    grok {
      match => [
      "message", "^(?:<%{POSINT:syslog_pri}>)?%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}"
      ]
      add_field => [ "received_at", "%{@timestamp}" ]
      add_field => [ "received_from", "%{host}" ]
    }
    syslog_pri { }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss", "ISO8601" ]
    }
    if !("_grokparsefailure" in [tags]) {
      mutate {
        replace => [ "@source_host", "%{syslog_hostname}" ]
        replace => [ "@message", "%{syslog_message}" ]
      }
    }
    mutate {
      remove_field => [ "syslog_hostname", "syslog_message", "syslog_timestamp" ]
    }
  }
}

output {
  stdout { debug => true debug_format => "json"}
EOF
    if [ "$EMBEDDED" = "true" ]; then
        cat << EOF >> /opt/logstash.conf
  elasticsearch { embedded => $EMBEDDED }
}
EOF
    else
        cat << EOF >> /opt/logstash.conf
  elasticsearch { embedded => $EMBEDDED host => "$ES_HOST" port => $ES_PORT }
}
EOF
   fi
fi

#java -jar /opt/logstash.jar agent -f /opt/logstash.conf -- web --backend elasticsearch://$ES_HOST:$ES_PORT/
/opt/logstash/bin/logstash -f /opt/logstash.conf
