# Gestor de Custodias y Stocks — Recambios Ibiza / AD Parts

Aplicación web para gestionar el stock que los clientes dejan en custodia (depósito), sus entregas parciales y los préstamos temporales de mercancía entre clientes.

- **App en producción:** https://yakobarib.github.io/Gestor-de-Custodias-y-Stocks/
- **Versión actual:** v.8.1.0

## Estructura del proyecto

```
index.html                        → versión en producción (desplegada en GitHub Pages, sirve desde la raíz)
supabase/
  migracion_tablas_por_entidad.sql → migración de app_state (bloque único) a tablas por entidad + RLS
APP/HTML/Archivo de versiones/    → histórico de versiones anteriores (v6.0 → v8.0.2), solo referencia
MANUAL/
  Manual Gestor Custodias v6.0.pdf
BRANDING/
  Branding_AD_Parts.txt
  logo_ad_parts_svg.svg
  logo_recambios_ibiza_svg.svg
Prueba de Impresion de Albaran de Entrega.pdf
```

`index.html` (en la raíz del repo) es la única fuente de verdad para lo desplegado: es un SPA de React (transpilado en el navegador con Babel Standalone, sin build), sin dependencias de servidor propio.

**Puesta en marcha en un proyecto Supabase nuevo (o migración de uno con `app_state`):** ejecuta `supabase/migracion_tablas_por_entidad.sql` en el SQL Editor de Supabase, activa el proveedor Email en Authentication, desactiva el alta pública de usuarios y crea manualmente una cuenta por operario (Authentication → Users). El script no borra `app_state`, que queda como copia de seguridad de los datos previos.

## Stack técnico

- React 18 + ReactDOM (CDN, UMD) — sin bundler, JSX compilado en el cliente.
- Backend: [Supabase](https://supabase.com), una tabla por entidad (`custodias`, `entregas`, `prestamos`), cada guardado es una operación atómica sobre su propia fila.
- Autenticación: Supabase Auth (email + contraseña), una cuenta por operario. Las tablas están protegidas por Row Level Security: solo usuarios autenticados pueden leer o escribir.
- Persistencia local (`localStorage`): sesión de login y preferencias de UI (tema, tamaño de fuente).

## Funcionalidades principales

- Alta y consulta de custodias (stock depositado por cliente).
- Entregas parciales con numeración automática de albarán.
- Préstamos temporales de stock entre clientes.
- Dashboard con KPIs, alertas de deuda y filtros.
- Vistas de Custodias, Entregas, Productos (agregado por referencia) e Histórico unificado.
- Generación de documentos de albarán imprimibles con el branding de AD Parts / Recambios Ibiza.
- Modo claro/oscuro y vista de solo lectura en móvil.
- Exportación de copia de seguridad de los datos (JSON) desde Configuración.

## Limitaciones conocidas

- El botón "Imprimir" abre el diálogo de impresión del navegador (`window.print()`); no genera directamente un PDF descargable.
- Borrar una custodia no elimina sus entregas/préstamos asociados, a propósito (se conservan como historial); pero no hay forma de "limpiar" esos registros huérfanos si se quisiera.
- Todas las cuentas autenticadas tienen el mismo nivel de acceso (sin roles/permisos por operario); el campo "operario" de cada movimiento sigue siendo texto libre sin validar contra el usuario logueado.
- El plan gratuito de Supabase puede pausarse tras ~1 semana de inactividad.

El registro de cambios detallado por versión está disponible dentro de la propia app, en el panel de Ayuda → Changelog.
