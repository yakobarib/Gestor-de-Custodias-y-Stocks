# Gestor de Custodias y Stocks — Recambios Ibiza / AD Parts

Aplicación web para gestionar el stock que los clientes dejan en custodia (depósito), sus entregas parciales y los préstamos temporales de mercancía entre clientes.

- **App en producción:** https://yakobarib.github.io/Gestor-de-Custodias-y-Stocks/
- **Versión actual:** v.8.0.4

## Estructura del proyecto

```
index.html                        → versión en producción (desplegada en GitHub Pages, sirve desde la raíz)
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

## Stack técnico

- React 18 + ReactDOM (CDN, UMD) — sin bundler, JSX compilado en el cliente.
- Backend: [Supabase](https://supabase.com) (tabla `app_state`), sincronización entre operarios por polling cada 10s.
- Persistencia local (`localStorage`): solo preferencias de UI (tema, tamaño de fuente).
- Sin autenticación ni roles de usuario — pensado para un equipo reducido de confianza.

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
- Sin autenticación: cualquiera con el enlace puede editar o borrar datos; el campo "operario" es texto libre sin validar.
- Sincronización por sondeo (polling) sobre un único bloque JSON: si dos operarios guardan casi a la vez, el último guardado puede sobrescribir cambios del otro. Pendiente de rediseño (tablas propias por entidad en Supabase) para eliminarlo por completo.
- El plan gratuito de Supabase puede pausarse tras ~1 semana de inactividad.

El registro de cambios detallado por versión está disponible dentro de la propia app, en el panel de Ayuda → Changelog.
