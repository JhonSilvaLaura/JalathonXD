#Requires -Version 5.1
<#
.SYNOPSIS
    Generador de CRUD Completo en Angular 21 (Estilo Demo-Front)
    
.DESCRIPTION
    Script que genera:
    - Verifica/Instala Node.js automáticamente
    - Verifica/Instala Angular CLI 21 automáticamente
    - Estructura: core/interfaces, core/services, features/[nombre]/components
    - CRUD completo en UN SOLO COMPONENTE con signals
    - Font Awesome para iconos
    - Integración lista con backend Spring WebFlux
    
.AUTHOR
    Jhon Brayan Silva Laura - Hackathon Ready v3.0
#>

$ErrorActionPreference = "Stop"

# ═══════════════════════════════════════════════════════════
# BANNER
# ═══════════════════════════════════════════════════════════
Clear-Host
Write-Host @"

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     🚀 GENERADOR CRUD ANGULAR 21 - ESTILO DEMO-FRONT         ║
║        Un Solo Componente + Signals + Font Awesome           ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# ═══════════════════════════════════════════════════════════
# 1. VERIFICACIÓN E INSTALACIÓN DE NODE.JS
# ═══════════════════════════════════════════════════════════
Write-Host "📦 PASO 1: Verificando Node.js..." -ForegroundColor Yellow

if (!(Get-Command "node" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Node.js no está instalado." -ForegroundColor Red
    Write-Host "📥 Instalando Node.js LTS vía winget..." -ForegroundColor Cyan
    
    winget install OpenJS.NodeJS.LTS -e --source winget --accept-package-agreements --accept-source-agreements
    
    # Refrescar PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    if (!(Get-Command "node" -ErrorAction SilentlyContinue)) {
        Write-Host @"
        
⚠️  Node.js instalado pero requiere reinicio de consola.

Por favor:
1. Cierra esta ventana de PowerShell
2. Abre una nueva ventana
3. Vuelve a ejecutar el script

"@ -ForegroundColor Yellow
        pause
        exit
    }
} 

$nodeVer = node -v
Write-Host "✅ Node.js detectado: $nodeVer" -ForegroundColor Green


# ═══════════════════════════════════════════════════════════
# 2. VERIFICACIÓN E INSTALACIÓN DE ANGULAR CLI 21
# ═══════════════════════════════════════════════════════════
Write-Host "`n📦 PASO 2: Verificando Angular CLI 21..." -ForegroundColor Yellow

$installNg = $false

if (!(Get-Command "ng" -ErrorAction SilentlyContinue)) {
    $installNg = $true
} else {
    $ngVersionOutput = ng version 2>&1 | Out-String
    if ($ngVersionOutput -match "Angular CLI:\s+(\d+)") {
        $ngVer = [int]$matches[1]
        Write-Host "📌 Angular CLI v$ngVer detectado" -ForegroundColor Cyan
        if ($ngVer -lt 21) {
            Write-Host "⚠️  Se requiere Angular CLI 21+" -ForegroundColor Yellow
            $installNg = $true
        }
    } else {
        $installNg = $true
    }
}

if ($installNg) {
    Write-Host "🔄 Instalando/Actualizando Angular CLI a versión 21..." -ForegroundColor Cyan
    npm install -g @angular/cli@^21.0.0
    Write-Host "✅ Angular CLI 21 instalado" -ForegroundColor Green
} else {
    Write-Host "✅ Angular CLI 21 listo" -ForegroundColor Green
}

# ═══════════════════════════════════════════════════════════
# 3. INTERFAZ INTERACTIVA
# ═══════════════════════════════════════════════════════════
Write-Host @"

╔═══════════════════════════════════════════════════════════════╗
║              📋 CONFIGURACIÓN DEL PROYECTO                    ║
╚═══════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

$projectName = Read-Host "Nombre del proyecto"
$featureName = Read-Host "Nombre del maestro/entidad (ej. user, product, student)"
$backendUrl = Read-Host "Backend URL (ej. http://localhost:8080)"
$endpoint = Read-Host "Endpoint API (ej. /api/users)"

