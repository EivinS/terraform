terraform {
  required_version = ">= 0.12"
}

provider "google" {
  version = "~> 2.19"
  project = var.gcp_project
}

//adding another bucket
resource "google_storage_bucket" "my-module-yesyes" {
  name          = "module-testing-bucket-${random_id.suffix2.hex}"
  location      = var.location
  force_destroy = var.force_destroy

//Delete objects in sink-bucket after 5 days
  lifecycle_rule {
    condition {
      age = 5
    }
    action {
      type = "Delete"
    }
  }
}

# https://www.terraform.io/docs/providers/google/r/storage_bucket.html
resource "google_storage_bucket" "storage_bucket" {
  name               = length(var.bucket_instance_custom_name) > 0 ? var.bucket_instance_custom_name : "${var.labels.app}-${random_id.suffix.hex}"
  force_destroy      = var.force_destroy
  location           = var.location
  project            = var.gcp_project
  storage_class      = var.storage_class
  bucket_policy_only = var.bucket_policy_only
  labels             = var.labels

  versioning {
    enabled = var.versioning
  }
  logging {
    log_bucket        = var.log_bucket
    log_object_prefix = length(var.bucket_instance_custom_name) > 0 ? var.bucket_instance_custom_name : "${var.labels.app}-${random_id.suffix.hex}"
  }
}

resource "random_id" "protector" {
  count       = var.prevent_destroy ? 1 : 0
  byte_length = 8
  keepers = {
    protector = google_storage_bucket.storage_bucket.id
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "random_id" "suffix" {
  byte_length = 2
}

resource "random_id" "suffix2" {
  byte_length = 2
}

resource "google_storage_transfer_job" "bucket-module" {
  description = "transfering-data-bucket-module"
  project     = var.gcp_project
  status      = "ENABLED"
  transfer_spec {
    gcs_data_source {
      bucket_name = google_storage_bucket.storage_bucket.name # Source bucket
    }
    gcs_data_sink {
      bucket_name = google_storage_bucket.my-module-yesyes.name # Destination bucket
    }
    transfer_options {
      overwrite_objects_already_existing_in_sink = false # Do not overwrite
      delete_objects_from_source_after_transfer  = false # Do not delete source
    }
    object_conditions {
      max_time_elapsed_since_last_modification = "604800s" # Skip files older than 1 week
    }
  }
  schedule { # Run every day at 11:40
    schedule_start_date {
      year  = 2020
      month = 10
      day   = 17
    }
    schedule_end_date {
      year  = 2020
      month = 12
      day   = 31
    }
    start_time_of_day {
      hours   = 13
      minutes = 00
      seconds = 0
      nanos   = 0
    }
  }
}


#My forky change
