Add-Type -AssemblyName System.Drawing

function New-RoundedRectPath {
    param(
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [float]$Radius
    )

    $d = $Radius * 2
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.StartFigure()
    $path.AddArc($X, $Y, $d, $d, 180, 90)
    $path.AddArc($X + $Width - $d, $Y, $d, $d, 270, 90)
    $path.AddArc($X + $Width - $d, $Y + $Height - $d, $d, $d, 0, 90)
    $path.AddArc($X, $Y + $Height - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

function New-ShieldPath {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.StartFigure()
    $path.AddBezier(286, 202, 344, 142, 430, 120, 512, 140)
    $path.AddBezier(512, 140, 594, 120, 680, 142, 738, 202)
    $path.AddBezier(738, 202, 796, 276, 790, 420, 754, 560)
    $path.AddBezier(754, 560, 706, 660, 622, 756, 512, 848)
    $path.AddBezier(512, 848, 402, 756, 318, 660, 270, 560)
    $path.AddBezier(270, 560, 234, 420, 228, 276, 286, 202)
    $path.CloseFigure()
    return $path
}

function Save-ScaledPng {
    param(
        [System.Drawing.Bitmap]$Source,
        [int]$Size,
        [string]$Path
    )

    $bitmap = New-Object System.Drawing.Bitmap($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.DrawImage($Source, 0, 0, $Size, $Size)

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}

function New-ShadowBrush {
    param([int]$Alpha)
    return New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($Alpha, 0, 0, 0))
}

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$masterPath = Join-Path $root 'assets\branding\app-icon-1024.png'

$master = New-Object System.Drawing.Bitmap(1024, 1024)
$graphics = [System.Drawing.Graphics]::FromImage($master)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$graphics.Clear([System.Drawing.Color]::FromArgb(255, 7, 10, 20))

$panelPath = New-RoundedRectPath -X 84 -Y 74 -Width 856 -Height 876 -Radius 122
$panelGradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.PointF(120, 82)),
    (New-Object System.Drawing.PointF(940, 950)),
    ([System.Drawing.Color]::FromArgb(255, 29, 39, 77)),
    ([System.Drawing.Color]::FromArgb(255, 10, 12, 29))
)
$graphics.FillPath($panelGradient, $panelPath)

$panelBorder = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(56, 255, 255, 255), 3)
$graphics.DrawPath($panelBorder, $panelPath)

$panelGlowPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$panelGlowPath.AddEllipse(120, 60, 790, 790)
$panelGlowBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($panelGlowPath)
$panelGlowBrush.CenterColor = [System.Drawing.Color]::FromArgb(34, 120, 165, 255)
$panelGlowBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 120, 165, 255))
$graphics.FillEllipse($panelGlowBrush, 120, 60, 790, 790)

$shieldPath = New-ShieldPath
$shieldInteriorBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 10, 15, 36))
$shieldShadow = New-ShadowBrush -Alpha 88
$graphics.TranslateTransform(0, 12)
$graphics.FillPath($shieldShadow, $shieldPath)
$graphics.ResetTransform()
$graphics.FillPath($shieldInteriorBrush, $shieldPath)

$shieldGlowBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.PointF(260, 200)),
    (New-Object System.Drawing.PointF(760, 820)),
    ([System.Drawing.Color]::FromArgb(110, 70, 180, 255)),
    ([System.Drawing.Color]::FromArgb(110, 204, 95, 255))
)
$shieldGlowPen = New-Object System.Drawing.Pen($shieldGlowBrush, 42)
$shieldGlowPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
$graphics.DrawPath($shieldGlowPen, $shieldPath)

$shieldEdgeBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.PointF(260, 200)),
    (New-Object System.Drawing.PointF(760, 820)),
    ([System.Drawing.Color]::FromArgb(255, 92, 198, 255)),
    ([System.Drawing.Color]::FromArgb(255, 195, 88, 255))
)
$shieldEdgePen = New-Object System.Drawing.Pen($shieldEdgeBrush, 24)
$shieldEdgePen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
$graphics.DrawPath($shieldEdgePen, $shieldPath)