Write-Host "`nIngresa los campos (formato: nombre:tipo)" -ForegroundColor Yellow
Write-Host "Ejemplos: id:number, name:string, price:number, active:boolean" -ForegroundColor Gray
Write-Host "Escribe 'FIN' cuando termines`n" -ForegroundColor Gray

$fields = @()
$fieldCount = 0

while ($true) {
    $fieldCount++
    $field = Read-Host "  Campo $fieldCount (o 'FIN')"
    
    if ($field.Trim().ToUpper() -eq "FIN") {
        break
    }
    
    if ($field.Contains(":")) {
        $fields += $field.Trim()
        $parts = $field -split ":"
        Write-Host "    ✓ $($parts[0]): $($parts[1])" -ForegroundColor Green
    } else {
        Write-Host "    ✗ Formato inválido. Usa: nombre:tipo" -ForegroundColor Red
        $fieldCount--
    }
}

# ═══════════════════════════════════════════════════════════
# 4. CREACIÓN DEL PROYECTO
# ═══════════════════════════════════════════════════════════
Write-Host @"

╔═══════════════════════════════════════════════════════════════╗
║           🚀 GENERANDO PROYECTO ANGULAR 21...                 ║
╚═══════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

Write-Host "`n[1/10] Creando proyecto Angular..." -ForegroundColor Yellow
ng new $projectName --routing --style scss --skip-git

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al crear el proyecto" -ForegroundColor Red
    pause
    exit 1
}

Set-Location ".\$projectName"
Write-Host "✅ Proyecto creado" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════
# 5. INSTALAR FONT AWESOME
# ═══════════════════════════════════════════════════════════
Write-Host "`n[2/10] Instalando Font Awesome..." -ForegroundColor Yellow
npm install @fortawesome/fontawesome-free
Write-Host "✅ Font Awesome instalado" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════
# 6. CONFIGURAR STYLES.SCSS Y ANGULAR.JSON
# ═══════════════════════════════════════════════════════════
Write-Host "`n[3/10] Configurando estilos globales..." -ForegroundColor Yellow

$stylesContent = @"
/* Font Awesome */
@import '@fortawesome/fontawesome-free/css/all.min.css';

/* Reset y estilos base */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
  padding: 20px;
}

/* Variables globales */
:root {
  --primary-color: #667eea;
  --secondary-color: #764ba2;
  --success-color: #48bb78;
  --danger-color: #f56565;
  --warning-color: #ed8936;
  --info-color: #4299e1;
  --light-bg: #f7fafc;
  --card-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}
"@

Set-Content -Path "src/styles.scss" -Value $stylesContent
Write-Host "✅ Estilos configurados" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════
# 7. CREAR ESTRUCTURA DE CARPETAS
# ═══════════════════════════════════════════════════════════
Write-Host "`n[4/10] Generando estructura de carpetas..." -ForegroundColor Yellow

$src = "src/app"
$dirs = @(
    "$src/core/interface",
    "$src/core/service",
    "$src/feature/$featureName",
    "src/environments"
)

foreach ($d in $dirs) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}

Write-Host "✅ Estructura creada" -ForegroundColor Green


# ═══════════════════════════════════════════════════════════
# 8. PARSEO DE CAMPOS Y CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════
Write-Host "`n[5/10] Procesando campos..." -ForegroundColor Yellow

$capitalizeFirst = {
    param([string]$str)
    return $str.Substring(0,1).ToUpper() + $str.Substring(1)
}

# Parsear campos manteniendo el ORDEN usando ArrayList
$fieldsOrdered = New-Object System.Collections.ArrayList
$fieldsHash = @{}

foreach ($f in $fields) {
    $parts = $f -split ":"
    $fName = $parts[0].Trim().Replace("?", "")
    $fType = $parts[1].Trim()
    
    # Convertir a tipos TypeScript con mayúscula inicial (estilo Angular 21)
    $tsType = switch ($fType.ToLower()) {
        "string" { "String" }
        "number" { "Number" }
        "boolean" { "Boolean" }
        "date" { "Date" }
        "localdate" { "String" }
        "localdatetime" { "String" }
        default { "String" }
    }
    
    # Guardar en orden
    $null = $fieldsOrdered.Add([PSCustomObject]@{
        Name = $fName
        Type = $tsType
    })
    
    $fieldsHash[$fName] = $tsType
}

