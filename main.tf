resource "azurerm_resource_group" "main" {
  name = "bjgomes-rg"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name = "bjgomes-vnet"
  location = "eastus"
  resource_group_name = azurerm_resource_group.main.name
  address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "main" {
  name = "bjgomes-subnet"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes = [cidrsubnet(azurerm_virtual_network.main.address_space[0], 8, 1)]

}

resource "azurerm_public_ip" "main" {
  count = 2
  name = "bjgomes-pip-${count.index}"
  location = "eastus"
  resource_group_name = azurerm_resource_group.main.name
  allocation_method = "Static"
  sku = "Standard"  
}

resource "azurerm_network_interface" "main" {
  count = 2
  name = "bjgomes-nic-${count.index}"
  location = "eastus"
  resource_group_name = azurerm_resource_group.main.name
  

  ip_configuration {
    name = "bjgomes-nic-01-ipconfig-${count.index}"
    subnet_id = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.main[count.index].id
  }
}

resource "azurerm_network_security_group" "main" {
  name = "bjgomes-nsg"
  location = "eastus"
  resource_group_name = azurerm_resource_group.main.name

}

resource "azurerm_network_security_rule" "SSH" {
name = "bjgomes-nsg-rule-01"
priority = 100
direction = "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range = "*"
destination_port_range = "22"
source_address_prefix = "*"
destination_address_prefix = "*"
resource_group_name = azurerm_resource_group.main.name
network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "RDP" {
name = "bjgomes-nsg-rule-02"
priority = 105
direction = "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range = "*"
destination_port_range = "3389"
source_address_prefix = "*"
destination_address_prefix = "*"
resource_group_name = azurerm_resource_group.main.name
network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "HTTP" {
name = "bjgomes-nsg-rule-03"
priority = 110
direction = "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range = "*"
destination_port_range = "80"
source_address_prefix = "*"
destination_address_prefix = "*"
resource_group_name = azurerm_resource_group.main.name
network_security_group_name = azurerm_network_security_group.main.name
}


resource "azurerm_network_interface_security_group_association" "main" {
  count = 2
  network_interface_id      = azurerm_network_interface.main[count.index].id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_linux_virtual_machine" "main" {
  name = "bjgomes-vm-01"
  location = "eastus"
  resource_group_name = azurerm_resource_group.main.name
  size = "Standard_D2s_v3"
  admin_username = "bjgomes"
  network_interface_ids = [azurerm_network_interface.main[0].id]
  admin_password = "0987^%$#poiuYTRE"
  disable_password_authentication = false
  computer_name = "bjgomes-vm-01"
  os_disk {
    name = "bjgomes-vm-01-osdisk"
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

}

resource "azurerm_windows_virtual_machine" "main" {
  name = "bjgomes-vm-02"
  location = "eastus"
  resource_group_name = azurerm_resource_group.main.name
  size = "Standard_D2s_v3"
  admin_username = "bjgomes"
  network_interface_ids = [azurerm_network_interface.main[1].id]
  admin_password = "0987^%$#poiuYTRE"
  computer_name = "bjgomes-vm-02"
  os_disk {
    name = "bjgomes-vm-02-osdisk"
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  
}

resource "azurerm_virtual_machine_extension" "main" {
  name = "bjgomes-vm-01-ext"
  virtual_machine_id = azurerm_windows_virtual_machine.main.id
  publisher = "Microsoft.Compute"
  type = "CustomScriptExtension"
  type_handler_version = "1.10"
  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -Name Web-Server -IncludeManagementTools"
    }
SETTINGS
}