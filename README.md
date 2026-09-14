# Homelab: Family Services + DevOps/Cloud Portfolio

A self-hosted homelab built on Proxmox VE, combining genuinely useful
family-facing services with a full Infrastructure-as-Code pipeline —
built as a portfolio project during a Cloud Support & DevOps bootcamp.

## Architecture

    Proxmox VE Host

    +------------------+
    | debian-template  |  (generalized golden image, clone source)
    +---------+--------+
              | cloned by Terraform
              v
    +------------------+  +--------------+  +--------------+
    | home-k3s-control |  | home-k3s-w1  |  | home-k3s-w2  |
    |      .241        |  |    .242      |  |    .243      |
    +------------------+  +--------------+  +--------------+
         Configured and joined into a K3s cluster by Ansible
         Runs: Traefik ingress, Nextcloud, PostgreSQL,
               Prometheus, Grafana, Loki, Promtail

    +------------------+
    |   home-control   |  Terraform + Ansible + Helm + git run here
    |      .240        |  Also runs: dnsmasq (local DNS),
    |                  |  Tailscale (subnet router, remote access)
    +------------------+

    Proxmox host also runs: NFS server (exports ZFS pool "main"
    to the 3 K3s nodes for Nextcloud's persistent storage)

## Tech stack

- **Hypervisor:** Proxmox VE
- **Provisioning:** Terraform (`bpg/proxmox` provider)
- **Configuration management:** Ansible
- **Package management (K8s):** Helm
- **Container orchestration:** K3s
- **Ingress:** Traefik (K3s bundled default)
- **Storage:** ZFS RAIDZ1 (3x HDD, `main` pool) exported via NFS
- **Local DNS:** dnsmasq (runs on home-control)
- **Remote access:** Tailscale (subnet router on home-control)
- **Application (Project 2):** Nextcloud + PostgreSQL
- **Observability (Project 3):** Prometheus + Grafana + Loki + Promtail
- **OS:** Debian 13 (Trixie)

## Repository structure

    homelab-iac/
    |-- main.tf              (VM resource definitions, 3 K3s nodes)
    |-- provider.tf          (Terraform provider configuration)
    |-- variables.tf         (Input variable declarations)
    |-- terraform.tfvars     (Secrets - gitignored, never committed)
    |-- ansible/
    |   |-- inventory.yml    (K3s node inventory, grouped by role)
    |   |-- ansible.cfg      (host_key_checking disabled - internal LAN only)
    |   `-- site.yml         (K3s install, cluster join, nfs-common, disable IPv6)
    |-- k8s/
    |   |-- nextcloud-pv.yaml         (NFS-backed PersistentVolume)
    |   |-- nextcloud-pvc.yaml        (statically bound PVC)
    |   |-- postgres-pvc.yaml         (local-path PVC for Postgres)
    |   |-- postgres-deployment.yaml  (PostgreSQL Deployment + Service)
    |   |-- nextcloud-deployment.yaml (Nextcloud Deployment + Service)
    |   `-- nextcloud-ingress.yaml    (Traefik host-based routing)
    |-- monitoring/
    |   |-- values.yaml              (kube-prometheus-stack Helm values)
    |   |-- loki-values.yaml         (Loki Helm values, SingleBinary mode)
    |   |-- promtail-values.yaml     (Promtail Helm values)
    |   `-- grafana-ingress.yaml     (Traefik host-based routing)
    |-- dns/
    |   `-- dnsmasq-custom-config.txt (reference copy of local DNS config)
    |-- docs/
    |   `-- family-onboarding-checklist.md
    `-- README.md

## Project roadmap

Each project is chosen to map to a specific, recognizable skill area:

    | # | Project                          | What it demonstrates            |
    |---|-----------------------------------|----------------------------------|
    | 1 | Terraform + Ansible + K3s         | Infrastructure automation       |
    | 2 | Nextcloud                         | Application hosting and storage |
    | 3 | Prometheus + Grafana + Loki       | Monitoring and observability    |
    | 4 | ArgoCD                            | GitOps and deployment mgmt      |
    | 5 | Custom app + CI pipeline (TBD)    | CI/CD, feeds Project 4          |

## Key design decisions

- **Template-based provisioning, not manual VM builds.** A single
  generalized Debian template (cloud-init ready, guest agent installed)
  is the only image ever cloned from — ensuring every node is
  reproducible from code, not hand-built.
- **Static IPs over DHCP.** Cluster nodes need stable addressing;
  DHCP reservation wasn't available on the ISP-provided router, so
  static IPs are set directly via cloud-init instead.
- **No true HA on the control plane.** With a single physical Proxmox
  host, the hardware itself is a single point of failure regardless of
  node count — so a single control-plane node was chosen deliberately.
- **Terraform and Ansible are kept separate**, not fused via
  provisioners. Terraform provisions infrastructure (declarative,
  state-based); Ansible configures it (procedural, re-runnable).
- **PostgreSQL is the default database** for any service that needs
  one, chosen for portability to a managed cloud database later.
- **NFS bridges host-level ZFS storage into K3s**, running directly
  on the Proxmox host. PostgreSQL deliberately does NOT use this NFS
  storage — its file-locking semantics are a real risk to database
  integrity — and uses K3s's local-path storage class instead.
- **Loki uses filesystem storage mode, not object storage.** A full
  MinIO/S3-compatible deployment was judged unnecessary complexity at
  this log volume; filesystem mode is a genuinely supported Loki
  deployment pattern for single-node setups, not a shortcut.
- **IPv6 disabled cluster-wide.** The home network has no working IPv6
  route; DNS was still returning IPv6 addresses for external
  registries (e.g. quay.io), causing every image pull to waste time
  failing through unreachable IPv6 addresses before falling back to
  IPv4. Disabled via Ansible (sysctl) across all 3 nodes.
- **Chart defaults are trimmed to actual cluster capacity, not
  accepted blindly.** Loki's bundled memcached cache requested ~9.6GB
  of RAM (more than an entire worker node has) and was disabled;
  Prometheus/Grafana/Loki storage sizes and retention were all
  deliberately sized against real node capacity rather than left at
  chart defaults sized for larger clusters.
- **Host key checking disabled for Ansible (internal automation only).**
  A fresh clone's new SSH host keys broke unattended Ansible runs
  against a strict known_hosts; accepted as a trade-off for a
  fully-trusted internal LAN automation context.
- **ZFS storage is managed manually, not via Terraform** — a
  destructive, host-level operation deliberately kept out of the
  automated apply/destroy cycle.
- **Local DNS (dnsmasq) and remote access (Tailscale) both run on
  home-control**, not inside K3s and not directly on Proxmox — a
  foundational service shouldn't go down with the cluster during
  testing, and internet-facing software was kept off the single most
  privileged machine in the homelab.
- **Remote access via Tailscale, not port forwarding.** No public
  listening port is ever exposed; access is gated by authentication
  into a private tailnet.

## Status

- [x] **Project 1: COMPLETE** — Terraform + Ansible + K3s cluster,
      fully tested (including a destroy/rebuild reproducibility test),
      version-controlled and documented
- [x] **Project 2: COMPLETE** — Nextcloud live and accessible both on
      the home network and remotely via Tailscale, with proper
      admin/regular account separation and a written family
      onboarding checklist
- [x] **Project 3: COMPLETE** — Prometheus, Grafana, and Loki deployed
      via Helm, all verified with real data (live cluster dashboards,
      genuine application logs), reachable at grafana.home.lab
- [ ] Project 4: ArgoCD
- [ ] Project 5: TBD (custom app + CI pipeline feeding ArgoCD)

## Pending / Deferred

Items that are known and tracked, but deliberately set aside to
revisit after Projects 4-5 are further along:

- Genuine off-network verification of the career-event laptop (tested
  so far only while on the home network, on both dual-boot OSes)
- Onboarding remaining family members (checklist ready; deferred —
  they are currently overseas)
- A second, independent backup of Nextcloud's data (the ZFS RAIDZ1
  pool protects against a disk failing, not against accidental
  deletion or corruption). Best destination is an incoming Synology
  or UGREEN NAS, not yet received — revisit once hardware arrives
- Removing bootcamp-era per-VM Tailscale entries, planned alongside
  their Proxmox VM deletion after the 7 Oct bootcamp presentation

## Reproducing this cluster

    cd ~/homelab-iac
    terraform init
    terraform apply
    cd ansible
    ansible-playbook -i inventory.yml site.yml
    cd ../k8s
    kubectl apply -f nextcloud-pv.yaml
    kubectl apply -f nextcloud-pvc.yaml
    kubectl apply -f postgres-pvc.yaml
    kubectl apply -f postgres-deployment.yaml
    kubectl apply -f nextcloud-deployment.yaml
    kubectl apply -f nextcloud-ingress.yaml
    cd ../monitoring
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring -f values.yaml
    helm install loki grafana/loki -n monitoring -f loki-values.yaml
    helm install promtail grafana/promtail -n monitoring -f promtail-values.yaml
    kubectl apply -f grafana-ingress.yaml

Note: the NFS export (Proxmox host) and dnsmasq/Tailscale config
(home-control) are manual, host-level setup steps, documented in
dns/ and this README, but not Terraform/Ansible-managed. The
monitoring namespace and various Secrets (grafana-admin-secret,
nextcloud-admin-secret, nextcloud-db-secret) must be created via
kubectl before applying the above.