# Construir campos para la interface EN ORDEN
$tsInterfaceFields = ""
foreach ($field in $fieldsOrdered) {
    $fName = $field.Name
    $fType = $field.Type
    
    # id es opcional
    if ($fName -eq "id") {
        $tsInterfaceFields += "  id?: String,`n"
    } else {
        $tsInterfaceFields += "  ${fName}: $fType,`n"
    }
}

# Agregar campos opcionales de control SOLO si no existen
$systemFields = @('status', 'createdAt', 'updatedAt')
foreach ($sysField in $systemFields) {
    if (-not $fieldsHash.ContainsKey($sysField)) {
        $tsInterfaceFields += "  ${sysField}?: String,`n"
    }
}

# Quitar última coma
$tsInterfaceFields = $tsInterfaceFields.TrimEnd(",`n") + "`n"

$ClassName = &$capitalizeFirst $featureName

Write-Host "✅ Campos procesados" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════
# 9. GENERAR ARCHIVOS DE CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════
Write-Host "`n[6/10] Configurando environments y app.config..." -ForegroundColor Yellow

# environments/environment.ts
$envContent = @"
export const environment = {
  production: false,
  apiUrl: '$backendUrl'
};
"@

Set-Content -Path "src/environments/environment.ts" -Value $envContent
Set-Content -Path "src/environments/environment.development.ts" -Value $envContent

# src/app/app.config.ts
$appConfigContent = @"
import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { routes } from './app.routes';
import { provideHttpClient } from '@angular/common/http';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    provideHttpClient()
  ]
};
"@

Set-Content -Path "$src/app.config.ts" -Value $appConfigContent

# Limpiar plantilla por defecto de Angular
$appComponentTsContent = @"
import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { $ClassName } from './feature/$featureName/$featureName';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, $ClassName],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App {
  title = '$projectName';
}
"@

Set-Content -Path "$src/app.ts" -Value $appComponentTsContent

$appComponentHtmlContent = @"
<app-$featureName />
"@

Set-Content -Path "$src/app.html" -Value $appComponentHtmlContent
Set-Content -Path "$src/app.scss" -Value ""

Write-Host "✅ Configuración lista" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════
# 10. GENERAR INTERFACES
# ═══════════════════════════════════════════════════════════
Write-Host "`n[7/10] Generando interfaces..." -ForegroundColor Yellow

$interfaceContent = @"
export interface $($ClassName)Interface {
$tsInterfaceFields}
"@

Set-Content -Path "$src/core/interface/$featureName.ts" -Value $interfaceContent
Write-Host "✅ Interface $($ClassName)Interface creada" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════
# 11. GENERAR SERVICES
# ═══════════════════════════════════════════════════════════
Write-Host "`n[8/10] Generando services..." -ForegroundColor Yellow

$serviceContent = @"
import { inject, Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { $($ClassName)Interface } from '../interface/$featureName';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class $($ClassName)Service {
  private http = inject(HttpClient);
  private url = ``$`{environment.apiUrl}$endpoint``;

  findAll(): Observable<$($ClassName)Interface[]> {
    return this.http.get<$($ClassName)Interface[]>(this.url);
  }

  findById(id: String): Observable<$($ClassName)Interface> {
    return this.http.get<$($ClassName)Interface>(``$`{this.url}/`$`{id}``);
  }

  save(data: $($ClassName)Interface): Observable<$($ClassName)Interface> {
    return this.http.post<$($ClassName)Interface>(this.url, data);
  }

  update(id: String, data: $($ClassName)Interface): Observable<$($ClassName)Interface> {
    return this.http.put<$($ClassName)Interface>(``$`{this.url}/`$`{id}``, data);
  }

  deleteById(id: String): Observable<$($ClassName)Interface> {
    return this.http.patch<$($ClassName)Interface>(``$`{this.url}/`$`{id}/removeLogically``, {});
  }

  restoreById(id: String): Observable<$($ClassName)Interface> {
    return this.http.patch<$($ClassName)Interface>(``$`{this.url}/`$`{id}/restoreLogically``, {});
  }

  delete(id: String): Observable<void> {
    return this.http.delete<void>(``$`{this.url}/`$`{id}``);
  }
}
"@

