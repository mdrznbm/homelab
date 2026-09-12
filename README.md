# Homelab: Family Services + DevOps/Cloud Portfolio

A self-hosted homelab built on Proxmox VE, combining genuinely useful
family-facing services with a full Infrastructure-as-Code pipeline —
built as a portfolio project during a Cloud Support & DevOps bootcamp.

## Architecture

    Proxmox VE Host

    +------------------+
    | debian-template  |  (VMID 9001, generalized golden image)
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
- **OS:** Debian 13 (Trixie)

## Repository structure

    homelab-iac/
    |-- main.tf              (VM resource definitions, 3 K3s nodes)
    |-- provider.tf          (Terraform provider configuration)
    |-- variables.tf         (Input variable declarations)
    |-- terraform.tfvars     (Secrets - gitignored, never committed)
    |-- ansible/
    |   |-- inventory.yml    (K3s node inventory, grouped by role)
    |   `-- site.yml         (K3s install + cluster join playbook)
    `-- README.md

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

## Status

- [x] Debian template built, generalized, and DNS-hardened
- [x] Dedicated control VM (`home-control`) with Terraform, Ansible, git
- [x] 3 K3s node VMs provisioned via Terraform
- [x] K3s cluster installed and joined via Ansible — **live and working**
- [ ] ZFS RAIDZ1 bulk storage pool
- [ ] Ingress strategy
- [ ] Family-facing services (Immich/Nextcloud, monitoring, etc.)

## Reproducing this cluster

    cd ~/homelab-iac
    terraform init
    terraform apply
    cd ansible
    ansible-playbook -i inventory.yml site.yml
- **Host key checking disabled for Ansible (internal automation only).**
  Discovered during a destroy/rebuild test that fresh clones generate new
  SSH host keys, which broke unattended Ansible runs against a strict
  known_hosts. Accepted trade-off for a fully-trusted internal LAN
  automation context — not a pattern suitable for public-facing hosts.
