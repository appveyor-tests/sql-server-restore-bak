$ErrorActionPreference = "Stop"
$env:isVs2017 = 'false'
if (test-path "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community") { $env:isVs2017 = 'true' }
if ($env:isVs2017 -eq 'true' -and ($env:SQL_INSTANCE_NAME -eq 'SQL2008R2SP2' -or $env:SQL_INSTANCE_NAME -eq 'SQL2012SP1')) { Exit-AppveyorBuild }

Write-Host "Starting SQL Server instance: $env:SQL_INSTANCE_NAME"
Start-Service "MSSQL`$$env:SQL_INSTANCE_NAME"
cmd /c sqlcmd -S localhost -U SA -P Password12! -Q "select @@VERSION"

Write-Host "Testing connectivity with named instance over named pipes"
$env:connection_string_with_instance = "Server=(local)\$env:SQL_INSTANCE_NAME;Database=master;User ID=sa;Password=Password12!"
$conn = New-Object System.Data.SqlClient.SqlConnection
$conn.ConnectionString = $env:connection_string_with_instance
$conn.Open()
      
Write-Host "Creating Northwind database"
$cmd = New-Object System.Data.SqlClient.SqlCommand("Create database Northwind", $conn)
$cmd.ExecuteNonQuery() | Out-Null
      
Write-Host "Restoring Northwind database"
$cmd = New-Object System.Data.SqlClient.SqlCommand("Restore database Northwind from disk='$env:appveyor_build_folder\northwind.bak' WITH REPLACE, move 'Northwind' to '$env:appveyor_build_folder\northwind.mdf', move 'Northwind_log' to '$env:appveyor_build_folder\northwind_log.ldf'", $conn)
$cmd.ExecuteNonQuery() | Out-Null
      
Write-Host "List tables in Northwind database"
$cmd = New-Object System.Data.SqlClient.SqlCommand("SELECT * FROM northwind.information_schema.tables", $conn)
$reader = $cmd.ExecuteReader()
while($reader.Read())
{
  Write-Host "Table: $($reader["table_name"])"
}
$conn.Close()
dir
