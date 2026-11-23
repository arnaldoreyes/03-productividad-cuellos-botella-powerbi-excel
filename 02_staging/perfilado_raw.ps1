<#
.SYNOPSIS
    Perfilado reproducible del dataset crudo del Proyecto 3 (Fase 02 - 02_staging).
.DESCRIPTION
    Lee 01_raw/entrada/garments_worker_productivity.csv sin modificarlo y genera un
    diagnóstico completo de calidad de datos, granularidad, nulos, categorías,
    fechas, estadísticas numéricas y casos especiales (productividad > 1 y tiempo muerto).
.NOTES
    Uso:
        powershell -ExecutionPolicy Bypass -File .\02_staging\perfilado_raw.ps1
#>

[CmdletBinding()]
param(
    [string]$RutaCsv = (Join-Path (Split-Path -Parent $PSScriptRoot) '01_raw\entrada\garments_worker_productivity.csv')
)

$ErrorActionPreference = 'Stop'
$inv = [System.Globalization.CultureInfo]::InvariantCulture

if (-not (Test-Path -LiteralPath $RutaCsv)) {
    throw "No se encontró el archivo crudo en: $RutaCsv"
}

function Format-Num {
    param([double]$Valor, [int]$Decimales = 4)
    return $Valor.ToString("N$Decimales", $inv)
}

function Normalize-Department {
    param([string]$Valor)
    if ($null -eq $Valor) { return '' }
    $limpio = $Valor.Trim().ToLowerInvariant()
    if ($limpio -eq 'sweing') { return 'sewing' }
    return $limpio
}

Write-Output "=============================================================================="
Write-Output "PERFILADO DE DATOS CRUDOS - PROYECTO 3 (02_staging/perfilado_raw.ps1)"
Write-Output "Archivo: $RutaCsv"
Write-Output "=============================================================================="

# ------------------------------------------------------------------------------
# 1. Conteo total de filas y verificación de duplicados exactos
# ------------------------------------------------------------------------------
$lineasCrudas = Get-Content -LiteralPath $RutaCsv
$encabezadoLinea = $lineasCrudas[0]
$lineasDatos = $lineasCrudas | Select-Object -Skip 1
$filas = Import-Csv -LiteralPath $RutaCsv
$columnas = @($filas[0].PSObject.Properties | ForEach-Object { $_.Name })

$gruposLineaExacta = $lineasDatos | Group-Object | Where-Object { $_.Count -gt 1 }
$duplicadosExactosGrupos = @($gruposLineaExacta).Count
$duplicadosExactosFilasExtra = if ($duplicadosExactosGrupos -gt 0) {
    ($gruposLineaExacta | Measure-Object -Property Count -Sum).Sum - $duplicadosExactosGrupos
} else { 0 }

Write-Output ""
Write-Output "1. DIMENSIONES Y DUPLICADOS EXACTOS"
Write-Output "------------------------------------------------------------------------------"
Write-Output ("Líneas totales en archivo (incl. encabezado) : {0}" -f $lineasCrudas.Count)
Write-Output ("Filas de datos (Import-Csv)                  : {0}" -f $filas.Count)
Write-Output ("Columnas                                     : {0}" -f $columnas.Count)
Write-Output ("Grupos de filas duplicadas exactas           : {0}" -f $duplicadosExactosGrupos)
Write-Output ("Filas extra por duplicación exacta           : {0}" -f $duplicadosExactosFilasExtra)

# ------------------------------------------------------------------------------
# 2. Verificación de granularidad: date + department (limpio) + team
# ------------------------------------------------------------------------------
Write-Output ""
Write-Output "2. VERIFICACION DE GRANULARIDAD (date + department limpio + team)"
Write-Output "------------------------------------------------------------------------------"

