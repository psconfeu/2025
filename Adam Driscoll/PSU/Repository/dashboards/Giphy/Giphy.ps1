New-UDApp -Content { 
    New-UDButton -Text "Gif me!"  -OnClick {
        $Gif = Invoke-RestMethod "https://api.giphy.com/v1/gifs/random?api_key=$($Secret:Giphy)&tag=dog&rating=g"
        $Session:ImageUrl = $Gif.Data.Images.Original.Url
        Sync-UDElement -Id 'gif'
    } -ShowLoading

    New-UDDynamic -Id 'gif' -Content {
        if ($Session:ImageUrl) {
            New-UDImage -Url $Session:ImageUrl
        }
    }
}