Set-Content -Path "$src/core/service/$featureName-service.ts" -Value $serviceContent
Write-Host "✅ Service $($ClassName)Service creado" -ForegroundColor Green


# ═══════════════════════════════════════════════════════════
# 12. GENERAR COMPONENTE ÚNICO (CRUD COMPLETO - ESTILO ANGULAR 21)
# ═══════════════════════════════════════════════════════════
Write-Host "`n[9/10] Generando componente CRUD único..." -ForegroundColor Yellow

# Construir inicialización de formXXX EN ORDEN
$formInit = ""
foreach ($field in $fieldsOrdered) {
    $fName = $field.Name
    $fType = $field.Type
    
    if ($fName -eq "id") { continue }
    
    $defaultValue = switch ($fType) {
        'String' { "''" }
        'Number' { '0' }
        'Boolean' { 'false' }
        'Date' { 'new Date()' }
        default { "''" }
    }
    $formInit += "    $fName`: $defaultValue,`n"
}

# COMPONENT TypeScript (ESTILO ANGULAR 21)
$componentTsContent = @"
import { Component, inject, OnInit, signal } from '@angular/core';
import { $($ClassName)Service } from '../../core/service/$featureName-service';
import { $($ClassName)Interface } from '../../core/interface/$featureName';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-$featureName',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './$featureName.html',
  styleUrl: './$featureName.scss',
})
export class $ClassName implements OnInit {
  private service = inject($($ClassName)Service);

  $($featureName)s = signal<$($ClassName)Interface[]>([]);
  
  form$($ClassName): $($ClassName)Interface = {
$formInit  };

  isEditing: String | null = null;

  ngOnInit() {
    this.cargar$($ClassName)s();
  }

  cargar$($ClassName)s() {
    this.service.findAll().subscribe(data => this.$($featureName)s.set(data));
  }

  save() {
    if (this.isEditing) {
      this.service.update(this.isEditing, this.form$ClassName).subscribe(() => {
        this.cargar$($ClassName)s();
        this.cleanForm();
      });
    } else {
      this.service.save(this.form$ClassName).subscribe(() => {
        this.cargar$($ClassName)s();
        this.cleanForm();
      });
    }
  }

  edit($($featureName): $($ClassName)Interface) {
    this.isEditing = $($featureName).id!;
    this.form$ClassName = { ...$featureName };
  }

  removeLogically(id: String) {
    this.service.deleteById(id).subscribe(() => {
      this.cargar$($ClassName)s();
    });
  }

  restoreLogically(id: String) {
    this.service.restoreById(id).subscribe(() => {
      this.cargar$($ClassName)s();
    });
  }

  delete(id: String) {
    if (confirm('¿Estás seguro de eliminar este elemento permanentemente?')) {
      this.service.delete(id).subscribe(() => {
        this.cargar$($ClassName)s();
      });
    }
  }

  getStatusClass(status?: String): string {
    if (!status) return 'status-active';
    
    const statusStr = status.toString().toUpperCase();
    switch(statusStr) {
      case 'ACTIVE': return 'status-active';
      case 'INACTIVE': return 'status-inactive';
      case 'DELETED': return 'status-deleted';
      case 'TRUE': return 'status-active';
      case 'FALSE': return 'status-inactive';
      default: return 'status-active';
    }
  }

  cleanForm() {
    this.form$ClassName = {
$formInit    };
    this.isEditing = null;
  }
}
"@

Set-Content -Path "$src/feature/$featureName/$featureName.ts" -Value $componentTsContent

