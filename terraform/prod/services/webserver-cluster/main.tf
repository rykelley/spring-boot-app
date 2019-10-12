provider "aws" {
  region = var.region

}


module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"
}





region                  = "us-east-2"
cluster_name            = "webserver-prod"
remote_state_bucket     = "ryans-tfstate"
remote_state_key        = "prod/terraform.tfstate"
alb_name                = "customers-prod-alb"
alb_security_group_name = "customers-alb-sec-group"
image_id                = "ami-05c1fa8df71875112"
instance_type           = "t2.small"
min_size                = 2
max_size                = 4
enable_autoscaling      = true