# Enriquecer en memoria (sin alterar el CSV) para auditoría de claves y fechas
$indice = 1
$registros = foreach ($r in $filas) {
    $indice++
    $deptTrimLower = if ($null -ne $r.department) { $r.department.Trim().ToLowerInvariant() } else { '' }
    $deptLimpio = Normalize-Department $r.department
    $fechaDt = [datetime]::MinValue
    $fechaOk = [datetime]::TryParseExact(
        $r.date.Trim(),
        'M/d/yyyy',
        $inv,
        [System.Globalization.DateTimeStyles]::None,
        [ref]$fechaDt
    )
    $fechaIso = if ($fechaOk) { $fechaDt.ToString('yyyy-MM-dd', $inv) } else { "INVALIDA:$($r.date)" }
    [PSCustomObject]@{
        LineaCsv       = $indice
        DateRaw        = $r.date
        FechaOk        = $fechaOk
        FechaDt        = if ($fechaOk) { $fechaDt } else { $null }
        FechaIso       = $fechaIso
        QuarterRaw     = $r.quarter
        DeptRaw        = $r.department
        DeptTrimLower  = $deptTrimLower
        DeptLimpio     = $deptLimpio
        DayRaw         = $r.day
        TeamRaw        = $r.team
        ClaveTrimLower = "$fechaIso|$deptTrimLower|$($r.team.Trim())"
        ClaveLimpia    = "$fechaIso|$deptLimpio|$($r.team.Trim())"
        Row            = $r
    }
}

$colisionesLimpia = @($registros | Group-Object -Property ClaveLimpia | Where-Object { $_.Count -gt 1 } | Sort-Object -Property @{Expression='Count';Descending=$true}, @{Expression='Name';Descending=$false})
$colisionesTrimLower = @($registros | Group-Object -Property ClaveTrimLower | Where-Object { $_.Count -gt 1 } | Sort-Object -Property @{Expression='Count';Descending=$true}, @{Expression='Name';Descending=$false})

$filasEnColisionLimpia = if ($colisionesLimpia.Count -gt 0) {
    ($colisionesLimpia | Measure-Object -Property Count -Sum).Sum
} else { 0 }

Write-Output ("Combinaciones únicas (date + dept trim/lower + team)                : {0}" -f (@($registros | Select-Object -ExpandProperty ClaveTrimLower -Unique).Count))
Write-Output ("Claves con colisión (date + dept trim/lower + team)                 : {0}" -f $colisionesTrimLower.Count)
Write-Output ("Combinaciones únicas (date + dept limpio [sweing->sewing] + team)   : {0}" -f (@($registros | Select-Object -ExpandProperty ClaveLimpia -Unique).Count))
Write-Output ("Claves con colisión (date + dept limpio [sweing->sewing] + team)    : {0}" -f $colisionesLimpia.Count)
Write-Output ("Total de filas involucradas en colisiones (clave limpia)            : {0}" -f $filasEnColisionLimpia)

