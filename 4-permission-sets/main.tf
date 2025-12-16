resource "google_organization_iam_custom_role" "project_viewer" {
  role_id     = var.role_name_prefix != "" ? "${var.role_name_prefix}.${var.viewer.role_id}" : var.viewer.role_id
  org_id      = var.organization_id
  title       = var.viewer.title
  description = var.viewer.description

  permissions = [
    "resourcemanager.projects.get",
    "resourcemanager.projects.getIamPolicy",
    "logging.logEntries.list",
    "logging.logs.list",
    "logging.privateLogEntries.list",
    "monitoring.timeSeries.list",
    "monitoring.metricDescriptors.list",
    "monitoring.dashboards.get",
    "monitoring.dashboards.list",
  ]
}

resource "google_organization_iam_custom_role" "project_developer" {
  role_id     = var.role_name_prefix != "" ? "${var.role_name_prefix}.${var.developer.role_id}" : var.developer.role_id
  org_id      = var.organization_id
  title       = var.developer.title
  description = var.developer.description

  permissions = [
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.start",
    "compute.instances.stop",
    "storage.buckets.create",
    "storage.buckets.delete",
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
    "cloudfunctions.functions.create",
    "cloudfunctions.functions.delete",
    "cloudfunctions.functions.get",
    "cloudfunctions.functions.list",
    "cloudfunctions.functions.update",
    "run.services.create",
    "run.services.delete",
    "run.services.get",
    "run.services.list",
    "run.services.update",
    "logging.logEntries.create",
    "monitoring.metricDescriptors.create",
    "monitoring.timeSeries.create",
    "cloudtrace.traces.patch",
    "cloudprofiler.profiles.create",
  ]
}

resource "google_organization_iam_custom_role" "project_operator" {
  role_id     = var.role_name_prefix != "" ? "${var.role_name_prefix}.${var.operator.role_id}" : var.operator.role_id
  org_id      = var.organization_id
  title       = var.operator.title
  description = var.operator.description

  permissions = [
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.start",
    "compute.instances.stop",
    "compute.instances.update",
    "compute.disks.create",
    "compute.disks.delete",
    "compute.disks.get",
    "compute.disks.list",
    "compute.networks.get",
    "compute.networks.list",
    "container.clusters.create",
    "container.clusters.delete",
    "container.clusters.get",
    "container.clusters.list",
    "container.clusters.update",
    "storage.buckets.create",
    "storage.buckets.delete",
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.buckets.update",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
    "cloudsql.instances.create",
    "cloudsql.instances.delete",
    "cloudsql.instances.get",
    "cloudsql.instances.list",
    "cloudsql.instances.update",
    "logging.logEntries.create",
    "logging.logEntries.list",
    "logging.sinks.create",
    "logging.sinks.delete",
    "logging.sinks.get",
    "logging.sinks.list",
    "logging.sinks.update",
    "monitoring.alertPolicies.create",
    "monitoring.alertPolicies.delete",
    "monitoring.alertPolicies.get",
    "monitoring.alertPolicies.list",
    "monitoring.alertPolicies.update",
    "monitoring.dashboards.create",
    "monitoring.dashboards.delete",
    "monitoring.dashboards.get",
    "monitoring.dashboards.list",
    "monitoring.dashboards.update",
    "cloudscheduler.jobs.create",
    "cloudscheduler.jobs.delete",
    "cloudscheduler.jobs.get",
    "cloudscheduler.jobs.list",
    "cloudscheduler.jobs.update",
    "run.services.create",
    "run.services.delete",
    "run.services.get",
    "run.services.list",
    "run.services.update",
    "secretmanager.secrets.create",
    "secretmanager.secrets.delete",
    "secretmanager.secrets.get",
    "secretmanager.secrets.list",
    "secretmanager.versions.access",
    "secretmanager.versions.add",
    "iam.serviceAccounts.actAs",
  ]
}
