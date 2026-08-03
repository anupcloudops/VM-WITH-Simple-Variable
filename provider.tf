terraform {
  required_providers{
    azurerm = {
        source = "hashicorp/azurerm"
        version = "4.68.0"
    }
  }
backend "azurerm" {
    resource_group_name  = "for-backend"
    storage_account_name = "pipelinekeliye"
    container_name       = "pipestorage"
    key                  = "app.tfstate"
  }
}
provider "azurerm"{
    features{}
    subscription_id = "05dbb74f-6152-4a1d-a1fd-c49be5c3fd99"
}
