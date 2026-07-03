<#
.SYNOPSIS
  Generador de proyectos Spring Boot (WebFlux + R2DBC) + Docker + Kubernetes
  basado en la estructura de https://github.com/AndreHermoza/k8s-template

.DESCRIPTION
  Pregunta el nombre del proyecto y las entidades (con sus campos) y crea
  TODA la carpeta: modelo, repositorio, servicio, controlador REST, schema.sql,
  Dockerfile, docker-compose.yml y manifiestos de k8s para cada entidad.

.USAGE
  .\generar-proyecto.ps1
  (si Windows bloquea la ejecución de scripts, corre primero:
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass)
#>

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

# Escribe archivos en UTF-8 SIN BOM (Set-Content -Encoding UTF8 en
# Windows PowerShell 5.1 agrega BOM, lo que rompe la compilacion de
# Java con "illegal character: '\ufeff'").
function Set-Utf8NoBom([string]$Path, [string]$Value) {
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path -Path (Get-Location).Path -ChildPath $Path
    }
    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Value, $Utf8NoBom)
}

function Cap([string]$w) {
    if ([string]::IsNullOrEmpty($w)) { return $w }
    return $w.Substring(0,1).ToUpper() + $w.Substring(1)
}

function LowFirst([string]$w) {
    if ([string]::IsNullOrEmpty($w)) { return $w }
    return $w.Substring(0,1).ToLower() + $w.Substring(1)
}

# Palabras reservadas de Java + nombres que el generador ya usa internamente
# (id, status, createdAt, updatedAt se agregan automaticamente a cada entidad).
$JavaReserved = @(
    'abstract','assert','boolean','break','byte','case','catch','char','class','const',
    'continue','default','do','double','else','enum','extends','final','finally','float',
    'for','goto','if','implements','import','instanceof','int','interface','long','native',
    'new','package','private','protected','public','return','short','static','strictfp',
    'super','switch','synchronized','this','throw','throws','transient','try','void',
    'volatile','while','var','record','yield','true','false','null'
)
$AutoFields = @('id','status','createdat','updatedat')

function Test-ValidIdentifier([string]$name) {
    # Letras/numeros, debe empezar con letra, sin espacios ni simbolos
    return ($name -match '^[A-Za-z][A-Za-z0-9]*$')
}

function Pluralize([string]$w) {
    $wLower = $w.ToLower()
    
    # Si ya termina en 's', no agregar nada
    if ($wLower.EndsWith('s')) {
        return $w
    }
    
    $vowels = @('a','e','i','o','u')
    $last = $w.Substring($w.Length - 1, 1).ToLower()
    
    # Terminaciones especiales
    if ($last -eq 'y' -and $w.Length -gt 1) {
        $beforeLast = $w.Substring($w.Length - 2, 1).ToLower()
        if (-not ($vowels -contains $beforeLast)) {
            # Consonante + y -> ies (country -> countries)
            return $w.Substring(0, $w.Length - 1) + "ies"
        }
    }
    
    if ($last -eq 'z') {
        return $w.Substring(0, $w.Length - 1) + "ces"
    } elseif ($vowels -contains $last) {
        return "${w}s"
    } else {
        return "${w}es"
    }
}

function CamelToSnake([string]$str) {
    $result = ""
    for ($i = 0; $i -lt $str.Length; $i++) {
        $char = $str[$i]
        if ([char]::IsUpper($char) -and $i -gt 0) {
            $result += "_" + $char.ToString().ToLower()
        } else {
            $result += $char.ToString().ToLower()
        }
    }
    return $result
}

function MapType([string]$t) {
    switch ($t) {
        "string"    { return @{ Java = "String";         Sql = "VARCHAR(100)" } }
        "texto"     { return @{ Java = "String";         Sql = "VARCHAR(255)" } }
        "textoLargo" { return @{ Java = "String";        Sql = "TEXT" } }
        "decimal"   { return @{ Java = "BigDecimal";     Sql = "DECIMAL(10,2)" } }
        "int"       { return @{ Java = "Integer";        Sql = "INT" } }
        "long"      { return @{ Java = "Long";           Sql = "BIGINT" } }
        "boolean"   { return @{ Java = "Boolean";        Sql = "BOOLEAN" } }
        "fecha"     { return @{ Java = "LocalDate";      Sql = "DATE" } }
        "fechahora" { return @{ Java = "LocalDateTime";  Sql = "TIMESTAMP" } }
        "timestamp" { return @{ Java = "LocalDateTime";  Sql = "TIMESTAMP" } }
        default     { return @{ Java = "String";         Sql = "VARCHAR(100)" } }
    }
}

# Reemplaza tokens {{TOKEN}} dentro de una plantilla (string de una sola comilla, sin interpolación)
function Fill([string]$template, [hashtable]$map) {
    $out = $template
    foreach ($key in $map.Keys) {
        $out = $out.Replace("{{$key}}", [string]$map[$key])
    }
    return $out
}

Clear-Host
Write-Host @"

================================================================
 Generador de proyecto Spring Boot + Docker + Kubernetes
================================================================

"@ -ForegroundColor Cyan

# ------------------------------------------------------------------
# 1. Datos generales del proyecto
# ------------------------------------------------------------------

Write-Host "=== CONFIGURACION DEL PROYECTO ===" -ForegroundColor Cyan
Write-Host ""

$ProjectName = Read-Host "Nombre del proyecto (kebab-case, ej: tienda-api)"
if ([string]::IsNullOrWhiteSpace($ProjectName)) { $ProjectName = "mi-proyecto" }
while ($ProjectName -notmatch '^[a-z][a-z0-9]*(-[a-z0-9]+)*$') {
    Write-Host "  Nombre invalido. Usa minusculas, numeros y guiones (ej: tienda-api)."
    $ProjectName = Read-Host "Nombre del proyecto (kebab-case, ej: tienda-api)"
    if ([string]::IsNullOrWhiteSpace($ProjectName)) { $ProjectName = "mi-proyecto" }
}

$BasePackage = Read-Host "Paquete base Java (default: pe.edu.vallegrande)"
if ([string]::IsNullOrWhiteSpace($BasePackage)) { $BasePackage = "pe.edu.vallegrande" }
while ($BasePackage -notmatch '^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)*$') {
    Write-Host "  Paquete invalido. Usa minusculas separadas por puntos (ej: com.empresa.proyecto)."
    $BasePackage = Read-Host "Paquete base Java (default: pe.edu.vallegrande)"
    if ([string]::IsNullOrWhiteSpace($BasePackage)) { $BasePackage = "pe.edu.vallegrande" }
}

