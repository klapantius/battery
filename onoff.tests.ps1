Describe 'onoff-functions' {
    BeforeAll {
        Import-module '.\onoff-functions.ps1' -Force
    }
    
    Describe "evaluation procedure" {
        BeforeAll {
            Mock show-notification {}
            Mock write-log {}
        }
        Context "no trigger file can be found" {
            BeforeAll {
                Mock get-lastTrigger { return $null }
            }
            Context "force mode on" {
                It "results $true (battery level <_>%)" -ForEach ( 10, 50, 100 ) {
                    evaluate -force $true -proc $_ -lowerTreshold '20' -upperTreshold '80' | Should -be $true
                }
            }
            Context "between limits" {
                It "results $false (battery level <_>%)" -ForEach ( 20, 21, 50, 79, 80 ) {
                    evaluate -proc $_ -lowerTreshold 20 -upperTreshold 80 | Should -be $false
                }
            }
            Context "treshold exceeded" {
                It "results $true (battery level $_%)" -ForEach ( 19, 81 ) {
                    evaluate -proc $_ -lowerTreshold 20 -upperTreshold 80 | Should -be $true
                }
            } 
        }
        Context "<test>" -Foreach @(
            @{test = "level is low, but trigger already has been sent"; lastTrigger = 10; current = 15; expected = $false },
            @{test = "level is low, last trigger left from turn-off"; lastTrigger = 82; current = 15; expected = $true },
            @{test = "level is high, last trigger left from turn-on"; lastTrigger = 15; current = 82; expected = $true },
            @{test = "level is high, but trigger already has been sent"; lastTrigger = 85; current = 83; expected = $false }
        ) {
            It "sends $expected" {
                Mock get-level { return $lastTrigger }
                evaluate -proc $current -lowerTreshold 20 -upperTreshold 80 | should -be $expected
            }
        }
    }
    
    Describe "get-level" {
        Context "no trigger" {
            It "returns -1" {
                $null | get-level | should -be -1
            }
        }
        Context "trigger is a non-null number" -ForEach @(
            @{ trigger = "asdf_adf_01"; expected = 1 },
            @{ trigger = "foo_bar_2"; expected = 2 },
            @{ trigger = "foo_bar_12"; expected = 12 },
            @{ trigger = "211221_1221_12"; expected = 12 },
            @{ trigger = "G:\My Drive\iktato\laptop\240402_1347_18"; expected = 18 }
        ) {
            It "converts to an integer ($trigger => $expected)" {
                $trigger | get-level | should -be $expected } 
        }
    }
}
