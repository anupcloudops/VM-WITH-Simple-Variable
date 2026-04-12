terraform {
  required_providers{
    azurerm = {
        source = "hashicorp/azurerm"
        version = "4.68.0"
    }
  }
}
provider "azurerm"{
    features{}
    subscription_id = "6f3ba0f1-4323-4d55-96d4-31240a3f1439"
}
