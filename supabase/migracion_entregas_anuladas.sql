-- Entregas anuladas / revertidas (v8.9.0)
-- Ejecutar UNA vez en Supabase → SQL Editor, ANTES de publicar la v8.9.0.
--
-- Una línea de entrega revertida (porque el producto no tenía stock real) no se
-- borra: se marca como anulada y se guarda quién, cuándo y por qué. La app la
-- muestra tachada en el Histórico y no la cuenta como entrega realizada.

alter table public.entregas
  add column if not exists anulada boolean not null default false,
  add column if not exists anulada_at timestamptz,
  add column if not exists anulada_por text,
  add column if not exists motivo_anulacion text;
