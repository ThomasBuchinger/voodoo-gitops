

terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
      version = "2.2.3"
    }
  }
}

provider "local" { }

resource "hello" {
  content  = "hello world"
  filename = hello.txt
}