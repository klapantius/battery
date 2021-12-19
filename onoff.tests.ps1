Import-module '.\onoff-functions.ps1' -Force

Describe "evaluation procedure" {
    Mock show-notification {}
    Context "force mode on" {
        0, 50, 100 | ForEach-Object {
            It "results $true (battery level $_%)" {
                evaluate -force $true -proc $_ -lowerTreshold 20 -upperTreshold 80 | Should -be $true
            }
        }
    }
}