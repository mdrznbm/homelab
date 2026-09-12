resource "proxmox_virtual_environment_vm" "home_k3s_control" {
  name      = "home-k3s-control"
  node_name = "pve"
  vm_id     = 101

  clone {
    vm_id = 9001
  }

  cpu {
    type  = "x86-64-v2-AES"
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "main-nvme"
    interface    = "scsi0"
    size         = 24
    iothread     = true
    ssd          = true
  }

  agent {
    enabled = true
  }

  initialization {
    datastore_id = "main-nvme"

    ip_config {
      ipv4 {
        address = "192.168.1.241/24"
        gateway = "192.168.1.254"
      }
    }

    user_account {
      username = "adm1n"
      keys     = [trimspace(file("/home/adm1n/.ssh/cluster_key.pub"))]
    }
  }
}

resource "proxmox_virtual_environment_vm" "home_k3s_w1" {
  name      = "home-k3s-w1"
  node_name = "pve"
  vm_id     = 102

  clone {
    vm_id = 9001
  }

  cpu {
    type  = "x86-64-v2-AES"
    cores = 2
  }

  memory {
    dedicated = 6144
  }

  disk {
    datastore_id = "main-nvme"
    interface    = "scsi0"
    size         = 32
    iothread     = true
    ssd          = true
  }

  agent {
    enabled = true
  }

  initialization {
    datastore_id = "main-nvme"

    ip_config {
      ipv4 {
        address = "192.168.1.242/24"
        gateway = "192.168.1.254"
      }
    }

    user_account {
      username = "adm1n"
      keys     = [trimspace(file("/home/adm1n/.ssh/cluster_key.pub"))]
    }
  }
}

resource "proxmox_virtual_environment_vm" "home_k3s_w2" {
  name      = "home-k3s-w2"
  node_name = "pve"
  vm_id     = 103

  clone {
    vm_id = 9001
  }

  cpu {
    type  = "x86-64-v2-AES"
    cores = 2
  }

  memory {
    dedicated = 6144
  }

  disk {
    datastore_id = "main-nvme"
    interface    = "scsi0"
    size         = 32
    iothread     = true
    ssd          = true
  }

  agent {
    enabled = true
  }

  initialization {
    datastore_id = "main-nvme"

    ip_config {
      ipv4 {
        address = "192.168.1.243/24"
        gateway = "192.168.1.254"
      }
    }

    user_account {
      username = "adm1n"
      keys     = [trimspace(file("/home/adm1n/.ssh/cluster_key.pub"))]
    }
  }
}
