variable "gcp_billing_account" {
  description = "Authorized billing account for the state project."
  type        = string
  nullable    = false
}

variable "gcp_folder_id" {
  description = "Numeric quantile-co folder ID directly parenting the state project."
  type        = string
  nullable    = false
}

variable "gcp_maintainers" {
  description = "Google account emails allowed to read saved plans, not Terraform state."
  type        = set(string)
  nullable    = false
}

variable "gcp_wif_pool" {
  description = "Existing GitHub workload identity pool resource path supplied by Q0."
  type        = string
  nullable    = false
}

variable "gh_maintainers" {
  description = "GitHub usernames trusted to run production Plan/Apply on main."
  type        = set(string)
  nullable    = false
}
