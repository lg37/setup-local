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
  # checkov:skip=CKV_AZURE_119: ok, validé pour public IP
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

resource "azurerm_linux_virtual_machine" "mylinux" {
  name                = var.vm_name
  resource_group_name = var.rg
  location            = var.location
  size                = var.vm_size
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]
  custom_data = filebase64("${path.module}/customdata.tpl")

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("${path.module}/mykey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "${var.vm_name}-os"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
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