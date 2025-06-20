# FireOne
PowerShell Module for Controlling FireOne Pyrotechnic Control Systems

#Global Variables
Certain global variables are made avalible to the user via the use of PSFramework configuration settings.  These can be settings configured in a number of ways, more information can be found [here](https://psframework.org/documentation/documents/psframework/configuration/scenario-module.html)
* FireOne.Port.Name - Name of the serial port to use when connecting to the FireOne control system. Default is COM1
* FireOne.Port.Speed - The connection speed of the serial port used when connecting to the FireOne control system. Default is 9600

#Setting Global Variables
Set-PSFConfig -Module FireOne -Name FireOne.Port.Name -Value COM5