$documentShadowPath = New-RoundedRectPath -X 368 -Y 278 -Width 248 -Height 310 -Radius 30
$graphics.TranslateTransform(10, 14)
$graphics.FillPath((New-ShadowBrush -Alpha 68), $documentShadowPath)
$graphics.ResetTransform()

$documentPath = New-RoundedRectPath -X 350 -Y 260 -Width 248 -Height 310 -Radius 30
$documentGradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.PointF(350, 260)),
    (New-Object System.Drawing.PointF(598, 570)),
    ([System.Drawing.Color]::FromArgb(255, 245, 246, 255)),
    ([System.Drawing.Color]::FromArgb(255, 153, 147, 202))
)
$graphics.FillPath($documentGradient, $documentPath)

$documentHighlightPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(84, 255, 255, 255), 3)
$graphics.DrawPath($documentHighlightPen, $documentPath)

$foldPoints = [System.Drawing.PointF[]]@(
    (New-Object System.Drawing.PointF(510, 260)),
    (New-Object System.Drawing.PointF(598, 260)),
    (New-Object System.Drawing.PointF(598, 348))
)
$foldGradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.PointF(510, 260)),
    (New-Object System.Drawing.PointF(598, 348)),
    ([System.Drawing.Color]::FromArgb(255, 255, 255, 255)),
    ([System.Drawing.Color]::FromArgb(255, 204, 199, 236))
)
$graphics.FillPolygon($foldGradient, $foldPoints)

$foldShadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(58, 8, 10, 30))
$foldShadowPoints = [System.Drawing.PointF[]]@(
    (New-Object System.Drawing.PointF(510, 260)),
    (New-Object System.Drawing.PointF(558, 260)),
    (New-Object System.Drawing.PointF(598, 300)),
    (New-Object System.Drawing.PointF(598, 348))
)
$graphics.FillPolygon($foldShadowBrush, $foldShadowPoints)

$linePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(190, 35, 42, 86), 14)
$linePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$linePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$graphics.DrawLine($linePen, 414, 392, 508, 392)
$graphics.DrawLine($linePen, 414, 452, 544, 452)
$linePen.Width = 12
$graphics.DrawLine($linePen, 414, 512, 490, 512)
$graphics.DrawLine($linePen, 414, 570, 470, 570)

$state = $graphics.Save()
$graphics.TranslateTransform(560, 514)
$graphics.RotateTransform(42)

$penShadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(66, 0, 0, 0))
$graphics.FillPath($penShadowBrush, (New-RoundedRectPath -X -74 -Y -18 -Width 172 -Height 38 -Radius 18))

$penBodyPath = New-RoundedRectPath -X -86 -Y -22 -Width 172 -Height 44 -Radius 20
$penBodyGradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.PointF(-86, -22)),
    (New-Object System.Drawing.PointF(86, 22)),
    ([System.Drawing.Color]::FromArgb(255, 18, 22, 43)),
    ([System.Drawing.Color]::FromArgb(255, 49, 55, 92))
)
$graphics.FillPath($penBodyGradient, $penBodyPath)

$penBodyEdge = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(88, 255, 255, 255), 3)
$graphics.DrawPath($penBodyEdge, $penBodyPath)

$gripBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.PointF(-6, -22)),
    (New-Object System.Drawing.PointF(34, 22)),
    ([System.Drawing.Color]::FromArgb(255, 10, 13, 28)),
    ([System.Drawing.Color]::FromArgb(255, 28, 33, 62))
)
$graphics.FillPath($gripBrush, (New-RoundedRectPath -X -8 -Y -22 -Width 48 -Height 44 -Radius 18))