# Construir HTML de campos de formulario EN ORDEN
$formFieldsHtml = ""
foreach ($field in $fieldsOrdered) {
    $fName = $field.Name
    $fType = $field.Type
    
    if ($fName -eq "id") { continue }
    
    $capitalized = &$capitalizeFirst $fName
    
    if ($fType -eq "Boolean") {
        $formFieldsHtml += "        <div class=`"form-group`">`n"
        $formFieldsHtml += "          <label for=`"$fName`">`n"
        $formFieldsHtml += "            <i class=`"fas fa-check-square`"></i> $capitalized`n"
        $formFieldsHtml += "          </label>`n"
        $formFieldsHtml += "          <input `n"
        $formFieldsHtml += "            id=`"$fName`" `n"
        $formFieldsHtml += "            type=`"checkbox`" `n"
        $formFieldsHtml += "            [(ngModel)]=`"form$ClassName.$fName`" `n"
        $formFieldsHtml += "            name=`"$fName`" `n"
        $formFieldsHtml += "          />`n"
        $formFieldsHtml += "        </div>`n`n"
    } elseif ($fType -eq "Number") {
        $formFieldsHtml += "        <div class=`"form-group`">`n"
        $formFieldsHtml += "          <label for=`"$fName`">`n"
        $formFieldsHtml += "            <i class=`"fas fa-hashtag`"></i> $capitalized`n"
        $formFieldsHtml += "          </label>`n"
        $formFieldsHtml += "          <input `n"
        $formFieldsHtml += "            id=`"$fName`" `n"
        $formFieldsHtml += "            type=`"number`" `n"
        $formFieldsHtml += "            [(ngModel)]=`"form$ClassName.$fName`" `n"
        $formFieldsHtml += "            name=`"$fName`" `n"
        $formFieldsHtml += "            required `n"
        $formFieldsHtml += "            placeholder=`"$capitalized`"`n"
        $formFieldsHtml += "          />`n"
        $formFieldsHtml += "        </div>`n`n"
    } else {
        $formFieldsHtml += "        <div class=`"form-group`">`n"
        $formFieldsHtml += "          <label for=`"$fName`">`n"
        $formFieldsHtml += "            <i class=`"fas fa-pen`"></i> $capitalized`n"
        $formFieldsHtml += "          </label>`n"
        $formFieldsHtml += "          <input `n"
        $formFieldsHtml += "            id=`"$fName`" `n"
        $formFieldsHtml += "            type=`"text`" `n"
        $formFieldsHtml += "            [(ngModel)]=`"form$ClassName.$fName`" `n"
        $formFieldsHtml += "            name=`"$fName`" `n"
        $formFieldsHtml += "            required `n"
        $formFieldsHtml += "            placeholder=`"$capitalized`"`n"
        $formFieldsHtml += "          />`n"
        $formFieldsHtml += "        </div>`n`n"
    }
}

# Construir HTML de tarjetas para visualización EN ORDEN
$cardFieldsHtml = ""
foreach ($field in $fieldsOrdered) {
    $fName = $field.Name
    $fType = $field.Type
    
    if ($fName -eq "id") { continue }
    
    $capitalized = &$capitalizeFirst $fName
    $cardFieldsHtml += "              @if (item.$fName !== undefined && item.$fName !== null) {`n"
    $cardFieldsHtml += "                <p>`n"
    $cardFieldsHtml += "                  <i class=`"fas fa-info-circle`"></i> <strong>$($capitalized):</strong> {{ item.$fName }}`n"
    $cardFieldsHtml += "                </p>`n"
    $cardFieldsHtml += "              }`n"
}

# Detectar si existe un campo "status" y su tipo
$hasStatusField = $false
$statusFieldType = "String"
foreach ($field in $fieldsOrdered) {
    if ($field.Name -eq "status") {
        $hasStatusField = $true
        $statusFieldType = $field.Type
        break
    }
}

