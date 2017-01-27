# docker-couchbase

A Docker container for Couchbase Community that auto-configures the cluster based on environment variables

# Quick Start

```bash
$ docker run -d -e CB_RAMSIZE=256 --name couchbase -p 8091-8094:8091-8094 -p 11210:11210 crobin/couchbase-community
$ docker logs -f couchbase
* Starting couchbase ..... started !
* Creating couchbase cluster
* Using random password: <random password here>
SUCCESS: init/edit 127.0.0.1
* Setup finished -- Web UI available at http://<ip>:8091
```

# Variables

The following variables are available

* __CB_ADMIN_USER__ : Admin username _(default: admin)_
* __CB_ADMIN_PWD__ : Admin password _(default: a random 16 char password, printed on stdout at start)_
* __CB_SERVICES__ : Which services are provided by the node: _(default: data,index,query,fts)_
* __CB_RAMSIZE__ : Data size _(default: 512)_
* __CB_INDEX_RAMSIZE__ : Index size _(default: 256)_
* __CB_FTS_RAMSIZE__ : FTS size _(default: 256)_
* __CB_INDEX_STORAGE__ : Index storage type _(default: default)_
