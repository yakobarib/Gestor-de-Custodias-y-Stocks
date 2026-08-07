-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRACIÓN: de un único bloque JSON (app_state) a tablas por entidad
-- ═══════════════════════════════════════════════════════════════════════════
-- Por qué: hoy toda la app se guarda como un único JSON en la fila "main" de
-- app_state. Si dos operarios guardan casi a la vez, el segundo sobreescribe
-- el bloque entero y puede borrar silenciosamente lo que acaba de escribir
-- el primero. Con una fila por custodia/entrega/préstamo, cada guardado solo
-- toca su propia fila y nunca pisa el trabajo de otro usuario.
--
-- CÓMO EJECUTAR: Supabase → tu proyecto → SQL Editor → pega todo este
-- archivo → Run. Es seguro ejecutarlo varias veces (usa IF NOT EXISTS y
-- ON CONFLICT DO NOTHING). La tabla app_state NO se toca ni se borra —
-- queda como copia de seguridad de los datos previos a la migración.
-- ═══════════════════════════════════════════════════════════════════════════

-- 1) TABLAS ------------------------------------------------------------------

create table if not exists custodias (
  id                 text primary key,
  cliente            text,
  albaran            text,
  factura_libre      text,
  operario_custodia  text,
  fecha              text,
  referencia         text,
  producto           text,
  almacen            text,
  uds_totales        integer not null default 0,
  uds_entregadas     integer not null default 0,
  notas              text,
  prom_skrit         text,
  created_at         timestamptz not null default now()
);

create table if not exists entregas (
  id             text primary key,
  custodia_id    text,
  fecha          text,
  uds            integer not null default 0,
  albaran        text,
  operario       text,
  notas          text,
  num_entrega    text,
  grupo_entrega  text,
  created_at     timestamptz not null default now()
);

create table if not exists prestamos (
  id              text primary key,
  custodia_id     text,
  uds             integer not null default 0,
  cliente_deudor  text,
  motivo          text,
  fecha           text,
  saldado         boolean not null default false,
  created_at      timestamptz not null default now()
);

-- Nota: custodia_id NO tiene una FK con ON DELETE CASCADE a propósito: al
-- borrar una custodia, sus entregas/préstamos deben conservarse como
-- historial en vez de desaparecer o bloquear el borrado.

create index if not exists idx_entregas_custodia   on entregas(custodia_id);
create index if not exists idx_prestamos_custodia  on prestamos(custodia_id);

-- 2) SEGURIDAD: solo usuarios autenticados pueden leer/escribir -------------
-- (esto es lo que "neutraliza" la clave pública anon incrustada en el HTML:
-- sin sesión de login válida, esa clave ya no da acceso a ningún dato)

alter table custodias enable row level security;
alter table entregas  enable row level security;
alter table prestamos enable row level security;

drop policy if exists "auth_all_custodias" on custodias;
create policy "auth_all_custodias" on custodias for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "auth_all_entregas" on entregas;
create policy "auth_all_entregas" on entregas for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

drop policy if exists "auth_all_prestamos" on prestamos;
create policy "auth_all_prestamos" on prestamos for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- 3) MIGRAR LOS DATOS ACTUALES DESDE app_state.data --------------------------

insert into custodias (id, cliente, albaran, factura_libre, operario_custodia, fecha, referencia, producto, almacen, uds_totales, uds_entregadas, notas, prom_skrit)
select
  c->>'id', c->>'cliente', c->>'albaran', c->>'facturaLibre', c->>'operarioCustodia', c->>'fecha',
  c->>'referencia', c->>'producto', c->>'almacen',
  coalesce((c->>'udsTotales')::int, 0), coalesce((c->>'udsEntregadas')::int, 0),
  c->>'notas', c->>'promSkrit'
from app_state, jsonb_array_elements(coalesce(data->'custodias', '[]'::jsonb)) as c
where id = 'main'
on conflict (id) do nothing;

insert into entregas (id, custodia_id, fecha, uds, albaran, operario, notas, num_entrega, grupo_entrega)
select
  e->>'id', e->>'custodiaId', e->>'fecha', coalesce((e->>'uds')::int, 0), e->>'albaran',
  e->>'operario', e->>'notas', nullif(e->>'numEntrega', ''), nullif(e->>'grupoEntrega', '')
from app_state, jsonb_array_elements(coalesce(data->'entregas', '[]'::jsonb)) as e
where id = 'main'
on conflict (id) do nothing;

insert into prestamos (id, custodia_id, uds, cliente_deudor, motivo, fecha, saldado)
select
  p->>'id', p->>'custodiaId', coalesce((p->>'uds')::int, 0), p->>'clienteDeutor',
  p->>'motivo', p->>'fecha', coalesce((p->>'saldado')::boolean, false)
from app_state, jsonb_array_elements(coalesce(data->'prestamos', '[]'::jsonb)) as p
where id = 'main'
on conflict (id) do nothing;

-- 4) COMPLETAR NÚMEROS DE ENTREGA QUE PUDIERAN FALTAR ------------------------

with maxnum as (
  select coalesce(max(num_entrega::int), 0) as m
  from entregas where num_entrega ~ '^[0-9]+$'
), faltantes as (
  select id, row_number() over (order by fecha nulls last, id) as rn
  from entregas
  where num_entrega is null
)
update entregas e
set num_entrega = lpad((maxnum.m + faltantes.rn)::text, 6, '0')
from faltantes, maxnum
where e.id = faltantes.id;

-- ═══════════════════════════════════════════════════════════════════════════
-- Después de ejecutar esto, en el panel de Supabase debes activar el login:
--
-- 1) Authentication → Providers → Email: debe estar activado (lo está por
--    defecto).
-- 2) Authentication → Settings (o "Sign In / Providers" según la versión):
--    desactiva "Allow new users to sign up" para que nadie pueda crearse
--    una cuenta por sí mismo — solo las cuentas que crees tú manualmente
--    podrán entrar.
-- 3) Authentication → Users → Add user: crea una cuenta (email + contraseña)
--    para cada operario. Marca "Auto Confirm User" para que no necesiten
--    confirmar por email.
-- ═══════════════════════════════════════════════════════════════════════════
