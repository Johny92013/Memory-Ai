-- Phase 6: Alte Zufallsprojektions-Embeddings invalidieren
-- Vorher gezählt: face_reference_embeddings ≈ 2, media_face_detections.embedding not null ≈ 10

-- Referenz-Embeddings löschen (nur Test-/Zufallsprojektion)
delete from public.face_reference_embeddings;

-- Detection-Embeddings leeren (Bounding Boxes bleiben)
update public.media_face_detections
set embedding = null
where embedding is not null;

-- Versions-Marker für künftige Modelle
alter table public.face_reference_embeddings
  add column if not exists model_version text not null default 'none';

comment on column public.face_reference_embeddings.model_version is
  'z.B. local_projection_v1 | mobilefacenet_v1';
