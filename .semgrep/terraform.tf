# ruleid: terraform-bucket-public-access-prevention
resource "google_storage_bucket" "unsafe" {
  public_access_prevention = "inherited"
}

# ruleid: terraform-bucket-public-access-prevention
resource "google_storage_bucket" "missing" {
  name = "missing-pap"
}

# ok: terraform-bucket-public-access-prevention
resource "google_storage_bucket" "safe" {
  public_access_prevention = "enforced"
}
