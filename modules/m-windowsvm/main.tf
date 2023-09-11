resource "azurerm_public_ip" "pip" {
  name                = "${var.vm_name}-pip"
  resource_group_name = var.rg
  location            = var.location
  allocation_method   = "Dynamic"

  tags = {
    env = "dev"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  resource_group_name = var.rg
  location            = var.location
  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
  tags = {
    env = "dev"
  }
}

resource "azurerm_windows_virtual_machine" "mywindows" {
  name                = var.vm_name
  resource_group_name = var.rg
  location            = var.location
  size                = var.vm_size
  admin_username      = "azureuser"
  admin_password      = "Password123!"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "${var.vm_name}-os"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  tags = {
    env = "dev"
  }
}

data "azurerm_public_ip" "pipdata" {
  name                = azurerm_public_ip.pip.name
  resource_group_name = var.rg
}