#RG
resource "azurerm_resource_group" "brg"{
    name = var.rg1
    location = var.loc
}
#STORAGE
resource "azurerm_storage_account" "bstore"{
    depends_on = [azurerm_resource_group.brg]
    name = var.storagename
    location = var.loc
    resource_group_name = var.rg1
    account_tier ="Standard"
    account_replication_type = "GRS"
    tags = {
                environment = "test"
                managed_by = "Anup"
            }
}
#VNET
resource "azurerm_virtual_network" "bvnet"{
    depends_on = [azurerm_resource_group.brg]
    name = var.vnetname
    location = var.loc
    resource_group_name = var.rg1
    address_space = ["10.0.0.0/24"]
}
#Subnet
resource "azurerm_subnet" "bsub"{
     depends_on = [azurerm_virtual_network.bvnet,azurerm_resource_group.brg]
    name= var.subnet
    virtual_network_name = var.vnetname
    resource_group_name = var.rg1
    address_prefixes = ["10.0.0.0/27"]
    }
    #publicip
    resource "azurerm_public_ip" "cpip"{
        depends_on = [azurerm_resource_group.brg]
        name = var.bpip
        location = var.loc
        resource_group_name = var.rg1
        allocation_method = "Static"
    }
    #Nsg
    resource "azurerm_network_security_group" "gnsg"{
        depends_on = [azurerm_resource_group.brg]
        name = var.nsg
        resource_group_name = var.rg1
        location = var.loc
        security_rule{
            name="asr"
            priority = 100
            direction = "Inbound"
            access ="Allow"
            protocol = "Tcp"
            source_port_range = "*"
            destination_port_range = "22"
            source_address_prefix = "*"
            destination_address_prefix = "*"
           
        }
    }
resource "azurerm_network_interface" "bni"{
    depends_on = [azurerm_subnet.bsub,azurerm_public_ip.cpip]
    name= var.ani
    location = var.loc
    resource_group_name = var.rg1
    ip_configuration{
        name = "test"
        subnet_id = data.azurerm_subnet.gsub.id
        private_ip_address_allocation = "Dynamic"
      public_ip_address_id = data.azurerm_public_ip.gpip.id
    }
}
data "azurerm_subnet" "gsub"{
     depends_on = [azurerm_subnet.bsub]
    name =var.subnet
    virtual_network_name = var.vnetname
    resource_group_name = var.rg1
}
data "azurerm_public_ip" "gpip"{
    depends_on = [azurerm_resource_group.brg,azurerm_public_ip.cpip]
    name =var.bpip
    resource_group_name = var.rg1
}
resource "azurerm_network_interface_security_group_association" "anisg"{
    depends_on = [azurerm_network_interface.bni,azurerm_network_security_group.gnsg]
    network_interface_id = data.azurerm_network_interface.dni.id
    network_security_group_id = data.azurerm_network_security_group.dsg.id
}
data "azurerm_network_interface" "dni"{
     depends_on = [azurerm_network_interface.bni]
    name =var.ani
    resource_group_name = var.rg1
}
data "azurerm_network_security_group" "dsg"{
    depends_on = [azurerm_network_security_group.gnsg]
    name =var.nsg
    resource_group_name = var.rg1
}
resource "azurerm_linux_virtual_machine" "avm"{
    name = var.azvm
    location = var.loc
    resource_group_name = var.rg1
    size = "Standard_D2s_v3"
    admin_username = "adminuser"
    admin_password = "Adminpass@123"
    network_interface_ids = [azurerm_network_interface.bni.id]
    disable_password_authentication = false
    os_disk{
        caching = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }
   source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
}
}
output "vmip"{
    value= azurerm_public_ip.cpip.ip_address
}