$ArtifactPkg = ($ProjectName -replace '-', '').ToLower()
$FullPackage = "$BasePackage.$ArtifactPkg"
$PackagePath = $FullPackage.Replace('.', '/')

$AppPort = Read-Host "Puerto de la API (default: 8080)"
if ([string]::IsNullOrWhiteSpace($AppPort)) { $AppPort = "8080" }
while ($AppPort -notmatch '^\d+$' -or [int]$AppPort -lt 1 -or [int]$AppPort -gt 65535) {
    Write-Host "  Puerto invalido. Escribe un numero entre 1 y 65535."
    $AppPort = Read-Host "Puerto de la API (default: 8080)"
    if ([string]::IsNullOrWhiteSpace($AppPort)) { $AppPort = "8080" }
}

Write-Host ""
Write-Host "=== CONFIGURACION DE BASE DE DATOS ===" -ForegroundColor Cyan
Write-Host "Opciones:"
Write-Host "  1. Neon PostgreSQL (Produccion/Cloud)"
Write-Host "  2. PostgreSQL Local (Docker Compose)"
Write-Host "  3. H2 en memoria (Desarrollo/Testing)"
Write-Host ""
$DbChoice = Read-Host "Selecciona opcion (1, 2, o 3)"
if ([string]::IsNullOrWhiteSpace($DbChoice)) { $DbChoice = "1" }

$NeonUrl = ""
$NeonUser = ""
$NeonPassword = ""
$NeonDbName = ""

if ($DbChoice -eq "1") {
    Write-Host ""
    Write-Host "Ingresa los datos de tu base de datos Neon PostgreSQL:" -ForegroundColor Yellow
    $NeonUrl = Read-Host "  URL de conexion Neon (ej: ep-xxx.us-east-1.aws.neon.tech)"
    $NeonDbName = Read-Host "  Nombre de la base de datos (default: $ArtifactPkg)"
    if ([string]::IsNullOrWhiteSpace($NeonDbName)) { $NeonDbName = $ArtifactPkg }
    $NeonUser = Read-Host "  Usuario"
    $NeonPassword = Read-Host "  Password" -AsSecureString
    $NeonPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NeonPassword)
    )
}

$K8sNs = Read-Host "Namespace de Kubernetes (default: $ArtifactPkg)"
if ([string]::IsNullOrWhiteSpace($K8sNs)) { $K8sNs = $ArtifactPkg }

$DockerUser = Read-Host "Usuario/organizacion de Docker Hub (default: miusuario)"
if ([string]::IsNullOrWhiteSpace($DockerUser)) { $DockerUser = "miusuario" }

Write-Host ""
Write-Host "=== OPCIONES AVANZADAS ===" -ForegroundColor Cyan
$IncludeCors = (Read-Host "Habilitar CORS en controladores? (S/n)").ToLower()
if ([string]::IsNullOrWhiteSpace($IncludeCors) -or $IncludeCors -eq "s") { $IncludeCors = $true } else { $IncludeCors = $false }

$IncludeSampleData = (Read-Host "Generar datos de prueba en schema.sql? (S/n)").ToLower()
if ([string]::IsNullOrWhiteSpace($IncludeSampleData) -or $IncludeSampleData -eq "s") { $IncludeSampleData = $true } else { $IncludeSampleData = $false }

Write-Host ""
Write-Host "Docker image: $DockerUser/${ProjectName}:1.0"
Write-Host ""

# ------------------------------------------------------------------
# 2. Entidades y campos
# ------------------------------------------------------------------

$EntityNames = New-Object System.Collections.ArrayList
$EntityFields = New-Object System.Collections.ArrayList   # "campo1:tipo1,campo2:tipo2"

Write-Host "Tipos de campo disponibles: string, texto, textoLargo, decimal, int, long, boolean, fecha, fechahora, timestamp"
Write-Host "(Cada entidad ya incluye automaticamente: id, status, createdAt, updatedAt)"
Write-Host ""

while ($true) {
    $Entity = Read-Host "Nombre de entidad (PascalCase, ej: Usuario) [enter para terminar]"
    if ([string]::IsNullOrWhiteSpace($Entity)) {
        if ($EntityNames.Count -eq 0) {
            Write-Host "Debes crear al menos una entidad."
            continue
        }
        break
    }
    $Entity = Cap $Entity.Trim()

    if (-not (Test-ValidIdentifier $Entity)) {
        Write-Host "  Nombre invalido: solo letras y numeros, sin espacios ni simbolos. Intenta de nuevo."
        continue
    }
    if ($JavaReserved -contains $Entity.ToLower()) {
        Write-Host "  '$Entity' es una palabra reservada de Java. Usa otro nombre."
        continue
    }
    if ($EntityNames -contains $Entity) {
        Write-Host "  La entidad '$Entity' ya fue agregada. Usa otro nombre o termina con enter vacio."
        continue
    }

    $Fields = ""
    $FieldNamesSeen = New-Object System.Collections.ArrayList
    Write-Host "  Campos de $Entity (formato nombre:tipo, ej: nombre:string). Enter vacio para terminar."
    while ($true) {
        $Field = Read-Host "    Campo"
        if ([string]::IsNullOrWhiteSpace($Field)) {
            if ([string]::IsNullOrWhiteSpace($Fields)) {
                Write-Host "    La entidad debe tener al menos un campo."
                continue
            }
            break
        }

        $Field = $Field.Trim()
        $parts = $Field -split ':'
        if ($parts.Count -ne 2 -or [string]::IsNullOrWhiteSpace($parts[0]) -or [string]::IsNullOrWhiteSpace($parts[1])) {
            Write-Host "    Formato invalido. Usa nombre:tipo (ej: nombre:string)."
            continue
        }

        $FName = LowFirst ($parts[0].Trim())
        $FType = $parts[1].Trim().ToLower()

        if (-not (Test-ValidIdentifier $FName)) {
            Write-Host "    Nombre de campo invalido: solo letras y numeros, sin espacios ni simbolos."
            continue
        }
        if ($JavaReserved -contains $FName.ToLower()) {
            Write-Host "    '$FName' es una palabra reservada de Java. Usa otro nombre de campo."
            continue
        }
        if ($AutoFields -contains $FName.ToLower()) {
            Write-Host "    '$FName' ya se agrega automaticamente a cada entidad (id, estado, fechaRegistro). Usa otro nombre."
            continue
        }
        if ($FieldNamesSeen -contains $FName.ToLower()) {
            Write-Host "    El campo '$FName' ya fue agregado en esta entidad."
            continue
        }
        $ValidTypes = @('string','texto','textolargo','decimal','int','long','boolean','fecha','fechahora','timestamp')
        if ($ValidTypes -notcontains $FType) {
            Write-Host "    Tipo '$FType' no reconocido, se usara 'string' por defecto. Tipos validos: $($ValidTypes -join ', ')"
        }

        [void]$FieldNamesSeen.Add($FName.ToLower())

        if ([string]::IsNullOrWhiteSpace($Fields)) {
            $Fields = "${FName}:${FType}"
        } else {
            $Fields = "$Fields,${FName}:${FType}"
        }
    }

    [void]$EntityNames.Add($Entity)
    [void]$EntityFields.Add($Fields)
    Write-Host "  -> Entidad '$Entity' agregada con campos: $Fields"
    Write-Host ""
}

