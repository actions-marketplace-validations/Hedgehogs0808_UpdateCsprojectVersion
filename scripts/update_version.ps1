param(
    [string]$src_dir # ソースファイルのパス
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# cprojファイルのバージョン情報の更新
Push-Location $src_dir
foreach ($dir in $(Get-ChildItem * | ? { $_.PSIsContainer }))
{
    Push-Location $dir
    foreach ($file in $(Get-ChildItem *.csproj -Recurse))
    {
        if($file | Test-Path)
        {
            $xml_doc = [xml](cat $file -enc utf8)
            $xml_nav = $xml_doc.CreateNavigator()
            # ライブラリバージョンの更新
            $libver = $xml_nav.Select("/Project/PropertyGroup/Version")
            $majVer,$minVer,$bldVer = ([string]$libver).Split(".")
            $majVer = [int]([int]$majVer+1);
            $newver = [string]$majVer + "." + $minVer + "." + $bldVer
            $libver.SetValue($newver);
            # 参照パッケージのバージョン情報の更新
            $nodes = $xml_nav.Select("/Project/ItemGroup/PackageReference")
            While ($nodes.MoveNext()) # MoveNext()メソッドによる値の取り出し
            {
                try
                {
                    $libName = $nodes.Current.getattribute("Include", "")
                    $v=[string](gh release view -R https://github.com/maegawa-h/$libName)
                    $v -match 'tag:\s(?<version>.*?)\s' >> $null
                    $version = $nodes.Current.Select("./@Version")
                    if ($Matches.version)
                    {
                        $version.SetValue($Matches.version)
                        Write-Host [M]$libName reference version: $Matches.version;
                    }
                }
                catch
                {
                
                }
            }
            $xml_doc.Save($file)
        }
        Write-Host ""
    }
    Pop-Location
}
Pop-Location

return $newver
