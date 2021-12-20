[cmdletbinding()]
param(
  [bool]$force = $false,
  [int]$lowerTreshold = 30, #22
  [int]$upperTreshold = 80  #82
)

Import-Module '.\onoff-functions.ps1' -force

launch -force $force -lowerTreshold $lowerTreshold -upperTreshold $upperTreshold
