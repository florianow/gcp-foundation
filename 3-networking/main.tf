module "networking_project" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref=v34.1.0"
  
  billing_account = var.billing_account_id
  parent          = var.management_folder_id
  name            = "${var.prefix}-networking-hub"
  prefix          = null

  services = [
    "compute.googleapis.com",
    "dns.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ]

  shared_vpc_host_config = {
    enabled = true
  }

  iam = {
    "roles/compute.networkAdmin" = var.network_admins
    "roles/viewer"               = var.network_viewers
  }
}

module "shared_vpc" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc?ref=v34.1.0"
  project_id = module.networking_project.project_id
  name       = "${var.prefix}-shared-vpc"

  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "dev-subnet-eu"
      region        = "europe-west1"
      secondary_ip_ranges = {
        pods     = "10.1.0.0/16"
        services = "10.2.0.0/20"
      }
    },
    {
      ip_cidr_range = "10.0.1.0/24"
      name          = "staging-subnet-eu"
      region        = "europe-west1"
      secondary_ip_ranges = {
        pods     = "10.3.0.0/16"
        services = "10.4.0.0/20"
      }
    },
    {
      ip_cidr_range = "10.0.2.0/24"
      name          = "prod-subnet-eu"
      region        = "europe-west1"
      secondary_ip_ranges = {
        pods     = "10.5.0.0/16"
        services = "10.6.0.0/20"
      }
    }
  ]

  psa_configs = [{
    ranges = {
      cloud-sql = "10.60.0.0/16"
    }
  }]
}

module "nat_gateway_eu" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-cloudnat?ref=v34.1.0"
  project_id     = module.networking_project.project_id
  region         = "europe-west1"
  name           = "${var.prefix}-nat-eu"
  router_network = module.shared_vpc.self_link
  
  logging_filter = "ERRORS_ONLY"
}

module "firewall_policies" {
  source    = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/net-vpc-firewall?ref=v34.1.0"
  project_id = module.networking_project.project_id
  network    = module.shared_vpc.name

  ingress_rules = {
    allow-iap-ssh = {
      description          = "Allow IAP for SSH"
      source_ranges        = ["35.235.240.0/20"]
      targets              = ["allow-iap"]
      use_service_accounts = false
      rules = [
        { protocol = "tcp", ports = [22] }
      ]
    }

    allow-internal = {
      description          = "Allow internal traffic between subnets"
      source_ranges        = ["10.0.0.0/8"]
      use_service_accounts = false
      rules = [
        { protocol = "tcp", ports = null },
        { protocol = "udp", ports = null },
        { protocol = "icmp", ports = null }
      ]
    }

    allow-health-checks = {
      description          = "Allow health checks from GCP load balancers"
      source_ranges        = ["35.191.0.0/16", "130.211.0.0/22"]
      use_service_accounts = false
      rules = [
        { protocol = "tcp", ports = null }
      ]
    }
  }

  egress_rules = {
    deny-all = {
      description   = "Deny all egress by default"
      deny          = true
      priority      = 65535
      destination_ranges = ["0.0.0.0/0"]
      rules = [
        { protocol = "all", ports = null }
      ]
    }

    allow-google-apis = {
      description   = "Allow access to Google APIs"
      priority      = 1000
      destination_ranges = ["199.36.153.8/30", "199.36.153.4/30"]
      rules = [
        { protocol = "tcp", ports = [443] }
      ]
    }

    allow-internal-egress = {
      description   = "Allow internal egress"
      priority      = 1000
      destination_ranges = ["10.0.0.0/8"]
      rules = [
        { protocol = "tcp", ports = null },
        { protocol = "udp", ports = null },
        { protocol = "icmp", ports = null }
      ]
    }
  }
}

module "dns_private_zone" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/dns?ref=v34.1.0"
  project_id = module.networking_project.project_id
  name       = "${var.prefix}-private-zone"
  zone_config = {
    domain = "${var.dns_domain}."
    private = {
      client_networks = [module.shared_vpc.self_link]
    }
  }

  recordsets = {
    "A internal-api" = { records = ["10.0.0.10"] }
  }
}

module "dns_googleapis_zone" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/dns?ref=v34.1.0"
  project_id = module.networking_project.project_id
  name       = "googleapis-private-zone"
  zone_config = {
    domain = "googleapis.com."
    private = {
      client_networks = [module.shared_vpc.self_link]
    }
  }

  recordsets = {
    "A " = { 
      ttl = 300
      records = ["199.36.153.8", "199.36.153.9", "199.36.153.10", "199.36.153.11"] 
    }
    "CNAME *" = { 
      ttl = 300
      records = ["googleapis.com."] 
    }
  }
}
