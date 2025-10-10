resource "random_string" "eventhub_name" {
  length  = 10
  special = false
  numeric = false
  upper   = false
  
  keepers = {
    # Only regenerate if these values change
    name = var.name
    resource_group = var.resource_group_name
  }

  lifecycle {
    ignore_changes = [
      keepers
    ]
  }
} 