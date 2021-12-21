Import-module '.\onoff-functions.ps1' -Force

Describe "evaluation procedure" {
    Mock show-notification {}
    Context "no trigger file can be found" {
        Mock get_last_trigger { return $null }
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
    @(
        [PSCustomObject]@{test = "level is low, but trigger already has been sent"; trigger = 10; current = 15; expected = $false },
        [PSCustomObject]@{test = "level is low, last trigger left from turn-off"; trigger = 82; current = 15; expected = $true },
        [PSCustomObject]@{test = "level is high, last trigger left from turn-on"; trigger = 15; current = 82; expected = $true },
        [PSCustomObject]@{test = "level is high, but trigger already has been sent"; trigger = 85; current = 83; expected = $false }
    ) | Foreach-Object {
        $tc = $_
        Context "$($tc.test)" {
            It "sends $($tc.expected)" {
                Mock get-level { return $tc.trigger }
                evaluate -proc $tc.current -lowerTreshold 20 -upperTreshold 80 | should -be $tc.expected
            }
        }
    }
}

Describe "get-level" {
    Context "no trigger" {
        It "returns -1" {
            $null | get-level | should -be -1
        }
    }
    Context "trigger is a non-null number" {
        @(
            [PSCustomObject]@{ trigger = "asdf_adf_01"; expected = 1 },
            [PSCustomObject]@{ trigger = "foo_bar_2"; expected = 2 },
            [PSCustomObject]@{ trigger = "foo_bar_12"; expected = 12 },
            [PSCustomObject]@{ trigger = "211221_1221_12"; expected = 12 }
        ) | foreach {
            It "converts to an integer ($($_.trigger) => $($_.expected))" {
                $($_.trigger) | get-level | should -be $($_.expected) } 
        }
    }
}
