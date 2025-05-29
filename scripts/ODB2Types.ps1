#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   ODB2Types.ps1                                                                ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaumep  <guillaumep@luminator.com>                                       ║
#║   Copyright (C) Luminator Technology Group.  All rights reserved.              ║
#╚════════════════════════════════════════════════════════════════════════════════╝


enum PartType {
    Powertrain
    Body
    Chassis
    Network
}

enum CodeType {
    Generic
    ManufacturerSpecific
}

enum SystemCategory {
    FuelAirMetering
    FuelAirMeteringInjector
    IgnitionOrMisfire
    EmissionControl
    SpeedIdleControl
    ComputerOutput
    Transmission
    HybridPropulsion
    Unknown
}

function Get-PartTypeDescription {
    param (
        [Parameter(Mandatory = $true)]
        [PartType]$Part
    )
    switch ($Part) {
        'Powertrain' { 'Powertrain (engine, transmission)' }
        'Body'       { 'Body (AC, airbags)' }
        'Chassis'    { 'Chassis (ABS, suspension)' }
        'Network'    { 'Network (CAN bus, communication)' }
        default      { 'Unknown Part Type' }
    }
}


function Get-CodeTypeDescription {
    param (
        [Parameter(Mandatory = $true)]
        [CodeType]$CodeType
    )
    switch ($CodeType) {
        'Generic'               { 'Generic OBD-II code' }
        'ManufacturerSpecific'  { 'Manufacturer-specific code' }
        default                 { 'Unknown Code Type' }
    }
}


function Get-SystemCategoryDescription {
    param (
        [Parameter(Mandatory = $true)]
        [SystemCategory]$System
    )
    switch ($System) {
        'FuelAirMetering'          { 'Fuel & Air Metering' }
        'FuelAirMeteringInjector' { 'Fuel & Air Metering (injector circuit)' }
        'IgnitionOrMisfire'       { 'Ignition System or Misfire' }
        'EmissionControl'         { 'Auxiliary Emission Control' }
        'SpeedIdleControl'        { 'Vehicle Speed & Idle Control System' }
        'ComputerOutput'          { 'Computer Output Circuit' }
        'Transmission'            { 'Transmission (gearbox)' }
        'HybridPropulsion'        { 'Hybrid Propulsion System' }
        'Unknown'                 { 'Unknown or Reserved System' }
        default                   { 'Unknown System Category' }
    }
}


function Parse-ObdCode {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Enter a 5-character OBD code like P0303")]
        [ValidatePattern('^[PBCU][01][0-9A-C][0-9]{2}$')]
        [string]$Code
    )

    # Determine PartType
    $part = switch ($Code[0]) {
        'P' { [PartType]::Powertrain }
        'B' { [PartType]::Body }
        'C' { [PartType]::Chassis }
        'U' { [PartType]::Network }
    }

    # Determine CodeType
    $codeType = switch ($Code[1]) {
        '0' { [CodeType]::Generic }
        '1' { [CodeType]::ManufacturerSpecific }
    }

    # Determine SystemCategory
    $systemChar = $Code[2]
    $system = switch ($systemChar) {
        '1' { [SystemCategory]::FuelAirMetering }
        '2' { [SystemCategory]::FuelAirMeteringInjector }
        '3' { [SystemCategory]::IgnitionOrMisfire }
        '4' { [SystemCategory]::EmissionControl }
        '5' { [SystemCategory]::SpeedIdleControl }
        '6' { [SystemCategory]::ComputerOutput }
        {$_ -in '7','8','9'} { [SystemCategory]::Transmission }
        {$_ -in 'A','B','C'} { [SystemCategory]::HybridPropulsion }
        Default { [SystemCategory]::Unknown }
    }

    $result = [PSCustomObject]@{
        Code             = $Code
        Part             = $part
        CodeType         = $codeType
        SystemCategory   = $system
        FaultDetailCode  = $Code.Substring(3, 2)
    }

    return $result
}
