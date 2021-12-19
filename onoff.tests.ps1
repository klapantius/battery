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
    Context "between limits" {
        20, 21, 50, 79, 80 | ForEach-Object {
            It "results $false (battery level $_%)" {
                evaluate -proc $_ -lowerTreshold 20 -upperTreshold 80 | Should -be $false
            }
        }
    }
    Context "treshold exceeded" {
        19, 81 | ForEach-Object {
            It "results $true (battery level $_%)" {
                evaluate -proc $_ -lowerTreshold 20 -upperTreshold 80 | Should -be $true
            }
        }
    }
}