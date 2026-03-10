output "nat_gateway_ids" {
  description = "IDs dos NAT Gateways. Map az→id no modo HA; map '0'→id no modo single; vazio se não criados."
  value = var.create_nat_gateway ? (
    var.nat_gateway_ha
    ? { for az, ngw in aws_nat_gateway.ha : az => ngw.id }
    : { "0" = aws_nat_gateway.single[0].id }
  ) : {}
}

output "nat_eip_public_ips" {
  description = "IPs públicos dos EIPs alocados para os NAT Gateways."
  value = var.create_nat_gateway ? (
    var.nat_gateway_ha
    ? { for az, eip in aws_eip.nat_ha : az => eip.public_ip }
    : { "0" = aws_eip.nat_single[0].public_ip }
  ) : {}
}


output "vpc_id" {
  description = "ID da VPC criada."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR da VPC."
  value       = aws_vpc.this.cidr_block
}

output "igw_id" {
  description = "ID do Internet Gateway (null se create_igw = false)."
  value       = var.create_igw ? aws_internet_gateway.this[0].id : null
}

output "public_subnet_ids" {
  description = "Map de name → ID das subnets públicas."
  value       = { for k, s in aws_subnet.public : k => s.id }
}

output "private_subnet_ids" {
  description = "Map de name → ID das subnets privadas."
  value       = { for k, s in aws_subnet.private : k => s.id }
}

output "public_route_table_id" {
  description = "ID da route table pública (null se não houver subnets públicas)."
  value       = length(var.public_subnets) > 0 ? aws_route_table.public[0].id : null
}

output "private_route_table_ids" {
  description = "Map de name → ID das route tables privadas."
  value       = { for k, rt in aws_route_table.private : k => rt.id }
}