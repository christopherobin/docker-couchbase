#!/bin/bash
# This is the init file for the couchbase cluster, it is run everytime the cb container is started

echo "starting" > /tmp/status

[[ ! -f /.cb.pwd ]] && openssl rand -hex 8 2>/dev/null 1>/.cb.pwd

RANDOM_PASSWORD="$( cat /.cb.pwd )"

CB_ADMIN_USER="${CB_ADMIN_USER:-admin}"
CB_ADMIN_PWD="${CB_ADMIN_PWD:-$RANDOM_PASSWORD}"
CB_SERVICES="${CB_SERVICES:-kv,index,n1ql,fts}"
CB_RAMSIZE="${CB_RAMSIZE:-512}"
CB_INDEX_RAMSIZE="${CB_INDEX_RAMSIZE:-256}"
CB_FTS_RAMSIZE="${CB_FTS_RAMSIZE:-256}"
CB_INDEX_STORAGE="${CB_INDEX_STORAGE:-forestdb}"

# Starts couchbase in the background
echo -n "* Starting couchbase "
export HOME=/var/lib/couchbase
exec /etc/service/couchbase-server/run 2>&1 &
CB_PID=$!

# Wait for cb to start
while ! curl --output /dev/null --silent --head --fail http://localhost:8091; do
    sleep 1 && echo -n ".";
done;
echo " started !"

# If no bucket is found, init the cluster and create the buckets
if ! couchbase-cli server-list -c 127.0.0.1:8091 -u "${CB_ADMIN_USER}" -p "${CB_ADMIN_PWD}" 1>/dev/null 2>&1; then
    # Init the cluster with the specified amount of memory
    echo "* Creating couchbase cluster"
    if [[ "$CB_ADMIN_PWD" == "$RANDOM_PASSWORD" ]]; then
        echo "* Using random password: ${RANDOM_PASSWORD}"
    fi

    # if only setting up a data node, remove some args
    if [[ "$CB_SERVICES" == "kv" ]]; then
        echo "* Setting memory quota"
        curl -sS -X POST http://127.0.0.1:8091/pools/default \
            -d "memoryQuota=${CB_RAMSIZE}"
        echo "* Setting up services"
        curl -sS -X POST http://127.0.0.1:8091/node/controller/setupServices \
            -d "services=${CB_SERVICES}"
        echo "* Setting up storage"
        curl -sS -X POST http://127.0.0.1:8091/settings/indexes \
            -d "storageMode=forestdb" | python -c 'import json,sys; print("\n".join(["  %s: %s" % (k, v) for k, v in json.load(sys.stdin).items()]))'
        echo "* Setting up credentials and port"
        curl -sS -X POST http://127.0.0.1:8091/settings/web \
            -d "username=${CB_ADMIN_USER}&password=${CB_ADMIN_PWD}&port=8091&" | python -c 'import json,sys; print("\n".join(["  %s: %s" % (k, v) for k, v in json.load(sys.stdin).items()]))'
    else
        echo "* Setting memory quota"
        curl -sS -X POST http://127.0.0.1:8091/pools/default \
            -d "memoryQuota=${CB_RAMSIZE}" \
            -d "indexMemoryQuota=${CB_INDEX_RAMSIZE}" \
            -d "ftsMemoryQuota=${CB_FTS_RAMSIZE}"
        echo "* Setting up services"
        curl -sS -X POST http://127.0.0.1:8091/node/controller/setupServices \
            -d "services=${CB_SERVICES}"
        echo "* Setting up storage"
        curl -sS -X POST http://127.0.0.1:8091/settings/indexes \
            -d "storageMode=forestdb" | python -c 'import json,sys; print("\n".join(["  %s: %s" % (k, v) for k, v in json.load(sys.stdin).items()]))'
        echo "* Setting up credentials and port"
        curl -sS -X POST http://127.0.0.1:8091/settings/web \
            -d "username=${CB_ADMIN_USER}&password=${CB_ADMIN_PWD}&port=8091&" | python -c 'import json,sys; print("\n".join(["  %s: %s" % (k, v) for k, v in json.load(sys.stdin).items()]))'
    fi
fi

# Trap and forward term/int from the docker env to cb
trap 'kill -TERM $CB_PID' TERM
trap 'kill -INT $CB_PID' INT

echo "ready" > /tmp/status

echo "* Setup finished -- Web UI available at http://<ip>:8091"
wait $CB_PID
trap - TERM INT
wait $CB_PID
EXIT_STATUS=$?
