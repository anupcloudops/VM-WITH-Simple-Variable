#RG
resource "azurerm_resource_group" "rgblock"{
    name = var.newrg
    location = var.loc
}
#vnet
resource "azurerm_virtual_network" "vnetblock" {
    depends_on = [ azurerm_resource_group.rgblock ]
    name = var.vnet
    location = var.loc
    resource_group_name = var.newrg
    address_space = ["10.0.0.0/16"]
}
#subnet
resource "azurerm_subnet" "subnetblock"{
    depends_on = [ azurerm_virtual_network.vnetblock , azurerm_resource_group.rgblock ]
    name = var.sub
    virtual_network_name = var.vnet
    resource_group_name = var.newrg
    address_prefixes = ["10.0.1.0/24"]
}
#public_ip
resource "azurerm_public_ip" "pipblock"{
    depends_on = [ azurerm_resource_group.rgblock ]
    name = var.pip
    location = var.loc
    resource_group_name = var.newrg
    allocation_method = "Static"
    sku = "Standard"
}
#network_interface
resource "azurerm_network_interface" "nicblock"{
    depends_on = [ azurerm_subnet.subnetblock , azurerm_public_ip.pipblock ]
    name = var.nic
    location = var.loc
    resource_group_name = var.newrg
    ip_configuration{
        name = "aic"
        subnet_id = data.azurerm_subnet.dsub.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = data.azurerm_public_ip.dpip.id
    }
}
data "azurerm_subnet" "dsub"{
    depends_on = [ azurerm_subnet.subnetblock ]
    name =var.sub
    virtual_network_name = var.vnet
    resource_group_name = var.newrg
}
data "azurerm_public_ip" "dpip" {
    depends_on = [ azurerm_public_ip.pipblock ]
    name = var.pip
    resource_group_name =var.newrg
    
}
#nsg
resource "azurerm_network_security_group" "nsgblock"{
    depends_on = [ azurerm_resource_group.rgblock ]
    name = var.nsg
    location = var.loc
    resource_group_name = var.newrg
    security_rule{
        name = "asr"
        priority = 100
        direction= "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "*"
        destination_address_prefix =  "*"
    }
}
#association
resource "azurerm_network_interface_security_group_association" "nic_nsg_assoiation"{
    depends_on = [ azurerm_network_interface.nicblock , azurerm_network_security_group.nsgblock ]
    network_interface_id = data.azurerm_network_interface.dnic.id
    network_security_group_id = data.azurerm_network_security_group.dnsg.id
}
data "azurerm_network_interface" "dnic" {
    depends_on = [ azurerm_network_interface.nicblock ]
    name = var.nic
    resource_group_name = var.newrg
}
data "azurerm_network_security_group" "dnsg" {
    depends_on = [ azurerm_network_security_group.nsgblock ]
    name = var.nsg
    resource_group_name = var.newrg
}
#VM
resource "azurerm_linux_virtual_machine" "vmblock" {
    depends_on = [azurerm_network_interface.nicblock]
    name = var.avm
    location = var.loc
    resource_group_name = var.newrg
    size = "Standard_D2s_v3"
    admin_username = var.user
    admin_password = var.pass
    network_interface_ids = [ azurerm_network_interface.nicblock.id ]
    disable_password_authentication = "false"
    os_disk{
        caching = "ReadWrite"
        storage_account_type = var.account
    }
  source_image_reference {
  publisher = "canonical"
  offer     = "ubuntu-24_04-lts"
  sku       = "server"
  version   = "latest"
}
}
output "vmip" {
    value = azurerm_public_ip.pipblock.ip_address
}

