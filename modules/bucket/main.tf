terraform {
  required_version = ">= 0.12"
}

provider "google" {
  version = "~> 2.19"
  project = var.gcp_project
}

resource "google_storage_bucket" "my-module-yesyes" {
  name          = "module-testing-bucket-${random_id.suffix2.hex}"
  location      = var.location
  force_destroy = var.force_destroy
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


#My forky change
