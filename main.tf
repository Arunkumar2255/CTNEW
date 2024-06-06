terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "AWS_ACCESS_KEY_ID" {
  description = "The AWS secret key"
  type        = string
  sensitive   = true
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "The AWS Secret access key"
  type        = string
  sensitive   = true
}
provider "aws" {
  region = "us-east-1"
}

module "efs" {
  source = "terraform-aws-modules/efs/aws"

  # File system
  name           = "example"
  creation_token = "example-token"
  encrypted      = true
  kms_key_arn    = "arn:aws:kms:eu-west-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"

  # performance_mode                = "maxIO"
  # NB! PROVISIONED TROUGHPUT MODE WITH 256 MIBPS IS EXPENSIVE ~$1500/month
  # throughput_mode                 = "provisioned"
  # provisioned_throughput_in_mibps = 256

  lifecycle_policy = {
    transition_to_ia = "AFTER_30_DAYS"
  }

  # File system policy
  attach_policy                      = true
  bypass_policy_lockout_safety_check = false
  policy_statements = [
    {
      sid     = "Example"
      actions = ["elasticfilesystem:ClientMount"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::111122223333:role/EfsReadOnly"]
        }
      ]
    }
  ]

  # Mount targets / security group
  mount_targets = {
    "eu-west-1a" = {
      subnet_id = "subnet-abcde012"
    }
    "eu-west-1b" = {
      subnet_id = "subnet-bcde012a"
    }
    "eu-west-1c" = {
      subnet_id = "subnet-fghi345a"
    }
  }
  security_group_description = "Example EFS security group"
  security_group_vpc_id      = "vpc-1234556abcdef"
  security_group_rules = {
    vpc = {
      # relying on the defaults provdied for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = ["10.99.3.0/24", "10.99.4.0/24", "10.99.5.0/24"]
    }
  }

  # Access point(s)
  access_points = {
    posix_example = {
      name = "posix-example"
      posix_user = {
        gid            = 1001
        uid            = 1001
        secondary_gids = [1002]
      }

      tags = {
        Additionl = "yes"
      }
    }
    root_example = {
      root_directory = {
        path = "/example"
        creation_info = {
          owner_gid   = 1001
          owner_uid   = 1001
          permissions = "755"
        }
      }
    }
  }

  # Backup policy
  enable_backup_policy = true

  # Replication configuration
  create_replication_configuration = true
  replication_configuration_destination = {
    region = "eu-west-2"
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