# ------------------------------------------------------------------
# 3. Crear estructura de carpetas
# ------------------------------------------------------------------

$Root = ".\$ProjectName"
if (Test-Path $Root) {
    Write-Host "El directorio '$Root' ya existe. Elige otro nombre o eliminalo primero."
    exit 1
}

$JavaSrc = "$Root/src/main/java/$PackagePath"
$ResSrc  = "$Root/src/main/resources"

New-Item -ItemType Directory -Force -Path "$JavaSrc/model"            | Out-Null
New-Item -ItemType Directory -Force -Path "$JavaSrc/repository"       | Out-Null
New-Item -ItemType Directory -Force -Path "$JavaSrc/service/impl"     | Out-Null
New-Item -ItemType Directory -Force -Path "$JavaSrc/rest"             | Out-Null
New-Item -ItemType Directory -Force -Path "$ResSrc"                   | Out-Null
New-Item -ItemType Directory -Force -Path "$Root/k8s"                 | Out-Null
New-Item -ItemType Directory -Force -Path "$Root/src/test/java/$PackagePath" | Out-Null

Write-Host ""
Write-Host "Generando proyecto en $Root ..."

# ------------------------------------------------------------------
# 4. Application class
# ------------------------------------------------------------------

$AppClass = (Cap $ArtifactPkg) + "Application"

$AppClassTemplate = @'
package {{FULL_PACKAGE}};

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class {{APP_CLASS}} {

    public static void main(String[] args) {
        SpringApplication.run({{APP_CLASS}}.class, args);
    }
}
'@

Set-Utf8NoBom -Path "$JavaSrc/${AppClass}.java" -Value (Fill $AppClassTemplate @{
    FULL_PACKAGE = $FullPackage
    APP_CLASS    = $AppClass
})

# ------------------------------------------------------------------
# 5. Generar codigo por cada entidad
# ------------------------------------------------------------------

$SchemaContent = ""

