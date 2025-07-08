param (
    [double]$RegionAreaW,
    [double]$RegionAreaH,
    [double]$RegionAreaX,
    [double]$RegionAreaY,
    [double]$ImageWidth,
    [double]$ImageHeight
)

# Calculate crop parameters
$cropX = [math]::Floor(($RegionAreaX - ($RegionAreaW / 2)) * $ImageWidth)
$cropY = [math]::Floor(($RegionAreaY - ($RegionAreaH / 2)) * $ImageHeight)
$cropW = [math]::Floor($RegionAreaW * $ImageWidth)
$cropH = [math]::Floor($RegionAreaH * $ImageHeight)

# Format as ImageMagick crop string
$crop = "-crop ${cropW}x${cropH}+${cropX}+${cropY}"

# Output the crop string
Write-Output $crop

