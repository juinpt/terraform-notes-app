# Creates one EC2 var.instance_count instances on each subnet
resource "aws_instance" "aws_ubuntu" {

  count = var.instance_count

  instance_type          = var.instance_type
  ami                    = var.ami
  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = element(var.subnet_ids, count.index % length(var.subnet_ids))

  user_data = templatefile("${path.module}/files/user_data.sh.tmpl", {
    postgres_host     = "${var.postgres_host}"
    postgres_port     = "${var.postgres_port}"
    postgres_db       = "${var.postgres_db}"
    postgres_user     = "${var.postgres_user}"
    postgres_password = "${var.postgres_password}"
    opensearch_host   = "${var.opensearch_host}"
    aws_region        = "${var.aws_region}"
    flask_secret_key  = "${var.flask_secret_key}"
  })

  tags = {
    Name = "${var.name_prefix}-${count.index}"
  }

}

