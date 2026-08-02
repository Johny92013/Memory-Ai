/// TODO(phase8): KI-gestützte Video-/Erinnerungs-Zusammenfassung.
///
/// Draft-Datenmodell (noch keine Migration ausführen):
///
/// ```sql
/// -- DRAFT ONLY
/// create table public.video_jobs (
///   id uuid primary key default gen_random_uuid(),
///   owner_id uuid not null references auth.users(id),
///   source_album_id uuid,
///   status text not null default 'queued',
///   output_storage_path text,
///   created_at timestamptz not null default now()
/// );
/// ```
class VideoAiDraftService {
  // TODO: Prompt-/Caption-Generierung
  // TODO: Szenenauswahl aus media_items
  Future<Never> enqueueJob() async {
    throw UnimplementedError('VideoAiDraftService – Phase 8 Gerüst');
  }
}
