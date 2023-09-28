# Setup AWS provider for Logging Account
provider "aws" {
  region = "us-east-2"
  profile = "logging"
  alias   = "logging"
}


