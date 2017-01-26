FROM couchbase:community-4.5.0

ADD setup.sh /bin/start-cb.sh

ENTRYPOINT ["bash", "/bin/start-cb.sh"]
