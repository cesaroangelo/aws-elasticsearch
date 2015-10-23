variable "access_key" { 
  description = "AWS access key"
  default = "XXXXXXXXXX"
}
variable "secret_key" {
  description = "AWS secret key"
  default = "XXXXXXXXXX"
}
variable "region" {
  description = "AWS region"
  default = "eu-west-1"
}
variable "key_name" {
  description = "AWS key_name"
  default = "user1_cesaro_ie"
}
variable "instance_type" {
  description = "AWS instance type"
  default = "t2.micro"
}
variable "vpc_cidr" {
  description = "AWS CIDR VPC"
  default = "10.0.0.0/16"
}
variable "vpc_sub_cidr" {
  description = "AWS CIDR VPC"
  default = "10.0.1.0/24"
}
variable "conn_user" {
  description = "AWS Connection User"
  default = "ec2-user"
}
variable "conn_keyfile" {
  description = "AWS Connection key_file"
  default = "/opt/terraform/provision/user1_cesaro_ie.pem"
}
variable "ami_value" {
  description = "AWS ami"
  default = "ami-69b9941e"
}
variable "availability_zone_1" {
  description = "AWS availability zone 1"
  default = "eu-west-1a"
}