# Generar lógica de botones según el tipo de status
$actionButtonsHtml = ""
if ($statusFieldType -eq "Boolean") {
    # Lógica para status Boolean (true/false)
    $actionButtonsHtml = @"
              @if (item.status !== false) {
                <button class="btn btn-edit" (click)="edit(item)">
                  <i class="fas fa-edit"></i> Editar
                </button>
                <button class="btn btn-delete" (click)="removeLogically(item.id!)">
                  <i class="fas fa-trash-alt"></i> Eliminar
                </button>
              }
              @if (item.status === false) {
                <button class="btn btn-restore" (click)="restoreLogically(item.id!)">
                  <i class="fas fa-undo"></i> Restaurar
                </button>
                <button class="btn btn-danger" (click)="delete(item.id!)">
                  <i class="fas fa-trash"></i> Eliminar Permanente
                </button>
              }
"@
} else {
    # Lógica para status String ('ACTIVE', 'INACTIVE', 'DELETED')
    $actionButtonsHtml = @"
              @if (item.status !== 'DELETED' && item.status !== 'deleted') {
                <button class="btn btn-edit" (click)="edit(item)">
                  <i class="fas fa-edit"></i> Editar
                </button>
                <button class="btn btn-delete" (click)="removeLogically(item.id!)">
                  <i class="fas fa-trash-alt"></i> Eliminar
                </button>
              }
              @if (item.status === 'DELETED' || item.status === 'deleted') {
                <button class="btn btn-restore" (click)="restoreLogically(item.id!)">
                  <i class="fas fa-undo"></i> Restaurar
                </button>
                <button class="btn btn-danger" (click)="delete(item.id!)">
                  <i class="fas fa-trash"></i> Eliminar Permanente
                </button>
              }
"@
}

# COMPONENT HTML
$componentHtmlContent = @"
<div class="crud-container">
  <!-- Formulario de Creación/Edición -->
  <section class="form-section">
    <h2>
      <i [class]="isEditing ? 'fas fa-edit' : 'fas fa-plus'"></i>
      {{ isEditing ? ' Editar $ClassName' : ' Crear $ClassName' }}
    </h2>
    
    <form (ngSubmit)="save()" class="form">
$formFieldsHtml
      <div class="btn-group">
        <button type="submit" class="btn btn-primary">
          <i [class]="isEditing ? 'fas fa-check' : 'fas fa-save'"></i> 
          {{ isEditing ? 'Actualizar' : 'Crear' }}
        </button>
        @if (isEditing) {
          <button type="button" class="btn btn-secondary" (click)="cleanForm()">
            <i class="fas fa-times"></i> Cancelar
          </button>
        }
      </div>
    </form>
  </section>

  <!-- Lista de Items -->
  <section class="list-section">
    <div class="search-bar">
      <h2><i class="fas fa-list"></i> Lista de $($ClassName)s</h2>
      <button class="btn btn-secondary" (click)="cargar$($ClassName)s()">
        <i class="fas fa-sync-alt"></i> Recargar
      </button>
    </div>

    @if ($($featureName)s().length > 0) {
      <div class="item-grid">
        @for (item of $($featureName)s(); track item.id) {
          <div class="item-card" [ngClass]="getStatusClass(item.status)">
            <div class="item-header">
              <h3>$ClassName #{{ item.id }}</h3>
              <span class="status-badge" [ngClass]="getStatusClass(item.status)">
                {{ item.status || 'ACTIVE' }}
              </span>
            </div>
            <div class="item-info">
$cardFieldsHtml
            </div>
            <div class="item-actions">
$actionButtonsHtml
            </div>
          </div>
        }
      </div>
    } @else {
      <div class="empty-state">
        <i class="fas fa-inbox fa-3x"></i>
        <p>No hay registros disponibles</p>
        <small>Crea tu primer registro usando el formulario</small>
      </div>
    }
  </section>
</div>
"@

Set-Content -Path "$src/feature/$featureName/$featureName.html" -Value $componentHtmlContent


# COMPONENT SCSS
$componentScssContent = @"
.crud-container {
  max-width: 1400px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: 1fr 2fr;
  gap: 20px;
  padding: 20px;
}

.form-section, .list-section {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

h2 {
  color: var(--primary-color);
  margin-bottom: 20px;
  display: flex;
  align-items: center;
  gap: 10px;
}

.form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;

  label {
    font-weight: 600;
    color: #2d3748;
    display: flex;
    align-items: center;
    gap: 8px;
  }

  input {
    padding: 10px 14px;
    border: 2px solid #e2e8f0;
    border-radius: 6px;
    font-size: 14px;
    transition: all 0.3s;

    &:focus {
      outline: none;
      border-color: var(--primary-color);
      box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
    }
  }

  input[type="checkbox"] {
    width: 20px;
    height: 20px;
    cursor: pointer;
  }
}

.btn {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  font-weight: 600;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  transition: all 0.3s;

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  }
}

.btn-primary {
  background: var(--primary-color);
  color: white;
}

