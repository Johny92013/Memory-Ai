# Face-Embedding-Modelle

Lege hier die On-Device-Datei ab:

- `mobilefacenet.tflite` (MobileFaceNet, kostenlos nutzbares Community-Modell)

Danach in `pubspec.yaml` unter `assets` eintragen und
`MobileFaceNetEmbeddingEngine` mit `tflite_flutter` fertig verdrahten.

Bis das Modell liegt, nutzt die App den lokalen Fallback
(`LocalProjectionEmbeddingEngine`) – bestehende Zufallsprojektions-
Embeddings wurden in der DB geleert (siehe Migration
`invalidate_legacy_face_embeddings`).
