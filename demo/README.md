# Local monitoring demo

From the repository root, set a random `GRAFANA_ADMIN_PASSWORD` and run:

```sh
docker compose -f demo/compose.yaml up --build -d
python3 scripts/check_demo.py
```

The exporter is installed by Chef during the image build. The build checks that a
second converge changes zero resources. The running container drops Linux capabilities,
uses a read-only root filesystem, and runs as `node_exporter`.

Prometheus discovers `exporter:9100` through JSON file discovery. Grafana provisions the
same dashboard file shipped by the cookbook. Its datasource UID is stable (`prometheus`).
The Chef demo recipe additionally exercises generation of discovery JSON and dashboard
installation during the image build; Compose mounts the corresponding repository assets.

Endpoints:

| URL | Purpose |
| --- | --- |
| http://localhost:3000/d/chef-host-overview | Anonymous Viewer dashboard |
| http://localhost:9090/targets | Scrape health |
| http://localhost:9090/alerts | Example host and Chef alerts |

The exporter is reachable only within the Compose network. Ports 3000 and 9090 bind
to the host's loopback interface. This does not model a production fleet, authentication
gateway, or host-mounted filesystem. Chef health panels need a scheduled host Chef run
and are expected to have no series in the minimal container demo.

If a bind fails, stop the existing local service on that port or update the host side
of the Compose port mapping and adjust `scripts/check_demo.py` accordingly.

`docker compose -f demo/compose.yaml down` stops the stack. Add `-v` only when you also
want to delete its local Prometheus and Grafana data volumes.
