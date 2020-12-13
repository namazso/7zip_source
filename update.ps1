$Last = [datetime](Get-Content -Encoding UTF8 "last.txt")
$Result = Invoke-WebRequest "https://sourceforge.net/projects/sevenzip/rss?path=/7-Zip" -UseBasicParsing;
$Rss = [xml]$Result;
$Rss.rss.channel.item | % {
    [PSCustomObject]@{
        'Title' = $_.title."#cdata-section"
        'Link' = $_.link
        'PubDate' = [datetime]($_.pubDate -replace ' UT','')
        'SfFileId' = $_."sf-file-id"."#text"
    }
} | ? { $_.PubDate -gt $Last } | ? { $_.Title -match '-src\.7z$' } | Sort-Object -Property PubDate | % {
	Remove-Item 'src*' -Recurse -Force
	try {
		Invoke-WebRequest -UserAgent "Wget/1.12 (linux-gnu)" ($_.Link -replace 'https:\/\/sourceforge\.net\/projects\/([^\/]*)\/files\/(.*)\/download','https://downloads.sourceforge.net/project/$1/$2') -OutFile "src.7z"
		7za x src.7z -osrc
		Remove-Item "src.7z" -Force
		$_.PubDate | Set-Content -Encoding UTF8 "last.txt"
		git add -A
		git commit -am ("From " + $_.Title + " released at " + $_.PubDate)
	} catch {}
}
