[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [switch]$Json
)


function Register-HtmlAgilityPack {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $False)]
        [string]$Path
    )
    begin {
        if ([string]::IsNullOrEmpty($Path)) {
            $Path = "{0}\lib\{1}\HtmlAgilityPack.dll" -f "$PSScriptRoot", "$($PSVersionTable.PSEdition)"
        }
    }
    process {
        try {
            if (-not (Test-Path -Path "$Path" -PathType Leaf)) { throw "no such file `"$Path`"" }
            if (!("HtmlAgilityPack.HtmlDocument" -as [type])) {
                Write-Verbose "Registering HtmlAgilityPack... "
                add-type -Path "$Path"
            } else {
                Write-Verbose "HtmlAgilityPack already registered "
            }
        } catch {
            throw $_
        }
    }
}

function Get-ManufacturerCodeUrl {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("acura","audi","bmw","chevrolet","dodge","chrysler","jeep","ford","honda","hyundai","infiniti","isuzu","jaguar","kia","land","rover","lexus","mazda","mitsubishi","nissan","subaru","toyota","vw")]
        [string]$CarMake
    )

    $SubPath = "/trouble_codes/{0}/" -f $CarMake
    $Url = "https://www.obd-codes.com/{0}" -f $SubPath
    $result = [PSCustomObject]@{
        SubPath         = $SubPath
        Url             = $Url
    }

    return $result
}


function Get-ManufacturerSpecificCodes {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("acura","audi","bmw","chevrolet","dodge","chrysler","jeep","ford","honda","hyundai","infiniti","isuzu","jaguar","kia","land","rover","lexus","mazda","mitsubishi","nissan","subaru","toyota","vw")]
        [string]$CarMake
    )

    try {

        Add-Type -AssemblyName System.Web

        $Null = Register-HtmlAgilityPack

        $Ret = $False

        $Obj = Get-ManufacturerCodeUrl $CarMake

        $Url = $Obj.Url
        $HeadersData = @{
             "authority"="www.obd-codes.com"
             "method"="GET"
             "path"="$($Obj.SubPath)"
             "scheme"="https"
             "accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8"
             "cache-control"="no-cache"
             "pragma"="no-cache"
             "priority"="u=0, i"
             "referer"="https://www.obd-codes.com/trouble_codes/"
        }
        $Results = Invoke-WebRequest -UseBasicParsing -Uri $Url -Headers $HeadersData
        $Data = $Results.Content
        if ($Results.StatusCode -eq 200) {
            $Ret = $True
        }

        $HtmlContent = $Results.Content

        [HtmlAgilityPack.HtmlDocument]$HtmlDoc = @{}
        $HtmlDoc.LoadHtml($HtmlContent)
        $HtmlNode = $HtmlDoc.DocumentNode

        [System.Collections.ArrayList]$ParsedList = [System.Collections.ArrayList]::new()
        $Valid = $True
        $Id = 2
        While($Valid){
                try {
                    $XPathDesc = "/html[1]/body[1]/div[1]/div[2]/table[1]/tr[{0}]" -f $Id
                    $XPathCode = "/html[1]/body[1]/div[1]/div[2]/table[1]/tr[{0}]/td" -f $Id
                    $ResultNodeDesc = $HtmlNode.SelectSingleNode($XPathDesc)
                    $ResultNodeCode = $HtmlNode.SelectSingleNode($XPathCode)
                    Write-Verbose "Id = $Id"

                    if (!$ResultNodeCode) {
                        Write-Verbose "EMPTY"
                        $Valid = $False
                        break;
                    }

                    [string]$Code = $ResultNodeCode.InnerText
                    [string]$Desc = $ResultNodeDesc.InnerText.TrimStart($Code)
                    
                    [pscustomobject]$o = [pscustomobject]@{
                        Code = "$Code"
                        Description = "$Desc"
                    }
                    $Id++
                    Write-Verbose "ok"
                    [void]$ParsedList.Add($o)
                } catch {
                    Write-Verbose "$_"
                    continue;
                }
            
        }
        if ($Json) {
            $ParsedList | ConvertTo-Json
        } else {
            return $ParsedList
        }


    }
    catch {
        Write-Warning "Error occurred: $_"
        return $null
    }
}


function Export-ManufacturerSpecificCodesJson {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $BackupPath = Join-Path "$PSScriptRoot" "ManufacturerSpecificCodes"
    if(![System.IO.Directory]::Exists($BackupPath)){ $Null=[System.IO.Directory]::CreateDirectory($BackupPath) }

    [string[]]$AllMakes = "acura","audi","bmw","chevrolet","dodge","chrysler","jeep","ford","honda","hyundai","infiniti","isuzu","jaguar","kia","land","rover","lexus","mazda","mitsubishi","nissan","subaru","toyota","vw"
    ForEach($make in $AllMakes){
        $Name='{0}.json' -f $make
        $JsonData = Get-ManufacturerSpecificCodes $make | ConvertTo-Json
        $CarMakeJson = Join-Path "$BackupPath" "$Name"
        $JsonData | Set-Content -Path $CarMakeJson
        Write-Host "Wrote $Name"
    }
}

