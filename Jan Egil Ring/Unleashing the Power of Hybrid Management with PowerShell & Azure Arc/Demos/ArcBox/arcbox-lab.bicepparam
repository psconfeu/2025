using 'C:\repos\azure_arc\azure_jumpstart_arcbox\bicep\main.bicep'

param tenantId = 'insert-your-tenant-id-here'

param windowsAdminUsername = 'arcdemo'

param flavor = 'ITPro'

param windowsAdminPassword = 'insert-your-password-here'

param logAnalyticsWorkspaceName = 'arcbox-la'

param deployBastion = false

param vmAutologon = true

param autoShutdownEnabled = true

param autoShutdownTime = '18:00'

param autoShutdownEmailRecipient = 'user@contoso.com'

param rdpPort = '3390'

//param enableAzureSpotPricing = false
