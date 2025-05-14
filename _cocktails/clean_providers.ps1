Get-ChildItem -Include .terraform -Recurse -force | Remove-Item -Force -Recurse
Get-ChildItem -Include .git -Recurse -force | Remove-Item -Force -Recurse
