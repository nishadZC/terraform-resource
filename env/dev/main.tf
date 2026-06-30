module "networking" {
  source               = "../../modules/networking"
  vpc_cidr             = var.vpc_cidr
  vpc_name             = var.vpc_name
  cidr_public_subnet   = var.cidr_public_subnet
  ap_availability_zone = var.ap_availability_zone
  cidr_private_subnet  = var.cidr_private_subnet
}
module "security_group" {
  source = "../../modules/security-groups"
  ec2_sg_name         = "${var.environment}-sg"
  ec2_jenkins_sg_name = "${var.environment}-jenkins-sg"
  vpc_id              = module.networking.vpc_id
}

module "jenkins" {
  source                    = "../../modules/jenkins"
  ami_id                    = var.ec2_ami_id
  instance_type             = var.instance_type
  tag_name                  = "${var.environment}-Jenkins:Ubuntu Linux EC2"
  public_key                = var.public_key
  subnet_id                 = tolist(module.networking.dev_proj_1_public_subnets)[0]
  sg_for_jenkins            = [module.security_group.sg_ec2_sg_ssh_http_id, module.security_group.sg_ec2_jenkins_port_8080]
  enable_public_ip_address  = true
  user_data_install_jenkins = templatefile("../../modules/jenkins-runner-script/jenkins-installer.sh", {})
}

module "ecr" {
  source = "../../modules/ecr"
  frontend_repository_name = "${var.environment}-frontend"
  backend_repository_name = "${var.environment}-backend"
}

module "ecs" {
  source = "../../modules/ecs"
  cluster_name       = "${var.environment}-eventify-cluster"
  vpc_id             = module.networking.dev_proj_1_vpc_id
  public_subnets     = module.networking.dev_proj_1_public_subnets
  backend_image_uri  = "${module.ecr.backend_repository_url}:latest"
  frontend_image_uri = "${module.ecr.frontend_repository_url}:latest"
  account_id         = "368763425814"

}