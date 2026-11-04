-- Categoría de producto en las custodias (v8.8.0)
-- Ejecutar UNA vez en Supabase → SQL Editor, ANTES de publicar la v8.8.0.
--
-- Valores que usa la app: LUBRICANTE, QUIMICO, BATERIA, OTROS.
-- Es nullable: las custodias existentes quedan "sin asignar" (NULL) hasta que
-- se les asigne categoría desde la pestaña Productos → ✏️ Editar.

alter table public.custodias
  add column if not exists categoria text;
