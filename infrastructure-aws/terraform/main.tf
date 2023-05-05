variable "aws_profile" {}
variable "aws_region" {}

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
}


resource "aws_instance" "Ubuntu-Terra-Test2" {
  ami           = "ami-007855ac798b5175e"
  instance_type = "t3.micro"

  tags = {
    Name= "UbuntuTerraTest2"
  }
}