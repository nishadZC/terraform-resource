module "security_group" {
  source = "../../modules/security-groups"
  ec2_sg_name         = "${var.environment}-sg"
  ec2_jenkins_sg_name = "${var.environment}-jenkins-sg"
  vpc_id              = module.networking.vpc_id
}