for ($i = 0; $i -lt $EntityNames.Count; $i++) {
    $Entity = $EntityNames[$i]
    $FieldsRaw = $EntityFields[$i]

    $EntityLower  = LowFirst $Entity
    $EntityTable  = $EntityLower.ToUpper()
    $EntityPlural = Pluralize $EntityLower
    $Repo         = "${Entity}Repository"
    $Service      = "${Entity}Service"
    $ServiceImpl  = "${Entity}ServiceImpl"
    $Rest         = "${Entity}Rest"

    $FieldPairs = $FieldsRaw -split ','

    $NeedsBigDecimal = $false
    $NeedsLocalDate = $false

    $ModelFieldsLines  = New-Object System.Collections.ArrayList
    $SettersLines      = New-Object System.Collections.ArrayList
    $SqlColumnsLines   = New-Object System.Collections.ArrayList

    foreach ($pair in $FieldPairs) {
        $parts = $pair -split ':'
        $fname = $parts[0]
        $ftype = $parts[1]
        $mapping = MapType $ftype
        $JType = $mapping.Java
        $SqlType = $mapping.Sql

        if ($JType -eq "BigDecimal") { $NeedsBigDecimal = $true }
        if ($JType -eq "LocalDate")  { $NeedsLocalDate = $true }

        [void]$ModelFieldsLines.Add("    private $JType $fname;")

        $FCap = Cap $fname
        [void]$SettersLines.Add("                    actual.set$FCap(${EntityLower}.get$FCap());")

        $ColName = $fname.ToUpper()
        [void]$SqlColumnsLines.Add("    `"$ColName`" $SqlType NOT NULL,")
    }

    $ModelFields = ($ModelFieldsLines -join "`n")
    $SettersUpdate = ($SettersLines -join "`n")
    $SqlColumns = ($SqlColumnsLines -join "`n")

    $Imports = ""
    if ($NeedsBigDecimal) { $Imports += "import java.math.BigDecimal;`n" }
    if ($NeedsLocalDate)  { $Imports += "import java.time.LocalDate;`n" }
    $Imports += "import java.time.LocalDateTime;`n"

    # -------- model/Entity.java --------
    $ModelTemplate = @'
package {{FULL_PACKAGE}}.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;

{{IMPORTS}}
@Data
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "{{ENTITY_TABLE}}")
public class {{ENTITY}} {

    @Id
    private Long id;

{{MODEL_FIELDS}}

    private String status;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}
'@
    Set-Utf8NoBom -Path "$JavaSrc/model/${Entity}.java" -Value (Fill $ModelTemplate @{
        FULL_PACKAGE  = $FullPackage
        IMPORTS       = $Imports
        ENTITY_TABLE  = $EntityTable
        ENTITY        = $Entity
        MODEL_FIELDS  = $ModelFields
    })

    # -------- repository --------
    $RepoTemplate = @'
package {{FULL_PACKAGE}}.repository;

import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import {{FULL_PACKAGE}}.model.{{ENTITY}};
import reactor.core.publisher.Flux;

@Repository
public interface {{REPO}} extends ReactiveCrudRepository<{{ENTITY}}, Long> {

    Flux<{{ENTITY}}> findByStatus(String status);
}
'@
    Set-Utf8NoBom -Path "$JavaSrc/repository/${Repo}.java" -Value (Fill $RepoTemplate @{
        FULL_PACKAGE = $FullPackage
        ENTITY       = $Entity
        REPO         = $Repo
    })

    # -------- service (interface) --------
    $ServiceTemplate = @'
package {{FULL_PACKAGE}}.service;

import {{FULL_PACKAGE}}.model.{{ENTITY}};
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface {{SERVICE}} {

    Flux<{{ENTITY}}> getAll{{ENTITY}}s();

    Mono<{{ENTITY}}> get{{ENTITY}}ById(Long id);

    Flux<{{ENTITY}}> get{{ENTITY}}sByStatus(String status);

    Mono<{{ENTITY}}> create{{ENTITY}}({{ENTITY}} {{ENTITY_LOWER}});

    Mono<{{ENTITY}}> update{{ENTITY}}(Long id, {{ENTITY}} {{ENTITY_LOWER}});

    Mono<Void> delete{{ENTITY}}(Long id);

    Mono<{{ENTITY}}> activate{{ENTITY}}(Long id);

    Mono<{{ENTITY}}> deactivate{{ENTITY}}(Long id);

    Mono<{{ENTITY}}> suspend{{ENTITY}}(Long id);
}
'@
    Set-Utf8NoBom -Path "$JavaSrc/service/${Service}.java" -Value (Fill $ServiceTemplate @{
        FULL_PACKAGE  = $FullPackage
        ENTITY        = $Entity
        SERVICE       = $Service
        ENTITY_LOWER  = $EntityLower
    })

    # -------- service/impl --------
    $ServiceImplTemplate = @'
package {{FULL_PACKAGE}}.service.impl;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import {{FULL_PACKAGE}}.model.{{ENTITY}};
import {{FULL_PACKAGE}}.repository.{{REPO}};
import {{FULL_PACKAGE}}.service.{{SERVICE}};
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class {{SERVICE_IMPL}} implements {{SERVICE}} {

    private final {{REPO}} {{ENTITY_LOWER}}Repository;

    @Override
    public Flux<{{ENTITY}}> getAll{{ENTITY}}s() {
        return {{ENTITY_LOWER}}Repository.findAll();
    }

    @Override
    public Mono<{{ENTITY}}> get{{ENTITY}}ById(Long id) {
        return {{ENTITY_LOWER}}Repository.findById(id);
    }

    @Override
    public Flux<{{ENTITY}}> get{{ENTITY}}sByStatus(String status) {
        return {{ENTITY_LOWER}}Repository.findByStatus(status);
    }

    @Override
    public Mono<{{ENTITY}}> create{{ENTITY}}({{ENTITY}} {{ENTITY_LOWER}}) {
        {{ENTITY_LOWER}}.setCreatedAt(LocalDateTime.now());
        {{ENTITY_LOWER}}.setUpdatedAt(LocalDateTime.now());
        if ({{ENTITY_LOWER}}.getStatus() == null || {{ENTITY_LOWER}}.getStatus().isEmpty()) {
            {{ENTITY_LOWER}}.setStatus("ACTIVE");
        }
        return {{ENTITY_LOWER}}Repository.save({{ENTITY_LOWER}});
    }

    @Override
    public Mono<{{ENTITY}}> update{{ENTITY}}(Long id, {{ENTITY}} {{ENTITY_LOWER}}) {
        return {{ENTITY_LOWER}}Repository.findById(id)
                .flatMap(existingEntity -> {
{{SETTERS_UPDATE}}
                    if ({{ENTITY_LOWER}}.getStatus() != null) {
                        existingEntity.setStatus({{ENTITY_LOWER}}.getStatus());
                    }
                    existingEntity.setUpdatedAt(LocalDateTime.now());
                    return {{ENTITY_LOWER}}Repository.save(existingEntity);
                });
    }

    @Override
    public Mono<Void> delete{{ENTITY}}(Long id) {
        return {{ENTITY_LOWER}}Repository.deleteById(id);
    }

    @Override
    public Mono<{{ENTITY}}> activate{{ENTITY}}(Long id) {
        return {{ENTITY_LOWER}}Repository.findById(id)
                .flatMap({{ENTITY_LOWER}} -> {
                    {{ENTITY_LOWER}}.setStatus("ACTIVE");
                    {{ENTITY_LOWER}}.setUpdatedAt(LocalDateTime.now());
                    return {{ENTITY_LOWER}}Repository.save({{ENTITY_LOWER}});
                });
    }

    @Override
    public Mono<{{ENTITY}}> deactivate{{ENTITY}}(Long id) {
        return {{ENTITY_LOWER}}Repository.findById(id)
                .flatMap({{ENTITY_LOWER}} -> {
                    {{ENTITY_LOWER}}.setStatus("INACTIVE");
                    {{ENTITY_LOWER}}.setUpdatedAt(LocalDateTime.now());
                    return {{ENTITY_LOWER}}Repository.save({{ENTITY_LOWER}});
                });
    }

    @Override
    public Mono<{{ENTITY}}> suspend{{ENTITY}}(Long id) {
        return {{ENTITY_LOWER}}Repository.findById(id)
                .flatMap({{ENTITY_LOWER}} -> {
                    {{ENTITY_LOWER}}.setStatus("SUSPENDED");
                    {{ENTITY_LOWER}}.setUpdatedAt(LocalDateTime.now());
                    return {{ENTITY_LOWER}}Repository.save({{ENTITY_LOWER}});
                });
    }
}
'@
    Set-Utf8NoBom -Path "$JavaSrc/service/impl/${ServiceImpl}.java" -Value (Fill $ServiceImplTemplate @{
        FULL_PACKAGE    = $FullPackage
        ENTITY          = $Entity
        REPO            = $Repo
        SERVICE         = $Service
        SERVICE_IMPL    = $ServiceImpl
        ENTITY_LOWER    = $EntityLower
        SETTERS_UPDATE  = $SettersUpdate
    })

    # -------- rest --------
    $CorsAnnotation = if ($IncludeCors) { "@CrossOrigin(origins = `"*`")" } else { "" }
    
    $RestTemplate = @'
package {{FULL_PACKAGE}}.rest;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import {{FULL_PACKAGE}}.model.{{ENTITY}};
import {{FULL_PACKAGE}}.service.{{SERVICE}};
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/{{ENTITY_PLURAL}}")
{{CORS_ANNOTATION}}
@RequiredArgsConstructor
public class {{REST}} {

    private final {{SERVICE}} {{ENTITY_LOWER}}Service;

    @GetMapping
    public Flux<{{ENTITY}}> getAll(@RequestParam(required = false) String status) {
        if (status != null && !status.isEmpty()) {
            return {{ENTITY_LOWER}}Service.get{{ENTITY}}sByStatus(status);
        }
        return {{ENTITY_LOWER}}Service.getAll{{ENTITY}}s();
    }

    @GetMapping("/{id}")
    public Mono<{{ENTITY}}> getById(@PathVariable Long id) {
        return {{ENTITY_LOWER}}Service.get{{ENTITY}}ById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<{{ENTITY}}> create(@RequestBody {{ENTITY}} {{ENTITY_LOWER}}) {
        return {{ENTITY_LOWER}}Service.create{{ENTITY}}({{ENTITY_LOWER}});
    }

    @PutMapping("/{id}")
    public Mono<{{ENTITY}}> update(@PathVariable Long id, @RequestBody {{ENTITY}} {{ENTITY_LOWER}}) {
        return {{ENTITY_LOWER}}Service.update{{ENTITY}}(id, {{ENTITY_LOWER}});
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> delete(@PathVariable Long id) {
        return {{ENTITY_LOWER}}Service.delete{{ENTITY}}(id);
    }

    @PatchMapping("/{id}/activate")
    public Mono<{{ENTITY}}> activate(@PathVariable Long id) {
        return {{ENTITY_LOWER}}Service.activate{{ENTITY}}(id);
    }

    @PatchMapping("/{id}/deactivate")
    public Mono<{{ENTITY}}> deactivate(@PathVariable Long id) {
        return {{ENTITY_LOWER}}Service.deactivate{{ENTITY}}(id);
    }

    @PatchMapping("/{id}/suspend")
    public Mono<{{ENTITY}}> suspend(@PathVariable Long id) {
        return {{ENTITY_LOWER}}Service.suspend{{ENTITY}}(id);
    }
}
'@
    Set-Utf8NoBom -Path "$JavaSrc/rest/${Rest}.java" -Value (Fill $RestTemplate @{
        FULL_PACKAGE   = $FullPackage
        ENTITY         = $Entity
        SERVICE        = $Service
        REST           = $Rest
        ENTITY_LOWER   = $EntityLower
        ENTITY_PLURAL  = $EntityPlural
        CORS_ANNOTATION = $CorsAnnotation
    })

    # -------- schema.sql (acumulado) --------
    $EntitySnake = CamelToSnake $EntityLower
    $SchemaContent += "DROP TABLE IF EXISTS ${EntitySnake}s CASCADE;`n`n"
    $SchemaContent += "CREATE TABLE IF NOT EXISTS ${EntitySnake}s (`n"
    $SchemaContent += "    id SERIAL PRIMARY KEY,`n"
    $SchemaContent += "$SqlColumns`n"
    $SchemaContent += "    status VARCHAR(20) DEFAULT 'ACTIVE',`n"
    $SchemaContent += "    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,`n"
    $SchemaContent += "    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP`n"
    $SchemaContent += ");`n`n"
    
    # Índices
    $SchemaContent += "-- Índice para mejorar búsquedas por status`n"
    $SchemaContent += "CREATE INDEX IF NOT EXISTS idx_${EntitySnake}s_status ON ${EntitySnake}s(status);`n`n"
    
    if ($IncludeSampleData) {
        $SchemaContent += "-- Datos de prueba`n"
        $SchemaContent += "INSERT INTO ${EntitySnake}s (status) VALUES ('ACTIVE')`n"
        $SchemaContent += "ON CONFLICT DO NOTHING;`n`n"
    }

    Write-Host "  -> Codigo generado para entidad: $Entity (/api/$EntityPlural)"
}

Set-Utf8NoBom -Path "$ResSrc/schema.sql" -Value $SchemaContent

# ------------------------------------------------------------------
# 6. application.yaml
# ------------------------------------------------------------------

$R2dbcUrl = ""
$R2dbcUser = ""
$R2dbcPassword = ""
$SqlInitMode = "always"

if ($DbChoice -eq "1") {
    # Neon PostgreSQL
    $R2dbcUrl = "r2dbc:postgresql://${NeonUrl}/${NeonDbName}?sslmode=require"
    $R2dbcUser = $NeonUser
    $R2dbcPassword = $NeonPassword
    $SqlInitMode = "always"
} elseif ($DbChoice -eq "2") {
    # PostgreSQL Local
    $R2dbcUrl = "r2dbc:postgresql://localhost:5432/${ArtifactPkg}"
    $R2dbcUser = $ArtifactPkg
    $R2dbcPassword = $ArtifactPkg
    $SqlInitMode = "always"
} else {
    # H2 en memoria
    $R2dbcUrl = "r2dbc:h2:mem:///testdb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE"
    $R2dbcUser = "sa"
    $R2dbcPassword = "password"
    $SqlInitMode = "always"
}

$AppYamlTemplate = @'
spring:
  application:
    name: {{PROJECT_NAME}}
  r2dbc:
    url: {{R2DBC_URL}}
    username: {{R2DBC_USER}}
    password: {{R2DBC_PASSWORD}}
    pool:
      initial-size: 5
      max-size: 10
      max-idle-time: 30m
  sql:
    init:
      schema-locations: classpath:schema.sql
      mode: {{SQL_INIT_MODE}}

server:
  port: {{APP_PORT}}

logging:
  level:
    io.r2dbc.postgresql: INFO
    org.springframework.r2dbc: INFO
    {{FULL_PACKAGE}}: DEBUG
'@
Set-Utf8NoBom -Path "$ResSrc/application.yaml" -Value (Fill $AppYamlTemplate @{
    APP_PORT        = $AppPort
    PROJECT_NAME    = $ProjectName
    R2DBC_URL       = $R2dbcUrl
    R2DBC_USER      = $R2dbcUser
    R2DBC_PASSWORD  = $R2dbcPassword
    SQL_INIT_MODE   = $SqlInitMode
    FULL_PACKAGE    = $FullPackage
})

# ------------------------------------------------------------------
# 8. Archivos adicionales (.dockerignore, .gitignore, .gitattributes, .env.example, HELP.md)
# ------------------------------------------------------------------

# .dockerignore
$DockerIgnoreContent = @'
target/
!target/*.jar
.mvn/
mvnw
mvnw.cmd
*.log
.git/
.gitignore
*.md
'@
Set-Utf8NoBom -Path "$Root/.dockerignore" -Value $DockerIgnoreContent

# .gitignore
$GitIgnoreContent = @'
HELP.md
target/
.mvn/wrapper/maven-wrapper.jar
!**/src/main/**/target/
!**/src/test/**/target/

### STS ###
.apt_generated
.classpath
.factorypath
.project
.settings
.springBeans
.sts4-cache

### IntelliJ IDEA ###
.idea
*.iws
*.iml
*.ipr

### NetBeans ###
/nbproject/private/
/nbbuild/
/dist/
/nbdist/
/.nb-gradle/
build/
!**/src/main/**/build/
!**/src/test/**/build/

### VS Code ###
.vscode/

### Environment Variables ###
.env
*.env
!.env.example
'@
Set-Utf8NoBom -Path "$Root/.gitignore" -Value $GitIgnoreContent

# .gitattributes
$GitAttributesContent = @'
/mvnw text eol=lf
*.cmd text eol=crlf
'@
Set-Utf8NoBom -Path "$Root/.gitattributes" -Value $GitAttributesContent

# .env.example
$EnvExampleContent = @'
# Ejemplo de configuracion de variables de entorno
# Copia este archivo como .env y reemplaza con tus credenciales reales

# URL completa de R2DBC para PostgreSQL en la nube
# Formato: r2dbc:postgresql://user:password@host:port/database?sslmode=require
DB_URL=r2dbc:postgresql://your-user:your-password@your-host.aws.neon.tech/neondb?sslmode=require

# Usuario de la base de datos (opcional si ya esta en DB_URL)
DB_USER=your-user

# Contrasena de la base de datos (opcional si ya esta en DB_URL)
DB_PASSWORD=your-password

# Puerto del servidor Spring Boot
SERVER_PORT=8080

# Ejemplos de proveedores:
# 
# Neon (Recomendado):
# DB_URL=r2dbc:postgresql://user:pass@ep-something-123.us-east-2.aws.neon.tech/neondb?sslmode=require
#
# Supabase:
# DB_URL=r2dbc:postgresql://postgres:pass@db.something.supabase.co:5432/postgres?sslmode=require
#
# ElephantSQL:
# DB_URL=r2dbc:postgresql://user:pass@suleiman.db.elephantsql.com:5432/database?sslmode=require
'@
Set-Utf8NoBom -Path "$Root/.env.example" -Value $EnvExampleContent

# HELP.md
$HelpMdContent = @"
# Getting Started

### Reference Documentation
For further reference, please consider the following sections:

* [Official Apache Maven documentation](https://maven.apache.org/guides/index.html)
* [Spring Boot Maven Plugin Reference Guide](https://docs.spring.io/spring-boot/maven-plugin)
* [Spring Reactive Web](https://docs.spring.io/spring-boot/reference/web/reactive.html)
* [Spring Data R2DBC](https://docs.spring.io/spring-boot/reference/data/sql.html#data.sql.r2dbc)
* [Docker Compose Support](https://docs.spring.io/spring-boot/reference/features/dev-services.html#features.dev-services.docker-compose)

### Guides
The following guides illustrate how to use some features concretely:

* [Building a Reactive RESTful Web Service](https://spring.io/guides/gs/reactive-rest-service/)
* [Accessing data with R2DBC](https://spring.io/guides/gs/accessing-data-r2dbc/)

### Additional Links
These additional references should also help you:

* [R2DBC Homepage](https://r2dbc.io)

### Docker Compose support
This project contains a Docker Compose file named ``docker-compose.yml``.

## Project Information

**Project Name:** $ProjectName
**Base Package:** $FullPackage
**Server Port:** $AppPort
**Database:** $(if ($DbChoice -eq "1") { "Neon PostgreSQL" } elseif ($DbChoice -eq "2") { "PostgreSQL Local" } else { "H2 In-Memory" })

### Entities Generated
"@

foreach ($e in $EntityNames) {
    $HelpMdContent += "`n* $e (Endpoint: /api/$(Pluralize (LowFirst $e)))"
}

Set-Utf8NoBom -Path "$Root/HELP.md" -Value $HelpMdContent

# ------------------------------------------------------------------
# 9. Dockerfile
# ------------------------------------------------------------------

$DockerfileContent = @'
# Stage 1: Build
FROM maven:3.9-eclipse-temurin-21-alpine AS build
WORKDIR /app

# Copiar solo pom.xml primero (para cache de dependencias)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copiar codigo fuente y compilar
COPY src ./src
RUN mvn clean package -DskipTests -B

# Stage 2: Runtime
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Crear usuario no-root
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copiar JAR desde stage de build
COPY --from=build /app/target/*.jar app.jar

# Puerto flexible con variable de entorno
ENV SERVER_PORT=8080
EXPOSE ${SERVER_PORT}

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
'@
Set-Utf8NoBom -Path "$Root/Dockerfile" -Value $DockerfileContent

# ------------------------------------------------------------------
# 10. docker-compose.yml
# ------------------------------------------------------------------

$EndpointsList = ""
foreach ($e in $EntityNames) {
    $EndpointsList += "* http://localhost:$AppPort/api/$(Pluralize (LowFirst $e))`n"
}

$DockerComposeContent = @"
services:
  # Backend Spring WebFlux
  backend:
    image: ${DockerUser}/${ProjectName}:1.0
    container_name: ${ProjectName}-backend
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "${AppPort}:${AppPort}"
    environment:
$(if ($DbChoice -eq "1") {
"      # Credenciales de Neon Database (Cloud)
      DB_URL: $R2dbcUrl
      DB_USERNAME: $R2dbcUser
      DB_PASSWORD: $R2dbcPassword
      SERVER_PORT: $AppPort"
} elseif ($DbChoice -eq "2") {
"      # PostgreSQL Local
      DB_URL: r2dbc:postgresql://postgres:5432/${ArtifactPkg}
      DB_USERNAME: ${ArtifactPkg}
      DB_PASSWORD: ${ArtifactPkg}
      SERVER_PORT: $AppPort"
} else {
"      # H2 en memoria
      DB_URL: r2dbc:h2:mem:///testdb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
      DB_USERNAME: sa
      DB_PASSWORD: password
      SERVER_PORT: $AppPort"
})
    networks:
      - ${ProjectName}-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:${AppPort}/api/$(Pluralize (LowFirst $EntityNames[0]))"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
$(if ($DbChoice -eq "2") {
"    depends_on:
      - postgres

  # PostgreSQL Local Database
  postgres:
    image: postgres:16-alpine
    container_name: ${ProjectName}-postgres
    environment:
      POSTGRES_DB: ${ArtifactPkg}
      POSTGRES_USER: ${ArtifactPkg}
      POSTGRES_PASSWORD: ${ArtifactPkg}
    ports:
      - '5432:5432'
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - ${ProjectName}-network
    restart: unless-stopped
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U ${ArtifactPkg}']
      interval: 10s
      timeout: 5s
      retries: 5"
})

networks:
  ${ProjectName}-network:
    driver: bridge
$(if ($DbChoice -eq "2") {
"
volumes:
  postgres-data:"
})
"@
Set-Utf8NoBom -Path "$Root/docker-compose.yml" -Value $DockerComposeContent

# ------------------------------------------------------------------
# 11. README.md
# ------------------------------------------------------------------

$ReadmeContent = @"
# $ProjectName

Proyecto generado con Spring Boot 3 + WebFlux + R2DBC + Docker + Kubernetes

## Tecnologias

- Java 21
- Spring Boot 3.3.4
- Spring WebFlux (Reactive)
- R2DBC (Reactive Database Connectivity)
- $(if ($DbChoice -eq "1") { "PostgreSQL (Neon Cloud)" } elseif ($DbChoice -eq "2") { "PostgreSQL (Local)" } else { "H2 (In-Memory)" })
- Docker & Docker Compose
- Kubernetes (K8s)
- Maven

## Entidades

$($EntityNames | ForEach-Object { "- $_ (Endpoint: /api/$(Pluralize (LowFirst $_)))" } | Out-String)

## Endpoints Disponibles

Cada entidad tiene los siguientes endpoints:

### CRUD Basico
- ``GET /api/{entidad}`` - Listar todos
- ``GET /api/{entidad}?status=ACTIVE`` - Filtrar por status
- ``GET /api/{entidad}/{id}`` - Obtener por ID
- ``POST /api/{entidad}`` - Crear nuevo
- ``PUT /api/{entidad}/{id}`` - Actualizar
- ``DELETE /api/{entidad}/{id}`` - Eliminar

### Gestion de Estado
- ``PATCH /api/{entidad}/{id}/activate`` - Activar
- ``PATCH /api/{entidad}/{id}/deactivate`` - Desactivar
- ``PATCH /api/{entidad}/{id}/suspend`` - Suspender

## Desarrollo Local

### Requisitos
- Java 21
- Maven 3.9+
- Docker & Docker Compose (opcional)

### Ejecutar con Maven
`````bash
# Compilar
mvnw clean package

# Ejecutar
mvnw spring-boot:run
`````

### Ejecutar con Docker Compose
`````bash
# Construir y ejecutar
docker-compose up --build

# Detener
docker-compose down
`````

La API estara disponible en: http://localhost:$AppPort

### Endpoints de prueba
$EndpointsList

## Despliegue en Kubernetes

### 1. Crear namespace
`````bash
kubectl apply -f k8s/${K8sNs}-namespace.yml
`````

### 2. Configurar secrets
Edita ``k8s/${K8sNs}-secret.yml`` con tus credenciales en base64:
`````bash
# Para encodear en base64
echo -n "tu-valor" | base64
`````

Luego aplica:
`````bash
kubectl apply -f k8s/${K8sNs}-secret.yml
`````

### 3. Desplegar aplicacion
`````bash
kubectl apply -f k8s/${K8sNs}-deployment.yml
kubectl apply -f k8s/${K8sNs}-service.yml
`````

### 4. Verificar despliegue
`````bash
# Ver pods
kubectl get pods -n $K8sNs

# Ver servicios
kubectl get svc -n $K8sNs

# Ver logs
kubectl logs -n $K8sNs -l app=$K8sNs -f
`````

## Compilar imagen Docker

`````bash
# Construir imagen
docker build -t ${DockerUser}/${ProjectName}:1.0 .

# Subir a Docker Hub
docker push ${DockerUser}/${ProjectName}:1.0
`````

## Estructura del Proyecto

`````
$ProjectName/
├── src/
│   ├── main/
│   │   ├── java/$PackagePath/
│   │   │   ├── model/           # Entidades
│   │   │   ├── repository/      # Repositorios R2DBC
│   │   │   ├── service/         # Logica de negocio
│   │   │   │   └── impl/
│   │   │   └── rest/            # Controladores REST
│   │   └── resources/
│   │       ├── application.yaml
│   │       └── schema.sql
│   └── test/
├── k8s/                          # Manifiestos Kubernetes
├── Dockerfile
├── docker-compose.yml
├── pom.xml
└── README.md
`````

## Base de Datos

$(if ($DbChoice -eq "1") {
"### Neon PostgreSQL (Cloud)
- URL: $NeonUrl
- Database: $NeonDbName
- SSL Mode: require

Las tablas se crean automaticamente al iniciar la aplicacion."
} elseif ($DbChoice -eq "2") {
"### PostgreSQL Local
- Host: localhost
- Port: 5432
- Database: $ArtifactPkg
- User: $ArtifactPkg
- Password: $ArtifactPkg

Con Docker Compose, PostgreSQL se inicia automaticamente."
} else {
"### H2 In-Memory
- URL: r2dbc:h2:mem:///testdb
- User: sa
- Password: password

La base de datos se crea en memoria al iniciar la aplicacion y se pierde al detenerla."
})

## Soporte

Generado automaticamente con el generador de proyectos Spring Boot WebFlux.
"@
Set-Utf8NoBom -Path "$Root/README.md" -Value $ReadmeContent

# ------------------------------------------------------------------
# 12. Manifiestos de Kubernetes
# ------------------------------------------------------------------

# Namespace
$K8sNamespaceContent = @"
apiVersion: v1
kind: Namespace
metadata:
  name: $K8sNs
  labels:
    name: $K8sNs
    environment: production
    app: webflux-crud
"@
Set-Utf8NoBom -Path "$Root/k8s/${K8sNs}-namespace.yml" -Value $K8sNamespaceContent

# Secret (plantilla vacia - el usuario debe llenarla)
$K8sSecretContent = @"
apiVersion: v1
kind: Secret
metadata:
  name: ${K8sNs}-secrets
  namespace: $K8sNs
type: Opaque
data:
  # Base de datos - Valores en base64
  # Para encodear: echo -n "tu-valor" | base64
  DB_URL: $(if ($DbChoice -eq "1") { [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($R2dbcUrl)) } else { "cjJkYmM6cG9zdGdyZXNxbDovL3lvdXItaG9zdC9kYXRhYmFzZQ==" })
  DB_USERNAME: $(if ($DbChoice -eq "1") { [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($R2dbcUser)) } else { "eW91ci11c2Vy" })
  DB_PASSWORD: $(if ($DbChoice -eq "1") { [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($R2dbcPassword)) } else { "eW91ci1wYXNzd29yZA==" })
  SERVER_PORT: $([Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($AppPort)))
"@
Set-Utf8NoBom -Path "$Root/k8s/${K8sNs}-secret.yml" -Value $K8sSecretContent

# Deployment
$FirstEndpoint = "/api/" + (Pluralize (LowFirst $EntityNames[0]))
$K8sDeploymentContent = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${K8sNs}-deployment
  namespace: $K8sNs
  labels:
    app: $K8sNs
    tier: backend
    version: "1.0"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: $K8sNs
      tier: backend
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: $K8sNs
        tier: backend
        version: "1.0"
    spec:
      containers:
      - name: $K8sNs
        image: ${DockerUser}/${ProjectName}:1.0
        imagePullPolicy: Always
        ports:
        - name: http
          containerPort: $AppPort
          protocol: TCP
        env:
        - name: DB_URL
          valueFrom:
            secretKeyRef:
              name: ${K8sNs}-secrets
              key: DB_URL
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: ${K8sNs}-secrets
              key: DB_USERNAME
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: ${K8sNs}-secrets
              key: DB_PASSWORD
        - name: SERVER_PORT
          valueFrom:
            secretKeyRef:
              name: ${K8sNs}-secrets
              key: SERVER_PORT
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: $FirstEndpoint
            port: $AppPort
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: $FirstEndpoint
            port: $AppPort
          initialDelaySeconds: 30
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
      restartPolicy: Always
"@
Set-Utf8NoBom -Path "$Root/k8s/${K8sNs}-deployment.yml" -Value $K8sDeploymentContent

# Service
$NodePortCalculated = 30000 + ([int]$AppPort % 10000)
$K8sServiceContent = @"
apiVersion: v1
kind: Service
metadata:
  name: ${K8sNs}-service
  namespace: $K8sNs
  labels:
    app: $K8sNs
    tier: backend
spec:
  type: LoadBalancer
  selector:
    app: $K8sNs
    tier: backend
  ports:
  - name: http
    protocol: TCP
    port: $AppPort
    targetPort: $AppPort
    nodePort: $NodePortCalculated
  sessionAffinity: ClientIP
"@
Set-Utf8NoBom -Path "$Root/k8s/${K8sNs}-service.yml" -Value $K8sServiceContent

Write-Host "  Archivos Docker y Kubernetes generados"

# ------------------------------------------------------------------
# 13. pom.xml
# ------------------------------------------------------------------

$PomTemplate = @'

$PomTemplate = @'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.4</version>
        <relativePath/>
    </parent>

    <groupId>{{BASE_PACKAGE}}</groupId>
    <artifactId>{{PROJECT_NAME}}</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>{{PROJECT_NAME}}</name>
    <description>{{PROJECT_NAME}} - Spring Boot 3 + Java 21</description>

    <properties>
        <java.version>21</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-webflux</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-r2dbc</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        <dependency>
            <groupId>io.r2dbc</groupId>
            <artifactId>r2dbc-h2</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>r2dbc-postgresql</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>io.projectreactor</groupId>
            <artifactId>reactor-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <excludes>
                        <exclude>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                        </exclude>
                    </excludes>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
'@
Set-Utf8NoBom -Path "$Root/pom.xml" -Value (Fill $PomTemplate @{
    BASE_PACKAGE = $BasePackage
    PROJECT_NAME = $ProjectName
})

# copiar mvnw / mvnw.cmd / .mvn si estan junto a este script
$ScriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ScriptDir)) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (Test-Path "$ScriptDir/mvnw") {
    Copy-Item "$ScriptDir/mvnw" "$Root/mvnw" -Force
} else {
    Write-Host "  Aviso: no se encontro 'mvnw' junto al script; copialo manualmente a $Root."
}
if (Test-Path "$ScriptDir/mvnw.cmd") {
    Copy-Item "$ScriptDir/mvnw.cmd" "$Root/mvnw.cmd" -Force
} else {
    Write-Host "  Aviso: no se encontro 'mvnw.cmd' junto al script; copialo manualmente a $Root."
}
if (Test-Path "$ScriptDir/.mvn") {
    Copy-Item "$ScriptDir/.mvn" "$Root/.mvn" -Recurse -Force
} else {
    Write-Host "  Aviso: no se encontro la carpeta '.mvn' junto al script; copiala manualmente a $Root."
}

# ------------------------------------------------------------------
# FINALIZACION
# ------------------------------------------------------------------

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "                                                                " -ForegroundColor Green
Write-Host "  PROYECTO '$ProjectName' GENERADO EXITOSAMENTE                " -ForegroundColor Green
Write-Host "                                                                " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Ubicacion: $Root" -ForegroundColor Cyan
Write-Host ""
Write-Host "Entidades creadas:" -ForegroundColor Yellow
foreach ($e in $EntityNames) {
    Write-Host "  - $e (/api/$(Pluralize (LowFirst $e)))" -ForegroundColor White
}
Write-Host ""
Write-Host "Archivos generados:" -ForegroundColor Yellow
Write-Host "  - Codigo Java (Model, Repository, Service, REST)"
Write-Host "  - Dockerfile (Java 21, multi-stage, Alpine)"
Write-Host "  - docker-compose.yml"
Write-Host "  - Manifiestos Kubernetes (namespace, secret, deployment, service)"
Write-Host "  - README.md, HELP.md"
Write-Host "  - .gitignore, .dockerignore, .gitattributes, .env.example"
Write-Host ""
Write-Host "Proximos pasos:" -ForegroundColor Cyan
Write-Host "  1. cd $ProjectName"
Write-Host "  2. .\mvnw.cmd clean package"
Write-Host "  3. .\mvnw.cmd spring-boot:run"
Write-Host ""
Write-Host "Con Docker:" -ForegroundColor Cyan
Write-Host "  docker-compose up --build"
Write-Host ""
Write-Host "La API estara disponible en: http://localhost:$AppPort" -ForegroundColor Green
Write-Host ""
Write-Host "Endpoints:" -ForegroundColor Yellow
foreach ($e in $EntityNames) {
    Write-Host "  http://localhost:$AppPort/api/$(Pluralize (LowFirst $e))" -ForegroundColor White
}
Write-Host ""
Write-Host "Consulta README.md y HELP.md para mas informacion" -ForegroundColor Gray
Write-Host ""
