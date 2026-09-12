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

    +------------------+
    |   home-control   |  Terraform + Ansible + git run here
    |      .240        |
    +------------------+

## Tech stack

- **Hypervisor:** Proxmox VE
- **Provisioning:** Terraform (`bpg/proxmox` provider)
- **Configuration management:** Ansible
- **Container orchestration:** K3s
- **Ingress:** Traefik (K3s bundled default)
- **Storage:** ZFS RAIDZ1 (3x HDD, `main` pool)
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
    |   `-- site.yml         (K3s install + cluster join playbook)
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
  state-based); Ansible configures it (procedural, re-runnable). Kept
  as two independent, composable steps rather than one coupled process.
- **PostgreSQL is the default database** for any service that needs
  one, chosen for portability to a managed cloud database later if
  ever needed.
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
  legitimate real-world choice on its own merits, not just the path of
  least resistance.

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
- [ ] Project 2: Nextcloud
- [ ] Project 3: Prometheus + Grafana + Loki
- [ ] Project 4: ArgoCD
- [ ] Project 5: TBD (custom app + CI pipeline feeding ArgoCD)

## Reproducing this cluster

    cd ~/homelab-iac
    terraform init
    terraform apply
    cd ansible
    ansible-playbook -i inventory.yml site.yml