.btn-secondary {
  background: #718096;
  color: white;
}

.btn-edit {
  background: var(--info-color);
  color: white;
}

.btn-delete {
  background: var(--danger-color);
  color: white;
}

.btn-restore {
  background: var(--success-color);
  color: white;
}

.btn-danger {
  background: #dc3545;
  color: white;
  
  &:hover {
    background: #c82333;
  }
}

.btn-group {
  display: flex;
  gap: 12px;
}

.search-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.item-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 16px;
}

.item-card {
  background: white;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  padding: 16px;
  transition: all 0.3s;

  &:hover {
    border-color: var(--primary-color);
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.15);
  }

  &.status-deleted {
    background: #fee;
    border-color: #fcc;
  }

  &.status-inactive {
    background: #fef3cd;
    border-color: #ffc107;
    opacity: 0.8;
  }
}

.item-header {
  margin-bottom: 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;

  h3 {
    color: var(--primary-color);
    font-size: 18px;
  }
}

.status-badge {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  
  &.status-active {
    background: #d4edda;
    color: #155724;
  }
  
  &.status-inactive {
    background: #fff3cd;
    color: #856404;
  }
  
  &.status-deleted {
    background: #f8d7da;
    color: #721c24;
  }
}

.item-info {
  margin-bottom: 16px;

  p {
    margin: 8px 0;
    color: #4a5568;
    display: flex;
    align-items: flex-start;
    gap: 8px;
    font-size: 14px;
  }
}

.item-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #a0aec0;

  i {
    margin-bottom: 16px;
  }

  p {
    font-size: 18px;
    margin-bottom: 8px;
  }

  small {
    color: #cbd5e0;
  }
}

@media (max-width: 768px) {
  .crud-container {
    grid-template-columns: 1fr;
  }
  
  .item-actions {
    .btn {
      font-size: 12px;
      padding: 8px 12px;
    }
  }
}
"@

Set-Content -Path "$src/feature/$featureName/$featureName.scss" -Value $componentScssContent

Write-Host "✅ Componente CRUD único generado" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════
# 13. CONFIGURAR ROUTES (Simplificado)
# ═══════════════════════════════════════════════════════════
Write-Host "`n[10/10] Configurando rutas..." -ForegroundColor Yellow

# app.routes.ts (rutas simples sin lazy loading)
$appRoutesContent = @"
import { Routes } from '@angular/router';

export const routes: Routes = [
  { path: '', redirectTo: '$featureName', pathMatch: 'full' },
  { path: '**', redirectTo: '$featureName' }
];
"@

Set-Content -Path "$src/app.routes.ts" -Value $appRoutesContent

Write-Host "✅ Rutas configuradas" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════
# FINALIZACIÓN
# ═══════════════════════════════════════════════════════════
Write-Host @"

╔═══════════════════════════════════════════════════════════════╗
║           ✅ ¡CRUD GENERADO EXITOSAMENTE!                     ║
╚═══════════════════════════════════════════════════════════════╝

📁 Proyecto: $projectName
📂 Estructura generada:
   ├── core/
   │   ├── interfaces/$featureName.interface.ts
   │   └── services/$featureName.service.ts
   ├── features/$featureName-management/
   │   └── components/
   │       ├── $featureName-list.component.ts
   │       ├── $featureName-list.component.html
   │       └── $featureName-list.component.scss
   └── environments/

🚀 Próximos pasos:
   1. cd $projectName
   2. ng serve
   3. Abrir: http://localhost:4200

💡 Features incluidas:
   ✓ CRUD completo en un solo componente
   ✓ Signals (Angular moderno)
   ✓ FormsModule (template-driven)
   ✓ Font Awesome icons
   ✓ Grid layout responsive
   ✓ Formularios con validación
   ✓ Integración con backend: $backendUrl$endpoint

🎨 Estilo:
   ✓ Cards con gradientes
   ✓ Botones con hover effects
   ✓ Layout adaptativo (móvil + desktop)
   ✓ Formulario lateral + Lista principal

"@ -ForegroundColor Green

Write-Host "🎉 ¡Listo para el hackathon! 🚀" -ForegroundColor Cyan
Write-Host ""
pause
