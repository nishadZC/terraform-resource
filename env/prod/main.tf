module "security_group" {
  source = "../../modules/security-groups"

  ec2_sg_name         = "prod-sg"
  ec2_jenkins_sg_name = "prod-jenkins-sg"
  vpc_id              = module.networking.vpc_id
}