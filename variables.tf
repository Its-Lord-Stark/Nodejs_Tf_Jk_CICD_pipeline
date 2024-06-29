variable "ami_id" {
    description = "ami ID to launch instance"
    type =string 
}


variable "instance_type" {
    description = "Type of instance to launch"
    type = string
    default = "t2.micro"
}