# define a provider for the managing account of the subdomain
provider "aws" {
  alias  = "subdomain_sandbox_twdps_io"
  region = "us-east-2"
  assume_role {
    role_arn     = "arn:aws:iam::${var.nonprod_account_id}:role/${var.assume_role}"
    session_name = "lab-platform-hosted-zones"
  }
}

# create the subdomain
module "subdomain_sandbox_twdps_io" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "2.0.0"
  create  = true

  providers = {
    aws = aws.subdomain_sandbox_twdps_io
  }

  zones = {
    "sandbox.${local.domain_twdps_io}" = {
      tags = {
        cluster = "sandbox"
      }
    }
  }

  tags = {
    pipeline       = "lab-platform-hosted-zones"
  }
}

module "subdomain_zone_delegation_sandbox_twdps_io" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "2.0.0"
  create  = true

  providers = {
    aws = aws.domain_twdps_io
  }

  private_zone = false
  zone_name = local.domain_twdps_io
  records = [
    {
      name            = "sandbox"
      type            = "NS"
      ttl             = 172800
      zone_id         = data.aws_route53_zone.zone_id_twdps_io.id
      allow_overwrite = true
      records         = lookup(module.subdomain_sandbox_twdps_io.route53_zone_name_servers,"sandbox.${local.domain_twdps_io}")
    }
  ]

  depends_on = [module.subdomain_sandbox_twdps_io]
}