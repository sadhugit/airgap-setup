output "vpc_id" {
    value = aws_vpc.myvpc.id
}
output "Internetgw" {
    value = aws_internet_gateway.gw.id
}
output "publicsubnetID" {
    value =  aws_subnet.public_subnet.id
}
output "privatesubetID" {
    value =  aws_subnet.private_subnet.id
}
