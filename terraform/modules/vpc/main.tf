# VPC

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.tags, { Name = var.name })
}


# Internet Gateway (único por VPC)

resource "aws_internet_gateway" "this" {
  count  = var.create_igw ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-igw" })
}


# Subnets públicas

resource "aws_subnet" "public" {
  for_each = { for s in var.public_subnets : s.name => s }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = lookup(each.value, "map_public_ip_on_launch", true)

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
    Tier = "public"
  })
}


# Subnets privadas

resource "aws_subnet" "private" {
  for_each = { for s in var.private_subnets : s.name => s }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
    Tier = "private"
  })
}


# Route Table pública (compartilhada por todas as subnets públicas)

resource "aws_route_table" "public" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-public-rt" })
}

# Rota padrão para o IGW
resource "aws_route" "public_default" {
  count                  = length(var.public_subnets) > 0 && var.create_igw ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

# Rotas extras definidas pelo caller para a route table pública
resource "aws_route" "public_extra" {
  for_each = {
    for r in var.public_extra_routes : r.destination_cidr_block => r
    if length(var.public_subnets) > 0
  }

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = each.value.destination_cidr_block

  # Apenas um dos targets abaixo deve ser preenchido por entrada
  gateway_id                = lookup(each.value, "gateway_id", null)
  nat_gateway_id            = lookup(each.value, "nat_gateway_id", null)
  transit_gateway_id        = lookup(each.value, "transit_gateway_id", null)
  vpc_peering_connection_id = lookup(each.value, "vpc_peering_connection_id", null)
  network_interface_id      = lookup(each.value, "network_interface_id", null)
}

# Associações das subnets públicas
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}


# NAT Gateway (opcional — requer subnets públicas e IGW)


# EIPs — um por AZ (modo HA) ou um único
locals {
  # AZs únicas das subnets públicas, usadas para alocar EIPs no modo HA
  public_subnet_azs = distinct([for s in var.public_subnets : s.az])

  # Qual subnet pública usar para cada NAT GW
  # Modo HA  → um NAT por AZ (primeira subnet pública daquela AZ)
  # Modo single → apenas a primeira subnet pública
  nat_subnet_map = var.create_nat_gateway && var.nat_gateway_ha ? {
    for s in var.public_subnets :
    s.az => s.name...        # agrupa por AZ
  } : {}

  # Mapa final: az → nome da primeira subnet pública nessa AZ
  nat_az_to_subnet = {
    for az, names in local.nat_subnet_map : az => names[0]
  }
}

resource "aws_eip" "nat_ha" {
  for_each = var.create_nat_gateway && var.nat_gateway_ha ? local.nat_az_to_subnet : {}
  domain   = "vpc"
  tags     = merge(var.tags, { Name = "${var.name}-nat-eip-${each.key}" })
}

resource "aws_eip" "nat_single" {
  count  = var.create_nat_gateway && !var.nat_gateway_ha ? 1 : 0
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name}-nat-eip" })
}

resource "aws_nat_gateway" "ha" {
  for_each = var.create_nat_gateway && var.nat_gateway_ha ? local.nat_az_to_subnet : {}

  allocation_id = aws_eip.nat_ha[each.key].id
  subnet_id     = aws_subnet.public[each.value].id

  tags       = merge(var.tags, { Name = "${var.name}-nat-${each.key}" })
  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "single" {
  count = var.create_nat_gateway && !var.nat_gateway_ha ? 1 : 0

  allocation_id = aws_eip.nat_single[0].id
  subnet_id     = aws_subnet.public[var.public_subnets[0].name].id

  tags       = merge(var.tags, { Name = "${var.name}-nat" })
  depends_on = [aws_internet_gateway.this]
}


# Route Tables privadas (uma por subnet privada para maior flexibilidade)

resource "aws_route_table" "private" {
  for_each = { for s in var.private_subnets : s.name => s }
  vpc_id   = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-${each.key}-rt" })
}

# Rotas extras definidas pelo caller para route tables privadas
# Chave do map: "<subnet_name>/<destination_cidr>"
resource "aws_route" "private_extra" {
  for_each = {
    for r in var.private_extra_routes :
    "${r.subnet_name}/${r.destination_cidr_block}" => r
  }

  route_table_id         = aws_route_table.private[each.value.subnet_name].id
  destination_cidr_block = each.value.destination_cidr_block

  gateway_id                = lookup(each.value, "gateway_id", null)
  nat_gateway_id            = lookup(each.value, "nat_gateway_id", null)
  transit_gateway_id        = lookup(each.value, "transit_gateway_id", null)
  vpc_peering_connection_id = lookup(each.value, "vpc_peering_connection_id", null)
  network_interface_id      = lookup(each.value, "network_interface_id", null)
}

# Rota padrão para o NAT Gateway — modo HA (NAT por AZ)
resource "aws_route" "private_nat_ha" {
  for_each = {
    for s in var.private_subnets : s.name => s
    if var.create_nat_gateway && var.nat_gateway_ha
  }

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  # Usa o NAT da mesma AZ da subnet; cai no NAT da primeira AZ disponível se não existir
  nat_gateway_id = contains(keys(aws_nat_gateway.ha), each.value.az) ? (
    aws_nat_gateway.ha[each.value.az].id
  ) : aws_nat_gateway.ha[keys(aws_nat_gateway.ha)[0]].id
}

# Rota padrão para o NAT Gateway — modo single
resource "aws_route" "private_nat_single" {
  for_each = {
    for s in var.private_subnets : s.name => s
    if var.create_nat_gateway && !var.nat_gateway_ha
  }

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.single[0].id
}

# Associações das subnets privadas
resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}