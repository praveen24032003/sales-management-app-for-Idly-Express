#requires -Version 5.1
<#
.SYNOPSIS
  Render the Idly Express brand glyph to PNG files used as launcher-icon
  source assets. Pure GDI+ — no external image services or binaries.

.DESCRIPTION
  Produces two outputs in assets/branding/:
    - icon_source.png      1024x1024, full-bleed gradient (Android adaptive bg
                           is applied separately; this one fills the safe area
                           on its own).
    - icon_foreground.png  1024x1024, transparent background with the white
                           plate+dome+steam glyph centered at 60% size so the
                           Android adaptive launcher can scale/mask it.

  Run from the project root:
    powershell -ExecutionPolicy Bypass -File tool/generate_brand_icon.ps1
#>

Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$outDir      = Join-Path $projectRoot 'assets\branding'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

$size = 1024

function New-IcoBitmap {
    param([int]$Width, [int]$Height)
    return [System.Drawing.Bitmap]::new($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
}

function Get-Graphics {
    param([System.Drawing.Bitmap]$Bitmap)
    $g = [System.Drawing.Graphics]::FromImage($Bitmap)
    $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    return $g
}

function New-RoundedRectPath {
    param([float]$X, [float]$Y, [float]$Width, [float]$Height, [float]$Radius)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $Radius * 2
    $path.AddArc($X, $Y, $d, $d, 180, 90)
    $path.AddArc($X + $Width - $d, $Y, $d, $d, 270, 90)
    $path.AddArc($X + $Width - $d, $Y + $Height - $d, $d, $d, 0, 90)
    $path.AddArc($X, $Y + $Height - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

function Draw-Glyph {
    param(
        [System.Drawing.Graphics]$G,
        [float]$CenterX,
        [float]$CenterY,
        [float]$GlyphSize
    )

    $white = [System.Drawing.Color]::FromArgb(242, 255, 255, 255)
    $steam = [System.Drawing.Color]::FromArgb(180, 255, 255, 255)

    # plate
    $plateWidth  = $GlyphSize * 0.66
    $plateHeight = $GlyphSize * 0.16
    $plateX = $CenterX - ($plateWidth / 2)
    $plateY = $CenterY + ($GlyphSize * 0.10)
    $platePath = New-RoundedRectPath -X $plateX -Y $plateY -Width $plateWidth -Height $plateHeight -Radius ($GlyphSize * 0.08)
    $platePen = New-Object System.Drawing.SolidBrush $white
    $G.FillPath($platePen, $platePath)
    $platePen.Dispose()
    $platePath.Dispose()

    # dome
    $domeRadius = $GlyphSize * 0.22
    $domeRect = New-Object System.Drawing.RectangleF (
        ($CenterX - $domeRadius),
        ($CenterY - $domeRadius - ($GlyphSize * 0.02)),
        ($domeRadius * 2),
        ($domeRadius * 2)
    )
    $domeBrush = New-Object System.Drawing.SolidBrush $white
    $G.FillEllipse($domeBrush, $domeRect)
    $domeBrush.Dispose()

    # steam (three rounded vertical strokes)
    $steamPen = New-Object System.Drawing.Pen ($steam, ($GlyphSize * 0.06))
    $steamPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $steamPen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
    $steamGap = $GlyphSize * 0.18
    $steamTopY = $CenterY - ($GlyphSize * 0.34)
    $steamLength = $GlyphSize * 0.14
    foreach ($offset in @(-1, 0, 1)) {
        $x = $CenterX + ($offset * $steamGap)
        $yOffset = if ($offset -eq 0) { -($GlyphSize * 0.02) } else { 0 }
        $G.DrawLine($steamPen, $x, ($steamTopY + $yOffset), $x, ($steamTopY + $steamLength + $yOffset))
    }
    $steamPen.Dispose()
}

# ---------- icon_source.png (full-bleed) ----------
Write-Host "Rendering icon_source.png ..."
$src = New-IcoBitmap -Width $size -Height $size
$gSrc = Get-Graphics -Bitmap $src

# Rounded-square gradient background (matches the Flutter BrandGlyph)
$bgRadius = $size * 0.20
$bgPath = New-RoundedRectPath -X 0 -Y 0 -Width $size -Height $size -Radius $bgRadius
$gradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
    (New-Object System.Drawing.PointF (0, 0)),
    (New-Object System.Drawing.PointF ($size, $size)),
    ([System.Drawing.Color]::FromArgb(255, 53, 168, 216)),
    ([System.Drawing.Color]::FromArgb(255, 26, 110, 145))
)
$gSrc.FillPath($gradient, $bgPath)
$gradient.Dispose()
$bgPath.Dispose()

Draw-Glyph -G $gSrc -CenterX ($size / 2) -CenterY ($size * 0.55) -GlyphSize ($size * 0.82)
$gSrc.Dispose()
$srcPath = Join-Path $outDir 'icon_source.png'
$src.Save($srcPath, [System.Drawing.Imaging.ImageFormat]::Png)
$src.Dispose()
Write-Host "  -> $srcPath"

# ---------- icon_foreground.png (transparent bg, smaller glyph for adaptive icon) ----------
Write-Host "Rendering icon_foreground.png ..."
$fg = New-IcoBitmap -Width $size -Height $size
$gFg = Get-Graphics -Bitmap $fg
# Adaptive-icon foreground: glyph at ~50% so the system mask doesn't crop steam.
Draw-Glyph -G $gFg -CenterX ($size / 2) -CenterY ($size * 0.55) -GlyphSize ($size * 0.50)
$gFg.Dispose()
$fgPath = Join-Path $outDir 'icon_foreground.png'
$fg.Save($fgPath, [System.Drawing.Imaging.ImageFormat]::Png)
$fg.Dispose()
Write-Host "  -> $fgPath"

Write-Host "`nDone. Both PNGs written to $outDir"
