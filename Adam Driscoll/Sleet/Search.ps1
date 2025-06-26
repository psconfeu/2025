sleet feed-settings --set "externalsearch:http://localhost:5000/search/query"
sleet recreate

Find-PSResource -Repository PSConfEUAzure -Name *Bike*
dotnet package search .Handlebars --source 'https://psgalleryeu.blob.core.windows.net/gallery7/index.json'