@{
    RootModule        = 'Driscoll.Bike.psm1'
    ModuleVersion     = '0.0.1'
    GUID              = '9e852256-9c29-4750-adf8-24732242e4a3'
    Author            = 'Adam Driscoll'
    CompanyName       = 'Ironman Software'
    Copyright         = '(c) Ironman Software. All rights reserved.'
    Description       = '🚲'
    FunctionsToExport = @('Show-Bike')
    RequiredModules   = @('Driscoll.Handlebars', 'Driscoll.Frame', 'Driscoll.Seat', 'Driscoll.Wheel')
}

