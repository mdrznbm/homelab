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
         Runs: Traefik ingress, Nextcloud, PostgreSQL

    +------------------+
    |   home-control   |  Terraform + Ansible + git run here
    |      .240        |  Also runs: dnsmasq (local DNS),
    |                  |  Tailscale (subnet router, remote access)
    +------------------+

    Proxmox host also runs: NFS server (exports ZFS pool "main"
    to the 3 K3s nodes for Nextcloud's persistent storage)

## Tech stack

- **Hypervisor:** Proxmox VE
- **Provisioning:** Terraform (`bpg/proxmox` provider)
- **Configuration management:** Ansible
- **Container orchestration:** K3s
- **Ingress:** Traefik (K3s bundled default)
- **Storage:** ZFS RAIDZ1 (3x HDD, `main` pool) exported via NFS
- **Local DNS:** dnsmasq (runs on home-control)
- **Remote access:** Tailscale (subnet router on home-control)
- **Application (Project 2):** Nextcloud + PostgreSQL
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
    |   `-- site.yml         (K3s install, cluster join, nfs-common)
    |-- k8s/
    |   |-- nextcloud-pv.yaml         (NFS-backed PersistentVolume)
    |   |-- nextcloud-pvc.yaml        (statically bound PVC)
    |   |-- postgres-pvc.yaml         (local-path PVC for Postgres)
    |   |-- postgres-deployment.yaml  (PostgreSQL Deployment + Service)
    |   |-- nextcloud-deployment.yaml (Nextcloud Deployment + Service)
    |   `-- nextcloud-ingress.yaml    (Traefik host-based routing)
    |-- dns/
    |   `-- dnsmasq-custom-config.txt (reference copy of local DNS config)
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
  node count — so a single control-plane node was chosen deliberately,
  rather than faking HA with 3 control-plane VMs that would still all
  go down together.
- **Terraform and Ansible are kept separate**, not fused via
  provisioners. Terraform provisions infrastructure (declarative,
  state-based); Ansible configures it (procedural, re-runnable).
- **PostgreSQL is the default database** for any service that needs
  one, chosen for portability to a managed cloud database later if
  ever needed.
- **NFS bridges host-level ZFS storage into K3s**, running directly
  on the Proxmox host rather than a dedicated passthrough VM, since
  the pool already existed at the host level. PostgreSQL deliberately
  does NOT use this NFS storage — its known unreliable file-locking
  semantics are a real risk to database integrity — and instead uses
  K3s's local-path storage class, which Postgres's single-pod access
  pattern doesn't need NFS's multi-pod capability for anyway.
- **Host key checking disabled for Ansible (internal automation only).**
  Discovered during a destroy/rebuild test that fresh clones generate new
  SSH host keys, which broke unattended Ansible runs against a strict
  known_hosts. Accepted trade-off for a fully-trusted internal LAN
  automation context — not a pattern suitable for public-facing hosts.
- **ZFS storage is managed manually, not via Terraform.** A one-time,
  destructive, host-level operation was deliberately kept out of the
  automated pipeline to avoid the risk of Terraform ever re-provisioning
  (and wiping) real family data on every apply.
- **Traefik (K3s's bundled default) was kept as the ingress controller**
  rather than replacing it — already installed and running, and a
  legitimate real-world choice on its own merits.
- **Local DNS (dnsmasq) runs on home-control, not inside K3s.**
  A foundational, always-needed service should not go down every time
  the cluster is destroyed and rebuilt for testing — the same reasoning
  applied to NFS.
- **Remote access via Tailscale, not port forwarding.** Tailscale makes
  only outbound connections and exposes no public listening port;
  access is gated by authentication into a private tailnet rather than
  by network discoverability. Configured as a subnet router on
  home-control (not directly on Proxmox, to avoid putting
  internet-facing software on the single most privileged machine in
  the homelab) so every current and future service becomes remotely
  reachable through one setup.

## Status

- [x] Debian template built, generalized, DNS-hardened, and
      cleaned of stale login history
- [x] Dedicated control VM (`home-control`) with Terraform, Ansible, git
- [x] 3 K3s node VMs provisioned via Terraform
- [x] K3s cluster installed and joined via Ansible — **live and working**
- [x] Full destroy/rebuild reproducibility test passed
- [x] ZFS RAIDZ1 pool verified healthy, per-service datasets created
- [x] Ingress (Traefik) confirmed running
- [x] **Project 1: COMPLETE**
- [x] NFS storage bridge (ZFS -> K3s) built and verified
- [x] PostgreSQL deployed for Nextcloud
- [x] Nextcloud deployed, connected to storage and database
- [x] Local DNS (dnsmasq) + Traefik Ingress — nextcloud.home.lab
      working on the home network
- [x] Family account structure established (admin / regular / group)
- [x] Remote access via Tailscale — verified working off-network,
      on cellular data, with home Wi-Fi disabled
- [ ] Family-onboarding checklist (written, reusable)
- [ ] Remaining family members onboarded
- [ ] Backup-of-the-backup strategy for NFS-backed data
- [ ] Project 3: Prometheus + Grafana + Loki
- [ ] Project 4: ArgoCD
- [ ] Project 5: TBD (custom app + CI pipeline feeding ArgoCD)

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

Note: the NFS export (Proxmox host) and dnsmasq/Tailscale config
(home-control) are manual, host-level setup steps, documented in
dns/ and this README, but not Terraform/Ansible-managed.
