FROM couchbase:community

ADD setup.sh /bin/start-cb.sh

ENTRYPOINT ["bash", "/bin/start-cb.sh"]
