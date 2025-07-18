BeforeAll {
    function Get-User {
        @{
            Name = "Jakub"
            Age = 31
        }
    }
}

Describe "describe" {
    It "is Jakub" {
        $user = Get-User

        $user | Should -Not -BeNullOrEmpty -ErrorAction Stop
        $user.Name | Should -Be "Jakub"
        $user.Age | Should -Be 31

    }

    It "is Tomas" {
        $user = Get-User

        $user | Should -Not -BeNullOrEmpty -ErrorAction Stop
        $user.Name | Should -Be "Tomas"
        $user.Age | Should -Be 27

    }
}