variable "project_id" {
  description = "The Google Cloud Project ID where resources will be deployed."
  type        = string  # This specifies that the variable's value must be a string.

  # Optional: Default value
  default     = "management-response"

  # Optional: Adding validation
  validation {
    condition     = length(var.project_id) > 0
    error_message = "The project_id must not be empty."
  }
}

variable "region" {
  description = "The GCP region"
  default     = "us-south1"
}