$nibPoints = [System.Drawing.PointF[]]@(
    (New-Object System.Drawing.PointF(-130, 0)),
    (New-Object System.Drawing.PointF(-86, -24)),
    (New-Object System.Drawing.PointF(-86, 24))
)
$nibGradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.PointF(-130, 0)),
    (New-Object System.Drawing.PointF(-86, 24)),
    ([System.Drawing.Color]::FromArgb(255, 250, 252, 255)),
    ([System.Drawing.Color]::FromArgb(255, 166, 176, 221))
)
$graphics.FillPolygon($nibGradient, $nibPoints)
$graphics.DrawLine((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(188, 28, 32, 66), 2)), -116, 0, -100, 0)
$graphics.DrawLine((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(188, 28, 32, 66), 2)), -100, 0, -88, -10)
$graphics.DrawLine((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(188, 28, 32, 66), 2)), -100, 0, -88, 10)

$capBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.PointF(44, -22)),
    (New-Object System.Drawing.PointF(86, 22)),
    ([System.Drawing.Color]::FromArgb(255, 16, 19, 38)),
    ([System.Drawing.Color]::FromArgb(255, 34, 39, 72))
)
$graphics.FillPath($capBrush, (New-RoundedRectPath -X 40 -Y -22 -Width 50 -Height 44 -Radius 18))

$clipPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(228, 241, 244, 255), 8)
$clipPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$clipPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$graphics.DrawLine($clipPen, 48, -24, 82, -2)
$graphics.DrawLine($clipPen, 82, -2, 62, 28)

$graphics.Restore($state)

foreach ($directory in @(
    (Split-Path -Parent $masterPath),
    (Join-Path $root 'android\app\src\main\res\mipmap-mdpi'),
    (Join-Path $root 'android\app\src\main\res\mipmap-hdpi'),
    (Join-Path $root 'android\app\src\main\res\mipmap-xhdpi'),
    (Join-Path $root 'android\app\src\main\res\mipmap-xxhdpi'),
    (Join-Path $root 'android\app\src\main\res\mipmap-xxxhdpi'),
    (Join-Path $root 'web\icons')
)) {
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
}

$master.Save($masterPath, [System.Drawing.Imaging.ImageFormat]::Png)

$targets = @(
    @{ Size = 48; Path = Join-Path $root 'android\app\src\main\res\mipmap-mdpi\ic_launcher.png' },
    @{ Size = 72; Path = Join-Path $root 'android\app\src\main\res\mipmap-hdpi\ic_launcher.png' },
    @{ Size = 96; Path = Join-Path $root 'android\app\src\main\res\mipmap-xhdpi\ic_launcher.png' },
    @{ Size = 144; Path = Join-Path $root 'android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png' },
    @{ Size = 192; Path = Join-Path $root 'android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png' },
    @{ Size = 32; Path = Join-Path $root 'web\favicon.png' },
    @{ Size = 192; Path = Join-Path $root 'web\icons\Icon-192.png' },
    @{ Size = 192; Path = Join-Path $root 'web\icons\Icon-maskable-192.png' },
    @{ Size = 512; Path = Join-Path $root 'web\icons\Icon-512.png' },
    @{ Size = 512; Path = Join-Path $root 'web\icons\Icon-maskable-512.png' }
)

foreach ($target in $targets) {
    Save-ScaledPng -Source $master -Size $target.Size -Path $target.Path
}

$clipPen.Dispose()
$capBrush.Dispose()
$gripBrush.Dispose()
$penBodyEdge.Dispose()
$penBodyGradient.Dispose()
$penShadowBrush.Dispose()
$linePen.Dispose()
$foldShadowBrush.Dispose()
$foldGradient.Dispose()
$documentHighlightPen.Dispose()
$documentGradient.Dispose()
$documentPath.Dispose()
$documentShadowPath.Dispose()
$shieldEdgePen.Dispose()
$shieldGlowPen.Dispose()
$shieldEdgeBrush.Dispose()
$shieldGlowBrush.Dispose()
$shieldInteriorBrush.Dispose()
$shieldShadow.Dispose()
$shieldPath.Dispose()
$panelGlowBrush.Dispose()
$panelGlowPath.Dispose()
$panelBorder.Dispose()
$panelGradient.Dispose()
$panelPath.Dispose()
$graphics.Dispose()
$master.Dispose()

Write-Host "Generated icon assets at $masterPath"