if ($colisionesLimpia.Count -gt 0) {
    Write-Output ""
    Write-Output "Ejemplos de colisiones en (date + department limpio + team) [hasta 5 grupos]:"
    foreach ($g in ($colisionesLimpia | Select-Object -First 5)) {
        Write-Output ("  Clave: {0}  (repeticiones: {1})" -f $g.Name, $g.Count)
        foreach ($item in $g.Group) {
            $rw = $item.Row
            Write-Output ("    Línea {0}: date={1} | quarter={2} | dept=[{3}] | team={4} | smv={5} | wip=[{6}] | over_time={7} | incentive={8} | workers={9} | target={10} | actual={11}" -f `
                $item.LineaCsv, $rw.date, $rw.quarter, $rw.department, $rw.team, $rw.smv, $rw.wip, $rw.over_time, $rw.incentive, $rw.no_of_workers, $rw.targeted_productivity, $rw.actual_productivity)
        }
    }
}

# ------------------------------------------------------------------------------
# 3. Conteo de nulos/vacíos por columna y cruce de nulos de wip por department
# ------------------------------------------------------------------------------
Write-Output ""
Write-Output "3. NULOS / VACIOS POR COLUMNA (15 COLUMNAS)"
Write-Output "------------------------------------------------------------------------------"
$tablaNulos = foreach ($col in $columnas) {
    $nulos = 0
    foreach ($r in $filas) {
        if ([string]::IsNullOrWhiteSpace([string]$r.$col)) {
            $nulos++
        }
    }
    $pct = ($nulos / $filas.Count) * 100.0
    [PSCustomObject]@{
        Columna   = $col
        Nulos     = $nulos
        NoNulos   = $filas.Count - $nulos
        PctNulos  = ("{0:N2}%" -f $pct)
    }
}
$tablaNulos | Format-Table -AutoSize | Out-String | ForEach-Object { $_.TrimEnd() }

Write-Output ""
Write-Output "Cruce de nulos de 'wip' por valor CRUDO de 'department':"
$cruceWipRaw = $registros | Group-Object -Property DeptRaw | Sort-Object -Property Name | ForEach-Object {
    $total = $_.Count
    $wipNulos = @($_.Group | Where-Object { [string]::IsNullOrWhiteSpace([string]$_.Row.wip) }).Count
    $wipNoNulos = $total - $wipNulos
    [PSCustomObject]@{
        DepartmentCrudo = "[$($_.Name)]"
        TotalFilas      = $total
        WipNulos        = $wipNulos
        WipConDato      = $wipNoNulos
        PctWipNulo      = ("{0:N2}%" -f (($wipNulos / $total) * 100.0))
    }
}
$cruceWipRaw | Format-Table -AutoSize | Out-String | ForEach-Object { $_.TrimEnd() }

Write-Output ""
Write-Output "Cruce de nulos de 'wip' por valor LIMPIO de 'department':"
$cruceWipLimpio = $registros | Group-Object -Property DeptLimpio | Sort-Object -Property Name | ForEach-Object {
    $total = $_.Count
    $wipNulos = @($_.Group | Where-Object { [string]::IsNullOrWhiteSpace([string]$_.Row.wip) }).Count
    $wipNoNulos = $total - $wipNulos
    [PSCustomObject]@{
        DepartmentLimpio = "[$($_.Name)]"
        TotalFilas       = $total
        WipNulos         = $wipNulos
        WipConDato       = $wipNoNulos
        PctWipNulo       = ("{0:N2}%" -f (($wipNulos / $total) * 100.0))
    }
}
$cruceWipLimpio | Format-Table -AutoSize | Out-String | ForEach-Object { $_.TrimEnd() }

# ------------------------------------------------------------------------------
# 4. Valores distintos y frecuencias de columnas categóricas
# ------------------------------------------------------------------------------
Write-Output ""
Write-Output "4. FRECUENCIAS DE COLUMNAS CATEGORICAS (entre corchetes para exponer espacios)"
Write-Output "------------------------------------------------------------------------------"

foreach ($catCol in @('quarter', 'department', 'day')) {
    Write-Output ""
    Write-Output ("Columna: {0}" -f $catCol)
    $freq = $filas | Group-Object -Property $catCol | Sort-Object -Property @{Expression='Count';Descending=$true}, @{Expression='Name';Descending=$false} | ForEach-Object {
        [PSCustomObject]@{
            ValorCrudo = "[$($_.Name)]"
            Longitud   = $_.Name.Length
            Frecuencia = $_.Count
            PctTotal   = ("{0:N2}%" -f (($_.Count / $filas.Count) * 100.0))
        }
    }
    $freq | Format-Table -AutoSize | Out-String | ForEach-Object { $_.TrimEnd() }
}

Write-Output ""
Write-Output "Columna: team (ordenada numéricamente)"
$freqTeam = $registros | Group-Object -Property TeamRaw | Sort-Object -Property { [int]$_.Name } | ForEach-Object {
    $fechasTeam = $_.Group | Where-Object { $_.FechaOk } | Sort-Object -Property FechaDt
    [PSCustomObject]@{
        TeamCrudo  = "[$($_.Name)]"
        Frecuencia = $_.Count
        PctTotal   = ("{0:N2}%" -f (($_.Count / $filas.Count) * 100.0))
        FechaMin   = ($fechasTeam | Select-Object -First 1).FechaIso
        FechaMax   = ($fechasTeam | Select-Object -Last 1).FechaIso
    }
}
$freqTeam | Format-Table -AutoSize | Out-String | ForEach-Object { $_.TrimEnd() }

# ------------------------------------------------------------------------------
# 5. Auditoría de fechas y consistencia con 'day'
# ------------------------------------------------------------------------------
Write-Output ""
Write-Output "5. AUDITORIA DE FECHAS Y CONSISTENCIA CON 'day'"
Write-Output "------------------------------------------------------------------------------"
$fechasValidas = @($registros | Where-Object { $_.FechaOk })
$fechasInvalidas = @($registros | Where-Object { -not $_.FechaOk })
$formatoRegexNoCoincide = @($registros | Where-Object { $_.DateRaw -notmatch '^\d{1,2}/\d{1,2}/\d{4}$' })
$fechasUnicas = @($fechasValidas | Select-Object -ExpandProperty FechaIso -Unique | Sort-Object)

$fechaMin = ($fechasValidas | Sort-Object -Property FechaDt | Select-Object -First 1)
$fechaMax = ($fechasValidas | Sort-Object -Property FechaDt | Select-Object -Last 1)

$discrepanciasDay = @($fechasValidas | Where-Object {
    $_.FechaDt.DayOfWeek.ToString() -ne $_.DayRaw.Trim()
})

Write-Output ("Registros con fecha válida en M/d/yyyy           : {0}" -f $fechasValidas.Count)
Write-Output ("Registros que NO parsean como M/d/yyyy           : {0}" -f $fechasInvalidas.Count)
Write-Output ("Registros que NO cumplen patrón ^\d{{1,2}}/\d{{1,2}}/\d{{4}}$ : {0}" -f $formatoRegexNoCoincide.Count)
Write-Output ("Fecha mínima                                     : {0} (crudo: {1})" -f $fechaMin.FechaIso, $fechaMin.DateRaw)
Write-Output ("Fecha máxima                                     : {0} (crudo: {1})" -f $fechaMax.FechaIso, $fechaMax.DateRaw)
Write-Output ("Fechas únicas                                    : {0}" -f $fechasUnicas.Count)
Write-Output ("Discrepancias entre 'day' y día real de 'date'   : {0}" -f $discrepanciasDay.Count)

if ($fechasInvalidas.Count -gt 0) {
    Write-Output "Ejemplos de fechas inválidas:"
    $fechasInvalidas | Select-Object -First 10 | ForEach-Object {
        Write-Output ("  Línea {0}: date=[{1}]" -f $_.LineaCsv, $_.DateRaw)
    }
}
if ($discrepanciasDay.Count -gt 0) {
    Write-Output "Ejemplos de discrepancias en 'day':"
    $discrepanciasDay | Select-Object -First 10 | ForEach-Object {
        Write-Output ("  Línea {0}: date={1} ({2}) vs day=[{3}]" -f $_.LineaCsv, $_.DateRaw, $_.FechaDt.DayOfWeek.ToString(), $_.DayRaw)
    }
}

# ------------------------------------------------------------------------------
# 6. Estadísticas básicas de columnas numéricas
# ------------------------------------------------------------------------------
Write-Output ""
Write-Output "6. ESTADISTICAS BASICAS DE COLUMNAS NUMERICAS"
Write-Output "------------------------------------------------------------------------------"
$colsNumericas = @(
    'targeted_productivity',
    'smv',
    'wip',
    'over_time',
    'incentive',
    'idle_time',
    'idle_men',
    'no_of_style_change',
    'no_of_workers',
    'actual_productivity'
)

$tablaStats = foreach ($col in $colsNumericas) {
    $valores = New-Object System.Collections.Generic.List[double]
    $noNumericos = 0
    $ceros = 0
    $mayoresCero = 0
    $negativos = 0
    $noEnteros = 0

    foreach ($r in $filas) {
        $txt = [string]$r.$col
        if ([string]::IsNullOrWhiteSpace($txt)) { continue }
        $num = 0.0
        if ([double]::TryParse($txt.Trim(), [System.Globalization.NumberStyles]::Float, $inv, [ref]$num)) {
            $valores.Add($num)
            if ($num -eq 0.0) { $ceros++ }
            elseif ($num -gt 0.0) { $mayoresCero++ }
            else { $negativos++ }
            if ([math]::Floor($num) -ne $num) { $noEnteros++ }
        } else {
            $noNumericos++
        }
    }

    $m = $valores | Measure-Object -Minimum -Maximum -Average
    [PSCustomObject]@{
        Columna     = $col
        NoNulos     = $valores.Count
        NoNum       = $noNumericos
        Min         = Format-Num $m.Minimum 4
        Max         = Format-Num $m.Maximum 4
        Promedio    = Format-Num $m.Average 4
        Ceros       = $ceros
        Mayores0    = $mayoresCero
        Negativos   = $negativos
        ConDecimal  = $noEnteros
    }
}
$tablaStats | Format-Table -AutoSize | Out-String | ForEach-Object { $_.TrimEnd() }

# ------------------------------------------------------------------------------
# 7. Casos especiales: actual_productivity > 1 y eventos de tiempo muerto
# ------------------------------------------------------------------------------
Write-Output ""
Write-Output "7. CASOS ESPECIALES: PRODUCTIVIDAD > 1 Y TIEMPO MUERTO"
Write-Output "------------------------------------------------------------------------------"

$prodMayor1 = @()
$maxProd = [double]::MinValue
$idleTimePos = 0
$idleMenPos = 0
$idleCualquiera = 0
$idleAmbos = 0
$soloIdleTime = 0
$soloIdleMen = 0

foreach ($item in $registros) {
    $rw = $item.Row
    $ap = [double]::Parse($rw.actual_productivity.Trim(), $inv)
    $it = [double]::Parse($rw.idle_time.Trim(), $inv)
    $im = [double]::Parse($rw.idle_men.Trim(), $inv)

    if ($ap -gt $maxProd) { $maxProd = $ap }
    if ($ap -gt 1.0) { $prodMayor1 += $item }

    $tieneIt = ($it -gt 0.0)
    $tieneIm = ($im -gt 0.0)
    if ($tieneIt) { $idleTimePos++ }
    if ($tieneIm) { $idleMenPos++ }
    if ($tieneIt -or $tieneIm) { $idleCualquiera++ }
    if ($tieneIt -and $tieneIm) { $idleAmbos++ }
    if ($tieneIt -and -not $tieneIm) { $soloIdleTime++ }
    if (-not $tieneIt -and $tieneIm) { $soloIdleMen++ }
}

Write-Output ("Registros con actual_productivity > 1           : {0} ({1:N2}% del total)" -f $prodMayor1.Count, (($prodMayor1.Count / $filas.Count) * 100.0))
Write-Output ("Valor máximo de actual_productivity             : {0}" -f (Format-Num $maxProd 6))
Write-Output ("Registros con idle_time > 0                     : {0} ({1:N2}% del total)" -f $idleTimePos, (($idleTimePos / $filas.Count) * 100.0))
Write-Output ("Registros con idle_men > 0                      : {0} ({1:N2}% del total)" -f $idleMenPos, (($idleMenPos / $filas.Count) * 100.0))
Write-Output ("Registros con idle_time > 0 O idle_men > 0      : {0} ({1:N2}% del total)" -f $idleCualquiera, (($idleCualquiera / $filas.Count) * 100.0))
Write-Output ("  - Ambos > 0 (idle_time > 0 Y idle_men > 0)    : {0}" -f $idleAmbos)
Write-Output ("  - Solo idle_time > 0 (idle_men = 0)           : {0}" -f $soloIdleTime)
Write-Output ("  - Solo idle_men > 0 (idle_time = 0)           : {0}" -f $soloIdleMen)
Write-Output ""
Write-Output "=============================================================================="
Write-Output "FIN DEL PERFILADO"
Write-Output "=============================================================================="
